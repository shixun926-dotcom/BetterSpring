# Lv14 · JWT

> **关卡编号**：`Lv14` ｜ **所属阶段**：第七阶段 · 真正做登录
> **前置关卡**：`Lv13` Redis（✅） ｜ **状态**：⬜ 未开始
> **对应需求**：`FR-U-004` ~ `FR-U-006`、`NFR-003`、`NFR-004` ｜ **对应接口**：`API-U-003` ~ `API-U-005` ｜ **对应数据表**：`T-user`
> **本关产物**：登录返回 JWT，受保护接口必须携带 `Authorization: Bearer <token>`

---

## 0. 本关速览

| 项目 | 内容 |
| --- | --- |
| 一句话目标 | 实现一次完整的登录认证：账号密码 → JWT → 携带 Token 访问受保护接口 |
| 核心知识点 | JWT 结构、签发、解析、身份判断、Session 对比、密码加密 |
| 预计耗时 | 🚧 待补充 |
| 难度（1~5） | 5 |
| 关键文件 | `util/JwtUtil.java`、`service/AuthService.java`、`controller/AuthController.java`、`entity/User.java`、`mapper/UserMapper.java` |
| 架构变化 | 链路前面插入**认证环节**，接口开始"需要身份" |

📌 参考文档给出的本关要理解的问题（**原文**）：

> 这时候你就会理解：
> JWT是什么
> 为什么要登录
> Token是什么
> 为什么不能只靠Session
> 拦截器是什么

⚠️ 注意：参考文档把"拦截器是什么"也列在这里，但**拦截器的完整实现放在 [`Lv17`](Lv17-拦截器.md)**。
本关先**在 Controller 里手写 Token 校验**（脏一点没关系），Lv17 再把它下沉到拦截器。
**这个"先脏后净"的过程本身就是教学内容，不要跳过。**（见 [08 §2 跨关依赖](../08-关卡总览与路线图.md#2-关卡依赖图)）

---

## 1. 本关目标 `Lv14-S1`

1. 能设计 `user` 表并说明密码为什么必须加密存储（`NFR-003`）；
2. 能实现登录接口：账号密码 → 查库 → 校验 → 签发 JWT → 返回；
3. 能说清 JWT 的三段结构（`Header.Payload.Signature`）以及**为什么它不能被篡改**；
4. 能实现"受保护接口"：从 `Authorization: Bearer xxx` 取出 Token，解析出用户 ID；
5. 能说清 Session 的两个具体麻烦，以及 JWT 怎么绕开它们；
6. 能说清"Token 放在 URL 里"有什么风险（`NFR-004`）。

📎 参考（`Consult.txt`）：

> 第 14 关：JWT
> 现在我们正式加入：
> 用户
>  ↓
> 登录
>  ↓
> 账号密码
>  ↓
> MySQL
>  ↓
> 验证成功
>  ↓
> JWT
>  ↓
> 返回前端
> 以后访问：
> GET /student
> 需要：
> Authorization: Bearer xxx
> 后端：
> JWT
>  ↓
> 解析
>  ↓
> 获取用户ID
>  ↓
> 判断身份
>  ↓
> 允许访问

---

## 2. 为什么学 `Lv14-S2`

先制造问题。

你的接口现在是**完全裸奔**的：任何人不需要任何凭证，就能：

```
GET  /students         → 看到所有学生
DELETE /students/1     → 删掉任何一个学生
```

这显然不行。

**方案一：Session**

登录成功后，服务端把"用户ID"存在内存里，发给前端一个 `JSESSIONID`。

| # | 问题 | 后果 |
| --- | --- | --- |
| 1 | 状态在服务端 | 服务重启 → 所有人被踢下线 |
| 2 | 状态在单台机器上 | 部署两个实例 → 请求打到另一个实例就不认识你（除非把 Session 放进 Redis，但那就等于又引入了中心存储） |
| 3 | 浏览器之外不好用 | App / 小程序 / 第三方调用要自己维护 Cookie |
| 4 | 每次请求都要查一次会话存储 | 多一次 IO |

**方案二：JWT**

服务端把"你是谁"**签个名**，然后交给前端自己保管。下次前端带回来，服务端**验签**就能确信"这确实是我签发的，且没被改过"，**不需要查任何存储**。

📌 JWT 的本质不是"加密"，而是"**防篡改的声明**"。
Payload 是**明文可读**的（Base64 编码，不是加密）—— 所以**绝对不能往 JWT 里放密码**。

---

## 3. 环境准备 `Lv14-S3`

| # | 项目 | 要求 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | Lv13 已通关 | 验证码登录链路可用 | Redis 里能看到 code | ⬜ |
| 2 | `T-user` 表 | 按 [05 §4](../05-数据库设计.md#4-t-user--用户表lv14-引入) 建立 | `SELECT * FROM user` 有数据 | ⬜ |
| 3 | JWT 依赖 | `jjwt` 或 `java-jwt` | `pom.xml` 中有该依赖 | ⬜ |
| 4 | 依赖登记 | 已登记到 [03 附录 A](../03-技术栈与选型.md#附录-a--追加区) 与 [§2 版本基线](../03-技术栈与选型.md#2-版本基线) | 表格中有该行 | ⬜ |
| 5 | 密码加密库 | BCrypt（`spring-security-crypto` 或 Spring Security 内置） | 能生成与校验哈希 | ⬜ |
| 6 | Postman | 会设置请求头 `Authorization` | 能发带 Header 的请求 | ⬜ |

📌 JWT 库选型待定，见 [03 附录 B B.2](../03-技术栈与选型.md#附录-b--待决事项)。定下后回填 [03 §2](../03-技术栈与选型.md#2-版本基线)。

---

## 4. 手把手写代码 `Lv14-S4`

### 4.1 `user` 表

```sql
CREATE TABLE `user` (
    id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
    username    VARCHAR(50)  NOT NULL                COMMENT '登录账号',
    password    VARCHAR(100) NOT NULL                COMMENT '加密后的密码',
    phone       VARCHAR(20)  NULL                    COMMENT '手机号',
    status      TINYINT      NOT NULL DEFAULT 1      COMMENT '1启用 0禁用',
    create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_username (username)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '用户表';
```

📌 表结构以 [05 §4](../05-数据库设计.md#4-t-user--用户表lv14-引入) 为准。若本关有调整，**追加到 [05 §3.2 / §4](../05-数据库设计.md)** 并登记 `CHG-*`，不要改已有字段。

⚠️ **初始密码必须写入加密后的值**，不能写明文。插入测试用户时先生成哈希再 `INSERT`。

### 4.2 密码加密（`NFR-003`）

```java
// 生成（只在初始化用户时用一次）
String hash = passwordEncoder.encode("123456");

// 校验（登录时）
boolean ok = passwordEncoder.matches(rawPassword, dbHash);
```

⚠️ **常见错误**：用 MD5/SHA1 直接哈希密码。这类算法太快，可被彩虹表与暴力破解。
必须用**带盐、慢**的算法（BCrypt / Argon2）。

### 4.3 JWT 工具类

```java
@Component
public class JwtUtil {

    // 🚧 待补充：密钥从配置读取，不得硬编码在代码里
    // @Value("${jwt.secret}")

    /** 签发 */
    public String generate(Long userId, String username) {
        // 🚧 待补充：setSubject / claim / setExpiration / signWith
    }

    /** 解析：验签 + 取出用户ID；失败返回 null 或抛异常 */
    public Long parseUserId(String token) {
        // 🚧 待补充
    }
}
```

⚠️ **密钥绝不能硬编码提交到 Git**，放配置且生产环境用环境变量。

### 4.4 登录接口

```java
@PostMapping("/auth/login")
public Result<String> login(@RequestBody LoginDTO dto) {
    // 🚧 待补充：
    // 1. 按 username 查 user
    // 2. 校验密码（passwordEncoder.matches）
    // 3. 校验 status == 1
    // 4. 签发 JWT
    // 5. return Result.success(token)
}
```

### 4.5 受保护接口（本关：手写在 Controller 里）

📌 **本关故意先写脏版本**，Lv17 再重构。

```java
@GetMapping("/students")
public Result<List<Student>> list(@RequestHeader(value = "Authorization", required = false) String auth) {
    // 🚧 待补充：
    // if (auth == null || !auth.startsWith("Bearer ")) throw new BusinessException(ErrorCode.UNAUTHORIZED);
    // Long userId = jwtUtil.parseUserId(auth.substring(7));
    // if (userId == null) throw new BusinessException(ErrorCode.UNAUTHORIZED);
    // ... 继续业务
}
```

📎 参考（`Consult.txt`）：

> 以后访问：
> GET /student
> 需要：
> Authorization: Bearer xxx
> 后端：
> JWT
>  ↓
> 解析
>  ↓
> 获取用户ID
>  ↓
> 判断身份
>  ↓
> 允许访问

### 4.6 运行与验证

```
① POST /auth/login  {"username":"admin","password":"123456"}
   → { "code":200, "msg":"success", "data":"eyJhbGciOi..." }

② GET /students  不带 Header
   → { "code":401, "msg":"未登录或登录已过期", "data":null }

③ GET /students  Header: Authorization: Bearer eyJhbGciOi...
   → { "code":200, "msg":"success", "data":[...] }
```

🚧 待补充：实际执行记录。

### 4.7 JWT 结构观察（必须做）

把返回的 Token 复制到 [jwt.io](https://jwt.io) 或手动 Base64 解码，**亲眼看到 Payload 是明文**。

📌 这个观察直接决定一条安全规则：**JWT 里只放"不怕被看到"的信息**（用户ID、用户名、过期时间）。

---

## 5. 你自己敲 `Lv14-S5`

- [ ] 不看 §4，建 `user` 表并插入一个密码已加密的测试用户
- [ ] 不看 §4，写 `JwtUtil`（签发 + 解析）
- [ ] 不看 §4，写登录接口并拿到 Token
- [ ] 不看 §4，写一个受保护接口，验证"不带 Token 401 / 带 Token 200"
- [ ] 手动解码 Token，指出哪一段是明文

---

## 6. 故意制造错误 `Lv14-S6`

### `Lv14-E01` · 篡改 Token

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把 Token 的 Payload 段改一个字符（如把 userId 从 1 改成 2），再请求 |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 报错 / 状态 | 🚧 待补充（预期：验签失败 → 401） |
| 原因 | 🚧 待补充（签名的作用） |
| 状态 | ⬜ |

📌 这个实验证明"JWT 防篡改"。**必须做。**

### `Lv14-E02` · 把密码明文存库

| 项 | 内容 |
| --- | --- |
| 破坏动作 | `password` 字段直接存 `123456` |
| 预期现象 | 🚧 待补充（功能上"能用"，但违反 `NFR-003`） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 改存 BCrypt 哈希 |
| 状态 | ⬜ |

### `Lv14-E03` · Token 过期

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把过期时间设成 10 秒，等 10 秒后再请求 |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充（异常类型？返回 401 还是 500？） |
| 状态 | ⬜ |

### `Lv14-E04` · `Bearer ` 前缀没处理

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把 `Authorization` 的值直接当 Token 解析（不剥掉 `Bearer `） |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 状态 | ⬜ |

### `Lv14-E05` · 密钥改动

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 重启时改掉 `jwt.secret` |
| 预期现象 | 🚧 待补充（提示：之前签发的 Token 全部失效） |
| 实际现象 | 🚧 待补充 |
| 状态 | ⬜ |

### `Lv14-E06` · Token 放 URL 里

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 改成 `GET /students?token=xxx` |
| 预期现象 | 🚧 待补充（违反 `NFR-004`） |
| 风险 | 🚧 待补充（提示：会进浏览器历史、进服务器 access log、被 Referer 带出去） |
| 恢复动作 | 改回请求头 |
| 状态 | ⬜ |

### `Lv14-E07` · 不校验 Token 直接放行

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 只判断 `auth != null` 就放行，不解析、不验签 |
| 预期现象 | 🚧 待补充（提示：随便一个字符串都能过） |
| 实际现象 | 🚧 待补充 |
| 状态 | ⬜ |

### `Lv14-E08` · 用户被禁用后 Token 仍可用

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把 `status` 改成 0，用之前签发的 Token 请求 |
| 预期现象 | 🚧 待补充（提示：**仍然能通过** —— 这是 JWT 的固有代价） |
| 实际现象 | 🚧 待补充 |
| 缓解方向 | 短过期时间 + 刷新机制、或在 Redis 里维护黑名单 |
| 状态 | ⬜ |

---

## 7. 解释原理 `Lv14-S7`

> 必须依次回答 [09 §4 的五个问题](../09-关卡教学与交付模板.md#4-每关必答的五个问题)。

1. **没有它会发生什么？** 🚧 待补充
2. **它怎么解决的？** 🚧 待补充
3. **实验验证了什么？** 见 `Lv14-E01` ~ `Lv14-E08`
4. **一句话结论** 🚧 待补充
5. **架构哪一层变了？** 认证环节插入（同步 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) 的 Lv14 行）

### 参考文档列出的五个必答问题

📎 原文：

> 这时候你就会理解：
> JWT是什么
> 为什么要登录
> Token是什么
> 为什么不能只靠Session
> 拦截器是什么

| 问题 | 你的答案 |
| --- | --- |
| JWT 是什么？ | 🚧 待补充（提示：三段结构、签名、明文 Payload） |
| 为什么要登录？ | 🚧 待补充 |
| Token 是什么？ | 🚧 待补充 |
| 为什么不能只靠 Session？ | 🚧 待补充（用 §2 的四条） |
| 拦截器是什么？ | 🚧 待补充（**本关只需说"一个能在请求进入 Controller 前先执行的组件"，完整实现在 Lv17**） |

### 必须能答的补充问题

| 问题 | 答案 |
| --- | --- |
| JWT 的 Payload 是加密的吗？ | 🚧 待补充（**不是，是 Base64 编码**） |
| 那为什么别人不能改它？ | 🚧 待补充（签名） |
| 服务端验 Token 需要查数据库吗？ | 🚧 待补充（不需要） |
| 用户被禁用后旧 Token 还能用吗？ | 🚧 待补充（引用 `Lv14-E08`） |
| 密码为什么要用 BCrypt 而不是 MD5？ | 🚧 待补充 |

⚠️ 本节不得出现未在 §4~§6 出现过的新名词。

---

## 8. 小练习 `Lv14-S8`

### `Lv14-Q01` 完整 JWT 结构解读

手动把 Token 三段分别 Base64 解码，写出每一段的内容与作用。

### `Lv14-Q02` 过期时间配置化

把过期时间放到 `application.yml`（如 `jwt.expire-minutes`），并验证 10 秒过期的效果。

### `Lv14-Q03` 验证码登录也发 Token

把 Lv13 的验证码登录补完：校验通过后同样签发 JWT（对应 `FR-U-003`）。

### `Lv14-Q04` 获取当前用户

实现 `GET /auth/me` 返回当前登录用户信息（对应 `FR-U-005`）。

### `Lv14-Q05` 刷新 Token 方案设计

设计一个"短 Token + 长 Refresh Token"方案，写出流程但不一定要实现。

📌 答案写到本关「附录 A · 追加区」，**不要覆盖题目**。

---

## 9. 通关标准 `Lv14-S9`

> 全部勾选才算 ✅ 通关。勾选后到 [10-学习进度记录](../10-学习进度记录.md) 登记。

- [ ] `Lv14-A01` `user` 表建立，密码以**加密形式**存储（`NFR-003`）
- [ ] `Lv14-A02` 登录接口能返回 JWT，且能手动解码看清三段结构
- [ ] `Lv14-A03` **亲眼确认 Payload 是明文**，并能说出这条结论的安全含义
- [ ] `Lv14-A04` 不带 Token 访问受保护接口返回 401，带 Token 返回 200
- [ ] `Lv14-A05` `Lv14-E01`（篡改 Token）已完成，**真的看到验签失败**
- [ ] `Lv14-A06` 能不看资料说清 Session 的至少 2 个麻烦与 JWT 的对应优势
- [ ] `Lv14-A07` 能说清 Token 为什么不能放 URL（`NFR-004`）
- [ ] `Lv14-A08` `Lv14-E01` ~ `Lv14-E08` 中至少完成五个
- [ ] `Lv14-A09` `Lv14-Q01` ~ `Lv14-Q05` 中至少完成两个
- [ ] `Lv14-A10` `API-U-003` ~ `API-U-005` 已回填 [06 §6.2](../06-接口规范.md#62-认证与用户-api-u-)
- [ ] `Lv14-A11` JWT 依赖与密钥配置已登记（[03 §2](../03-技术栈与选型.md#2-版本基线) / [附录 A](../03-技术栈与选型.md#附录-a--追加区)），且密钥未提交到 Git
- [ ] `Lv14-A12` [04 §5.4 第七阶段快照](../04-系统架构与技术演进.md#54-第七阶段结束时lv14-后) 已补图
- [ ] `Lv14-A13` 代码是自己敲的，不是复制的
- [ ] `Lv14-A14` 本关新增内容已按 [00-维护规范](../00-文档使用与维护规范.md) 登记

📌 `Lv14-A03` 与 `Lv14-A05` 是本关的核心，**不允许跳过**。

---

## 10. 下一关 `Lv14-S10`

登录做完了，但你应该注意到一件事：

**你刚刚在每个受保护接口的开头，都写了一遍"取 Header → 剥 Bearer → 解析 Token → 判断是否为空"这四行。**

现在只有 1 个受保护接口，你写 1 遍。等到有 20 个接口呢？

而且，写完之后你发现更糟的问题：前端传来的是这样的东西——

```json
{ "name": "", "age": -5, "gender": "不知道" }
```

你的接口会**照单全收地写进数据库**。

下一关先解决第二个问题：**参数校验**。

➡️ [`Lv15` · 参数校验](Lv15-参数校验.md)

---

## 附录 A · 追加区

> 追加格式见 [00-维护规范 §3.3](../00-文档使用与维护规范.md)。已写入的条目不得删除。

### A.1 Token 结构解读（待学习者填写）

| 段 | 原始内容 | 解码后 |
| --- | --- | --- |
| Header | 🚧 | 🚧 |
| Payload | 🚧 | 🚧 |
| Signature | 🚧 | （不可解码，仅验签） |

### A.2 认证链路验证记录（待学习者填写）

| 场景 | 请求 | 响应 |
| --- | --- | --- |
| 无 Token | 🚧 | 🚧 |
| 有 Token | 🚧 | 🚧 |
| 篡改 Token | 🚧 | 🚧 |

*（后续追加自此向下）*

## 附录 B · 踩坑记录 `Lv14-P0n`

| ID | 日期 | 现象 | 原因 | 解决 | 关联实验 |
| --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — |

## 附录 C · 勘误

*（暂无。格式见 [00-维护规范 §4.2](../00-文档使用与维护规范.md)。）*
