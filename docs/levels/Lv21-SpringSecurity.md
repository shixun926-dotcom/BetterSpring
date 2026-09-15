# Lv21 · Spring Security

> **关卡编号**：`Lv21` ｜ **所属阶段**：第九阶段 · 把它变成一个真正的项目
> **前置关卡**：`Lv20` 文件上传（✅） ｜ **状态**：⬜ 未开始
> **对应需求**：`FR-U-008`、`FR-A-003`、`FR-A-004` ｜ **对应接口**：`API-A-*` 系列 ｜ **对应数据表**：`T-role`、`T-user_role`
> **本关产物**：认证授权体系化，权限控制生效

---

## 0. 本关速览

| 项目 | 内容 |
| --- | --- |
| 一句话目标 | 把散落的权限判断换成统一的授权体系，并说清"认证"与"授权"的区别 |
| 核心知识点 | 认证 / 授权、角色、权限、`SecurityFilterChain`、注解式鉴权 |
| 预计耗时 | 🚧 待补充 |
| 难度（1~5） | 5 |
| 关键文件 | `config/SecurityConfig.java`、`service/UserDetailsServiceImpl.java`、`T-role` / `T-user_role` |
| 架构变化 | 认证授权体系化，替代 / 包裹 [Lv17](Lv17-拦截器.md) 的自定义拦截器 |

⚠️ **本关是全项目最难的一关。** 它同时涉及：过滤器链（比拦截器更靠前）、`IOC`、`AOP`、数据库表设计、JWT 集成。
**如果 Lv17 和 Lv18 是靠背下来的，本关会很痛苦。** 这是设计如此 —— 参考文档把它放在第九阶段是有原因的。

---

## 1. 本关目标 `Lv21-S1`

1. 能说清**认证（Authentication）**与**授权（Authorization）**的区别；
2. 能设计角色与权限的表结构，并说清"角色"与"权限"为什么要分开；
3. 能理解 Spring Security 的过滤器链位置（比 [Lv17](Lv17-拦截器.md) 的拦截器更靠前）；
4. 能把 [Lv14](Lv14-JWT.md) 的 JWT 集成进 Spring Security（替换或包裹自定义拦截器）；
5. 能用注解或配置实现"仅管理员可访问"；
6. 能说清"无权限"（403）与"未登录"（401）的区别，并在实验里分别验证；
7. 能说出**为什么"忘记给新接口加权限判断"是最大的风险**，以及 Spring Security 的默认策略怎么缓解它。

📎 参考（`Consult.txt`）：

> 后面甚至可以加入：
> Redis
> RabbitMQ
> WebSocket
> Spring Security
> Docker
> Nginx
> Vue3

以及最终形态中的：

> 用户
>  ├── 注册
>  ├── 登录
>  ├── JWT
>  └── 权限
>
> 管理员
>  ├── 用户管理
>  ├── 学生管理
>  └── 权限管理

📌 本关与 [Lv17](Lv17-拦截器.md) 的关系见 [08 附录 B B.1](../08-关卡总览与路线图.md#附录-b--待决事项)：是"用 Security 全面替代拦截器"，还是"拦截器负责 JWT 认证、Security 负责授权"。**先做决定再动手。**

---

## 2. 为什么学 `Lv21-S2`

先制造问题。

[Lv17](Lv17-拦截器.md) 的拦截器现在只做了一件事：**校验 Token 是否有效**。所有登录用户一视同仁。

现在需求来了：

```
学生  → 只能查看自己的信息、选课、查成绩
教师  → 能录入成绩、查看所授课程学生
管理员 → 能管理用户、学生、课程、权限
```

**用拦截器怎么做？**

```java
// 拦截器里会迅速变成这样
if (uri.startsWith("/admin/users")) { requireRole(user, "ADMIN"); }
else if (uri.startsWith("/admin/students")) { requireRole(user, "ADMIN"); }
else if (uri.startsWith("/teacher/scores")) { requireRole(user, "TEACHER", "ADMIN"); }
else if (uri.equals("/students/me")) { ... }
// ... 20 个接口 20 条 if
```

| # | 问题 | 后果 |
| --- | --- | --- |
| 1 | 权限规则与路由字符串耦合 | 改一个 URL 就漏一条规则 |
| 2 | **新接口默认没规则** | **默认放开 = 漏一个就是后门** |
| 3 | 无法表达"数据级权限" | "只能看自己的成绩"这种规则写不进去 |
| 4 | 无法复用 | 每个项目重写一遍 |
| 5 | 顺序脆弱 | `if` 的先后顺序会改变结果 |

**Spring Security 解决的就是这些**，核心是两点：

1. **默认拒绝**（deny by default）—— 没明确放开的，就是拒绝。第 2 条风险被结构性地消除了；
2. 认证与授权是**框架职责**，规则用声明式表达，不写在 `if` 里。

📌 关键认识：

> **认证解决"你是谁"，授权解决"你能做什么"。**
> [Lv14](Lv14-JWT.md) 做的是认证；本关做的是授权。

---

## 3. 环境准备 `Lv21-S3`

| # | 项目 | 要求 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | Lv20 已通关 | 第八阶段全部完成 | 全部接口可用 | ⬜ |
| 2 | 依赖 | `spring-boot-starter-security` | `pom.xml` 中有该依赖 | ⬜ |
| 3 | 依赖登记 | 已登记到 [03 附录 A](../03-技术栈与选型.md#附录-a--追加区) | 表格中有该行 | ⬜ |
| 4 | 表 | `T-role`、`T-user_role` 已建立 | 见 [05 §5.1](../05-数据库设计.md#51-t-role--t-user_role) | ⬜ |
| 5 | 表设计 | 已补齐 [05 §5.1](../05-数据库设计.md#51-t-role--t-user_role) | 并登记 `CHG-*` | ⬜ |
| 6 | 方案决定 | 见 [08 附录 B B.1](../08-关卡总览与路线图.md#附录-b--待决事项) | 已作出决定 | ⬜ |
| 7 | 异常处理器 | `GlobalExceptionHandler` 已能处理 401/403 | 见 [Lv11](Lv11-异常处理.md) | ⬜ |

⚠️ ⚠️ **重要提醒**：加入 `spring-boot-starter-security` 依赖的**那一刻**，你现有的所有接口都会被自动保护（默认全部需要登录，且会自动生成一个随机密码打印在控制台）。
**这是正常的，不要慌。** 本关 §6 的第一个实验就是这个。

---

## 4. 手把手写代码 `Lv21-S4`

### 4.1 表结构（补齐 [05 §5.1](../05-数据库设计.md#51-t-role--t-user_role)）

```sql
-- db/03-migration-002.sql
CREATE TABLE role (
    id   BIGINT      NOT NULL AUTO_INCREMENT,
    code VARCHAR(50) NOT NULL COMMENT '角色编码，如 ADMIN / TEACHER / STUDENT',
    name VARCHAR(50) NOT NULL COMMENT '角色名称',
    PRIMARY KEY (id),
    UNIQUE KEY uk_code (code)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '角色表';

CREATE TABLE user_role (
    id      BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_role (user_id, role_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '用户角色关联表';
```

📌 这些表在 [05 §2](../05-数据库设计.md#2-表清单) 中已登记为 `T-role` / `T-user_role`，本关只是**把它建出来**并补全字段。

### 4.2 用户加载

```java
@Service
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UserMapper userMapper;

    @Override
    public UserDetails loadUserByUsername(String username) {
        // 🚧 待补充：
        // 1. 按 username 查 user
        // 2. 查出该用户的角色（关联 T-user_role / T-role）
        // 3. 组装成 Spring Security 的 UserDetails（含 authorities）
    }
}
```

### 4.3 安全配置

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        // 🚧 待补充：
        // 1. csrf 关闭（前后端分离 + JWT）
        // 2. session 设为 STATELESS
        // 3. 白名单：/auth/** 放行
        // 4. 其余请求认证
        // 5. 挂上 JWT 过滤器
        // 6. 401 / 403 的响应体也要是 Result<T>（见 §4.5）
        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();     // 与 Lv14 一致
    }
}
```

### 4.4 JWT 过滤器（与 [Lv14](Lv14-JWT.md)/[Lv17](Lv17-拦截器.md) 的衔接）

```java
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    // 🚧 待补充：解析 Token → 构造 Authentication → 放入 SecurityContextHolder
}
```

📌 **与 [Lv17](Lv17-拦截器.md) 的取舍**（必须明确写出结论）：

| 方案 | 做法 | 优点 | 缺点 |
| --- | --- | --- | --- |
| A. 全面替换 | 删掉 `AuthInterceptor`，认证与授权都交给 Security | 统一、默认拒绝 | 要重写认证部分 |
| B. 并存 | 拦截器继续做 JWT 认证，Security 只做授权 | 改动小 | 两套机制，容易互相绕过 |

⚠️ 方案 B 有个真实陷阱：**Security 的过滤器链在拦截器之前**。如果 Security 配置成放行全部、靠拦截器认证，那么任何忘记配 Security 的地方都会是敞开的。
**如果选 B，必须在文档里写清"放行全部"这个决定的理由与风险。**

🚧 待补充：本项目选择与理由（并回填 [08 附录 B B.1](../08-关卡总览与路线图.md#附录-b--待决事项) 与 [04 附录 B B.2](../04-系统架构与技术演进.md#附录-b--待决事项)）。

### 4.5 401 与 403 也要走统一出口

```java
// 🚧 待补充：
// http.exceptionHandling()
//     .authenticationEntryPoint(...)   // 401：未登录
//     .accessDeniedHandler(...)        // 403：无权限
// 两者都要写出 Result<T> 的 JSON，而不是 Security 默认的 HTML
```

📌 不做这一步，你的 [Lv10](Lv10-统一返回结果.md) 统一返回就在认证失败这条路上破功了。

### 4.6 接口鉴权

```java
// 方式一：配置式
// http.authorizeHttpRequests()
//     .requestMatchers("/admin/**").hasRole("ADMIN")
//     .anyRequest().authenticated();

// 方式二：注解式
@PreAuthorize("hasRole('ADMIN')")
@DeleteMapping("/{id}")
public Result<Void> delete(@PathVariable Integer id) { ... }
```

📌 注解式需要 `@EnableMethodSecurity`。

### 4.7 运行与验证

| # | 场景 | 预期 |
| --- | --- | --- |
| 1 | 学生 Token 访问 `DELETE /students/1` | **403** |
| 2 | 管理员 Token 访问同一接口 | 200 |
| 3 | 不带 Token 访问受保护接口 | **401** |
| 4 | 不带 Token 访问白名单 | 正常 |

📌 场景 1 与 3 必须**分别验证**：401 和 403 是两件事。

---

## 5. 你自己敲 `Lv21-S5`

- [ ] 先只加依赖，观察全部接口被锁住的现象（这就是 `Lv21-E01`）
- [ ] 建 `role` / `user_role` 表并插入角色数据
- [ ] 不看 §4，写 `UserDetailsService`
- [ ] 不看 §4，写 `SecurityFilterChain` 并让白名单生效
- [ ] 不看 §4，写出 401 / 403 的统一 JSON
- [ ] 分别验证 401 与 403

---

## 6. 故意制造错误 `Lv21-S6`

### `Lv21-E01` · 只加依赖，不做任何配置

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 只加 `spring-boot-starter-security` 依赖，启动 |
| 预期现象 | 🚧 待补充（先写预期） |
| 实际现象 | 🚧 待补充（提示：控制台打印 `Using generated security password: xxx`；所有接口 401） |
| 原因 | 🚧 待补充（**默认拒绝**，这就是 Security 的核心价值） |
| 状态 | ⬜ |

### `Lv21-E02` · 忘配白名单

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 不把 `/auth/**` 加入白名单 |
| 预期现象 | 🚧 待补充（提示：登录接口需要登录 → 死锁） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 加入白名单 |
| 状态 | ⬜ |

### `Lv21-E03` · 角色前缀写错

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 数据库里角色是 `ADMIN`，配置里写 `hasRole("ADMIN")` |
| 预期现象 | 🚧 待补充（提示：`hasRole` 会自动加 `ROLE_` 前缀 → 匹配不上） |
| 实际现象 | 🚧 待补充（**403，但不报错**） |
| 恢复动作 | 数据库存 `ROLE_ADMIN`，或用 `hasAuthority("ADMIN")` |
| 状态 | ⬜ |

📌 这是最容易踩的坑之一：**静默 403，没有任何报错。**

### `Lv21-E04` · CSRF 没关

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 保留默认的 CSRF 防护 |
| 预期现象 | 🚧 待补充（POST 请求 403） |
| 实际现象 | 🚧 待补充 |
| 原因 | 🚧 待补充（前后端分离 + JWT 场景下不需要 CSRF token） |
| 恢复动作 | `http.csrf(AbstractHttpConfigurer::disable)` |
| 状态 | ⬜ |

### `Lv21-E05` · Session 没设为 STATELESS

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 保留默认 Session 策略 |
| 预期现象 | 🚧 待补充（JWT 与 Session 两套机制同时存在） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | `SessionCreationPolicy.STATELESS` |
| 状态 | ⬜ |

### `Lv21-E06` · 401/403 返回了 HTML

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 不配 `authenticationEntryPoint` / `accessDeniedHandler` |
| 预期现象 | 🚧 待补充（前端收到 HTML，解析失败） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 两个 handler 都返回 `Result` JSON |
| 状态 | ⬜ |

### `Lv21-E07` · 过滤器里不设置 `SecurityContext`

| 项 | 内容 |
| --- | --- |
| 破坏动作 | JWT 过滤器里解析出了用户，但不往 `SecurityContextHolder` 放 |
| 预期现象 | 🚧 待补充（Token 有效但仍 401/403） |
| 实际现象 | 🚧 待补充 |
| 状态 | ⬜ |

### `Lv21-E08` · 注解式鉴权没开启

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 用 `@PreAuthorize` 但不加 `@EnableMethodSecurity` |
| 预期现象 | 🚧 待补充（**静默失效** —— 注解被完全忽略） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 加 `@EnableMethodSecurity` |
| 状态 | ⬜ |

📌 又是"静默失效"。本套文档里它已经出现第四次了（[Lv15](Lv15-参数校验.md) `@Valid`、[Lv18](Lv18-AOP.md) 切点、[Lv12](Lv12-事务.md) private、本关注解式鉴权）。
**"注解写了但没生效"是本项目最需要警惕的一类问题，必须养成"写完就验证"的习惯。**

### `Lv21-E09` · 密码编码器换了

| 项 | 内容 |
| --- | --- |
| 破坏动作 | [Lv14](Lv14-JWT.md) 用 BCrypt 存的密码，本关换成别的 `PasswordEncoder` |
| 预期现象 | 🚧 待补充（**所有老用户登不上**） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 保持一致 |
| 状态 | ⬜ |

### `Lv21-E10` · 错误响应泄露内部信息

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 401 handler 把异常堆栈也返回 |
| 预期现象 | 🚧 待补充（违反 `NFR-002`） |
| 恢复动作 | 只返回统一 JSON |
| 状态 | ⬜ |

---

## 7. 解释原理 `Lv21-S7`

> 必须依次回答 [09 §4 的五个问题](../09-关卡教学与交付模板.md#4-每关必答的五个问题)。

1. **没有它会发生什么？** 🚧 待补充（用 §2 的 5 条问题）
2. **它怎么解决的？** 🚧 待补充
3. **实验验证了什么？** 见 `Lv21-E01` ~ `Lv21-E10`
4. **一句话结论** 🚧 待补充
5. **架构哪一层变了？** 授权体系化（同步 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) 的 Lv21 行）

### 必须能答的问题

| 问题 | 答案 |
| --- | --- |
| 认证与授权的区别？ | 🚧 待补充 |
| 401 与 403 的区别？ | 🚧 待补充 |
| Security 的过滤器链在请求链路的什么位置？ | 🚧 待补充（比 [Lv17](Lv17-拦截器.md) 的拦截器**更靠前**） |
| **"默认拒绝"为什么比"默认放开"安全？** | 🚧 待补充（这是本关最重要的结论） |
| 角色与权限为什么要分开？ | 🚧 待补充 |
| `@PreAuthorize` 不生效的原因一般是什么？ | 🚧 待补充（引用 `Lv21-E08`） |

⚠️ 本节不得出现未在 §4~§6 出现过的新名词。

---

## 8. 小练习 `Lv21-S8`

### `Lv21-Q01` 三角色

为 `学生` / `教师` / `管理员` 三个角色各配一条不同的接口权限，并分别验证。

### `Lv21-Q02` 数据级权限

实现"学生只能查看自己的信息"（`GET /students/me`），说明它与"接口级权限"的区别。

### `Lv21-Q03` 权限表化

把 `hasRole(...)` 硬编码的规则改成从数据库读取，说明何时值得这么做。

### `Lv21-Q04` 与管理员的接口对接

补全 `API-A-001` ~ `API-A-003`（用户管理 / 学生管理 / 权限管理）的接口设计并登记到 [06 §6.3](../06-接口规范.md#63-课程--成绩--管理员)。

### `Lv21-Q05` 写进规范

把"新增接口必须显式声明权限"写进 [07 §3](../07-代码规范与工程规范.md#3-分层边界规范硬约定)，并登记 `CHG-*`。

📌 答案写到本关「附录 A · 追加区」，**不要覆盖题目**。

---

## 9. 通关标准 `Lv21-S9`

> 全部勾选才算 ✅ 通关。勾选后到 [10-学习进度记录](../10-学习进度记录.md) 登记。

- [ ] `Lv21-A01` 经历过 `Lv21-E01`（只加依赖就被锁住），并能解释"默认拒绝"的价值
- [ ] `Lv21-A02` `role` / `user_role` 表已建立，用户与角色能正确关联
- [ ] `Lv21-A03` `UserDetailsService` 与 `SecurityFilterChain` 可用
- [ ] `Lv21-A04` **401 与 403 分别验证成功**，且都是 `Result<T>` JSON
- [ ] `Lv21-A05` "仅管理员可删除学生"生效：学生 Token 403，管理员 Token 200
- [ ] `Lv21-A06` 能不看资料说清认证与授权、401 与 403 的区别
- [ ] `Lv21-A07` 能说清 Security 过滤器链与 [Lv17](Lv17-拦截器.md) 拦截器的先后与取舍
- [ ] `Lv21-A08` 与 [Lv17](Lv17-拦截器.md) 的关系已作出明确决定并写入文档（回填 [08 附录 B B.1](../08-关卡总览与路线图.md#附录-b--待决事项)、[04 附录 B B.2](../04-系统架构与技术演进.md#附录-b--待决事项)）
- [ ] `Lv21-A09` `Lv21-E01` ~ `Lv21-E10` 中至少完成六个
- [ ] `Lv21-A10` `Lv21-Q01` ~ `Lv21-Q05` 中至少完成两个
- [ ] `Lv21-A11` 密码编码器与 [Lv14](Lv14-JWT.md) 保持一致，老用户仍能登录
- [ ] `Lv21-A12` [05 §5.1](../05-数据库设计.md#51-t-role--t-user_role) 已由"🚧 待补充"补齐为实际字段
- [ ] `Lv21-A13` 代码是自己敲的，不是复制的
- [ ] `Lv21-A14` 本关新增内容已按 [00-维护规范](../00-文档使用与维护规范.md) 登记

📌 `Lv21-A01`、`Lv21-A04`、`Lv21-A05` 是本关的核心。

---

## 10. 下一关 `Lv21-S10`

权限做完了。现在考虑一个业务场景：

**学生选课成功后，要给这个学生发一条通知（站内信 / 短信 / 邮件）。**

最直接的写法是在选课 Service 里直接调用通知服务：

```java
@Transactional
public void selectCourse(Integer studentId, Integer courseId) {
    courseSelectionMapper.insert(...);
    courseMapper.incrementSelected(...);
    noticeService.send(studentId, "选课成功");   // ← 直接调用
}
```

问题来了：

| # | 问题 | 后果 |
| --- | --- | --- |
| 1 | 通知服务慢（发短信要 2 秒） | 选课接口要等 2 秒才返回 |
| 2 | 通知服务挂了 | **整个选课失败并回滚** —— 明明课已经选上了 |
| 3 | 想改成异步发 | 得改业务代码 |
| 4 | 想加第二个消费者（比如同时发邮件） | 还得改业务代码 |

这是一个典型的"**主流程不该被旁支流程拖累**"的场景。

下一关：**RabbitMQ**。

➡️ [`Lv22` · RabbitMQ](Lv22-RabbitMQ.md)

---

## 附录 A · 追加区

> 追加格式见 [00-维护规范 §3.3](../00-文档使用与维护规范.md)。已写入的条目不得删除。

### A.1 与 [Lv17](Lv17-拦截器.md) 的关系决定（待学习者填写）

| 项 | 记录 |
| --- | --- |
| 选择方案（替换 / 并存） | 🚧 |
| 理由 | 🚧 |
| 对 `AuthInterceptor` 的处置 | 🚧 |
| 决定的日期 | 🚧 |

### A.2 401 / 403 验证记录（待学习者填写）

| 场景 | 期望 | 实际 |
| --- | --- | --- |
| 学生 Token 删学生 | 403 | 🚧 |
| 管理员 Token 删学生 | 200 | 🚧 |
| 无 Token 访问 | 401 | 🚧 |

*（后续追加自此向下）*

## 附录 B · 踩坑记录 `Lv21-P0n`

| ID | 日期 | 现象 | 原因 | 解决 | 关联实验 |
| --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — |

## 附录 C · 勘误

*（暂无。格式见 [00-维护规范 §4.2](../00-文档使用与维护规范.md)。）*
