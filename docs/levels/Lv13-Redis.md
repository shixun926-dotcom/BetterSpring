# Lv13 · Redis

> **关卡编号**：`Lv13` ｜ **所属阶段**：第六阶段 · Redis
> **前置关卡**：`Lv12` 事务（✅） ｜ **状态**：⬜ 未开始
> **对应需求**：`FR-U-001`、`FR-U-002`、`FR-U-003` ｜ **对应接口**：`API-U-001`、`API-U-002` ｜ **对应数据表**：—
> **本关产物**：验证码写入 Redis 并 5 分钟自动过期，登录时能校验

---

## 0. 本关速览

| 项目 | 内容 |
| --- | --- |
| 一句话目标 | 用 Redis 做一次真实验证码，并说清 Redis 到底解决了什么问题 |
| 核心知识点 | 五种数据类型（String/Hash/List/Set/ZSet）、过期时间、Key 设计 |
| 预计耗时 | 🚧 待补充 |
| 难度（1~5） | 3 |
| 关键文件 | `service/CodeService.java`、`config/RedisConfig.java`、`application.yml` |
| 架构变化 | 出现**旁路存储**，Service 同时依赖 Mapper 与 Redis |

---

## 1. 本关目标 `Lv13-S1`

1. 能说出 Redis 五种数据类型各自的适用场景（不是背名字，是"什么数据用它"）；
2. 能亲手用 `redis-cli` 完成 String / Hash / List / Set / ZSet 各一次基本操作；
3. 能实现"获取验证码"接口，把验证码写进 Redis 并设置 5 分钟过期；
4. 能用 `TTL` 命令验证过期时间真的在倒计时，并等到它变成 `-2`（消失）；
5. 能设计清晰的 Key 命名（如 `code:13800138000`）；
6. 能说清"验证码为什么不放 MySQL"。

📎 参考（`Consult.txt`）：

> 第 13 关：Redis
> 先不要碰复杂的缓存。
> 我们从：
> Java
>  ↓
> Redis
> 开始。
> 学习：
> String
> Hash
> List
> Set
> ZSet
> 然后做：
> 登录验证码
> 用户获取验证码
>  ↓
> Redis
>  ↓
> 5分钟过期
> 例如：
> code:13800138000
>         ↓
>       928371
> 然后：
> 登录
>  ↓
> 从 Redis 获取验证码
>  ↓
> 验证
> 你会理解：
> Redis 到底解决了什么问题。

---

## 2. 为什么学 `Lv13-S2`

先制造问题。要实现"验证码 5 分钟过期"，用 MySQL 你会怎么做？

```
① 建一张表 verification_code(phone, code, expire_time)
② 每次生成：INSERT 或 UPDATE
③ 校验时：SELECT ... WHERE phone = ? AND expire_time > NOW()
④ 清理：写一个定时任务，每分钟 DELETE FROM ... WHERE expire_time < NOW()
```

**问题清单：**

| # | 问题 | 后果 |
| --- | --- | --- |
| 1 | 每个请求都打数据库 | 高频场景（短信验证码被刷）直接压垮库 |
| 2 | 需要额外的定时清理任务 | 多一个会出故障的组件 |
| 3 | 过期是"应用层判断" | 判断逻辑漏一处就永远不过期 |
| 4 | 单机内存缓存（`Map`） | 重启就丢；多实例之间不共享 |

**Redis 解决的就是这些**：把数据放在内存里，**过期由服务器自己保证**，`SET key value EX 300` 一句话搞定，不需要你写清理任务。

📌 本关的关键判断：**Redis 不是"更快的 MySQL"，它是"另一种用途的存储"。**
适合它的数据特征：**小、热、有生命周期、可容忍丢失**。

---

## 3. 环境准备 `Lv13-S3`

| # | 项目 | 要求 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | Lv12 已通关 | 事务可用 | 转账异常回滚成功 | ⬜ |
| 2 | Redis 已安装并启动 | 可连接 | `redis-cli ping` → `PONG` | ⬜ |
| 3 | 依赖 | `spring-boot-starter-data-redis` | `pom.xml` 中有该依赖 | ⬜ |
| 4 | 依赖登记 | 已登记到 [03 附录 A](../03-技术栈与选型.md#附录-a--追加区) | 表格中有该行 | ⬜ |
| 5 | 客户端 | Redis CLI 或 RedisInsight | 能执行 `SET` / `GET` / `TTL` | ⬜ |

---

## 4. 手把手写代码 `Lv13-S4`

### 4.1 先只用命令行，不碰 Java

📌 **本关第一步不要写代码。** 先把五种类型各操作一遍：

```bash
# String：验证码（本关主用）
SET code:13800138000 928371 EX 300
GET code:13800138000
TTL code:13800138000          # 观察倒计时

# Hash：一个对象的多个字段
HSET student:1 name 张三 age 20
HGETALL student:1

# List：有序、可重复（如消息队列雏形）
LPUSH notices 通知1
RPUSH notices 通知2
LRANGE notices 0 -1

# Set：无序、去重（如标签、共同好友）
SADD tags java spring
SMEMBERS tags

# ZSet：带分数排序（如排行榜）
ZADD ranking 95 张三
ZADD ranking 88 李四
ZREVRANGE ranking 0 -1 WITHSCORES
```

🚧 待补充：把实际执行的输出粘贴到本关「附录 A」。

📌 **五句话记住五种类型：**

| 类型 | 一句话 | 典型场景 | 引入关卡 |
| --- | --- | --- | --- |
| String | 一个键一个值 | 验证码、计数器、缓存单对象 | Lv13 |
| Hash | 一个键一组字段 | 缓存对象（改一个字段不用整体覆盖） | Lv13 |
| List | 有序可重复 | 消息列表、最新 N 条 | Lv13 |
| Set | 无序去重 | 标签、共同好友、去重统计 | Lv13 |
| ZSet | 带分数可排序 | 排行榜、延时队列 | Lv13 |

### 4.2 配置

```yaml
spring:
  data:
    redis:
      host: localhost
      port: 6379
      database: 0
```

⚠️ Spring Boot 3 的配置前缀是 `spring.data.redis`，不是 Spring Boot 2 的 `spring.redis`。

### 4.3 Java 代码

```java
@Service
public class CodeService {

    private static final String CODE_KEY_PREFIX = "code:";
    private static final Duration CODE_TTL = Duration.ofMinutes(5);

    private final StringRedisTemplate redisTemplate;

    public CodeService(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    /** 生成并保存验证码，5 分钟过期 */
    public String generate(String phone) {
        String code = String.valueOf((int) ((Math.random() * 9 + 1) * 100000));
        redisTemplate.opsForValue().set(CODE_KEY_PREFIX + phone, code, CODE_TTL);
        return code;
    }

    /** 校验验证码 */
    public boolean verify(String phone, String input) {
        String saved = redisTemplate.opsForValue().get(CODE_KEY_PREFIX + phone);
        return saved != null && saved.equals(input);
    }
    // 🚧 待补充：校验成功后应立即删除（一次性使用）
}
```

📌 参考文档的 Key 设计（**原文**）：

> 例如：
> code:13800138000
>         ↓
>       928371

📌 `CODE_KEY_PREFIX` 这类常量写法见 [07 §2](../07-代码规范与工程规范.md#2-命名规范)。

### 4.4 Controller

```java
@PostMapping("/auth/code")
public Result<Void> sendCode(@RequestParam String phone) {
    codeService.generate(phone);
    return Result.success();
}

@PostMapping("/auth/login")
public Result<String> login(@RequestParam String phone, @RequestParam String code) {
    // 🚧 待补充：调用 codeService.verify
    // 本关只返回一个占位字符串；真正的 JWT 在 Lv14
}
```

📌 路径定名尚未确定，见 [06 附录 B B.2](../06-接口规范.md#附录-b--待决事项)。定下后回填 [06 §6.2](../06-接口规范.md#62-认证与用户-api-u-) 的 `API-U-001`、`API-U-002`。

### 4.5 运行与验证

```
① POST /auth/code?phone=13800138000
② redis-cli
   > KEYS code:*
   > TTL code:13800138000       ← 看到 300 左右
   > GET code:13800138000       ← 拿到验证码
③ 等待并重复 TTL，观察倒计时
④ 5 分钟后 GET → (nil)，TTL → -2
```

📌 **必须亲眼看到 `TTL` 从 300 变到 -2。** 这是本关"过期由 Redis 保证"的唯一证据。

🚧 待补充：实际观察记录。

### 4.6 结构变化

```
Controller
    ↓
Service ──┬──▶ Mapper ──▶ MySQL
          └──▶ Redis        ← 本关新增
```

📌 同步到 [04 架构图](../04-系统架构与技术演进.md#1-最终架构图)（该图已预留 `Redis ← Service`）。

---

## 5. 你自己敲 `Lv13-S5`

- [ ] 不看 §4，用命令行把五种类型各操作一遍
- [ ] 不看 §4，写出"获取验证码"接口，并在 redis-cli 里看到 key
- [ ] 不看 §4，写出校验逻辑
- [ ] 亲眼看到 `TTL` 倒数到 -2

---

## 6. 故意制造错误 `Lv13-S6`

### `Lv13-E01` · 不设置过期时间

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把 `set(key, value, CODE_TTL)` 改成 `set(key, value)` |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充（`TTL` 返回什么？） |
| 原因 | 🚧 待补充（提示：`TTL = -1` 表示永不过期） |
| 恢复动作 | 加上 TTL |
| 状态 | ⬜ |

### `Lv13-E02` · Redis 没启动

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 停掉 Redis 服务，调用接口 |
| 预期现象 | 🚧 待补充（提示：是启动报错还是请求报错？） |
| 实际现象 | 🚧 待补充 |
| 报错关键行 | 🚧 待补充 |
| 状态 | ⬜ |

### `Lv13-E03` · 端口 / 库号写错

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把 `port` 改成 6380，或 `database` 改成 5 |
| 预期现象 | 🚧 待补充（库号写错时会怎样？） |
| 实际现象 | 🚧 待补充（提示：**不会报错**，只是数据在另一个库里，`redis-cli` 默认库看不到） |
| 状态 | ⬜ |

### `Lv13-E04` · 校验后不删除

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 校验成功后不 `delete`，用同一个验证码再登录一次 |
| 预期现象 | 🚧 待补充（提示：第二次还能成功 —— 这是一个安全问题） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 校验成功后立即删除，或设计"尝试次数限制" |
| 状态 | ⬜ |

### `Lv13-E05` · 验证码可被暴力猜

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 不限制尝试次数，循环调用登录接口 |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 加固方向 | 尝试次数计数（用 Redis `INCR` + TTL）、限制频率 |
| 状态 | ⬜ |

### `Lv13-E06` · 把验证码打进日志

| 项 | 内容 |
| --- | --- |
| 破坏动作 | `log.info("验证码是 {}", code)` |
| 预期现象 | 🚧 待补充（违反 [07 §6](../07-代码规范与工程规范.md#6-日志规范) 第 5 条） |
| 恢复动作 | 移除或脱敏 |
| 状态 | ⬜ |

---

## 7. 解释原理 `Lv13-S7`

> 必须依次回答 [09 §4 的五个问题](../09-关卡教学与交付模板.md#4-每关必答的五个问题)。

1. **没有它会发生什么？** 🚧 待补充（用 §2 的 MySQL 方案）
2. **它怎么解决的？** 🚧 待补充
3. **实验验证了什么？** 见 `Lv13-E01` ~ `Lv13-E06`
4. **一句话结论** 🚧 待补充
5. **架构哪一层变了？** 出现旁路存储（同步 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) 的 Lv13 行）

### 必须能答的问题

| 问题 | 答案 |
| --- | --- |
| Redis 到底解决了什么问题？ | 🚧 待补充 |
| 为什么过期放 Redis 比自己写定时任务好？ | 🚧 待补充 |
| `TTL = -1` 和 `TTL = -2` 分别是什么意思？ | 🚧 待补充 |
| Key 为什么设计成 `code:{phone}`？ | 🚧 待补充 |
| Redis 里的数据丢了会怎样？ | 🚧 待补充（提示：验证码丢了 = 重新获取，可接受） |

⚠️ 本节不得出现未在 §4~§6 出现过的新名词。
📌 特别地：**本节禁止展开"缓存穿透/击穿/雪崩"** —— 参考文档明确说"先不要碰复杂的缓存"，这些留到后续需要时作为 [附录 A 追加](../README.md#附录-a--追加区)。

---

## 8. 小练习 `Lv13-S8`

### `Lv13-Q01` 一次性验证码

校验成功后立即删除，并验证同一个验证码不能用第二次。

### `Lv13-Q02` 尝试次数限制

用 Redis 的 `INCR` + `EXPIRE` 实现"同一手机号验证码最多尝试 5 次"。

### `Lv13-Q03` 用 Hash 缓存学生

用 `HSET` 缓存一个学生对象，并比较它与 String 存 JSON 的差异。

### `Lv13-Q04` 用 ZSet 做排行榜

用 ZSet 做"学生成绩排行榜"，取前 3 名。

### `Lv13-Q05` 不用 Redis

用 MySQL 实现同样的验证码功能，写出你需要额外写的清理逻辑，然后对比两者的代码量。

📌 答案写到本关「附录 A · 追加区」，**不要覆盖题目**。

---

## 9. 通关标准 `Lv13-S9`

> 全部勾选才算 ✅ 通关。勾选后到 [10-学习进度记录](../10-学习进度记录.md) 登记。

- [ ] `Lv13-A01` 用命令行把五种数据类型各操作过一遍
- [ ] `Lv13-A02` 能不看资料说出五种类型各自的适用场景
- [ ] `Lv13-A03` "获取验证码"接口写完，且 `redis-cli` 能看到 key
- [ ] `Lv13-A04` **亲眼看到 `TTL` 从 300 倒数到 -2**（本关核心证据）
- [ ] `Lv13-A05` 登录校验能正确比对 Redis 里的验证码
- [ ] `Lv13-A06` 能说清"验证码为什么不用 MySQL"的至少 3 条理由
- [ ] `Lv13-A07` `Lv13-E01` ~ `Lv13-E06` 中至少完成四个
- [ ] `Lv13-A08` `Lv13-Q01` ~ `Lv13-Q05` 中至少完成两个
- [ ] `Lv13-A09` `API-U-001`、`API-U-002` 的路径已定下并回填 [06 §6.2](../06-接口规范.md#62-认证与用户-api-u-)
- [ ] `Lv13-A10` 依赖已登记到 [03 附录 A](../03-技术栈与选型.md#附录-a--追加区)
- [ ] `Lv13-A11` 代码是自己敲的，不是复制的
- [ ] `Lv13-A12` 本关新增内容已按 [00-维护规范](../00-文档使用与维护规范.md) 登记

📌 `Lv13-A04` 是本关的核心，**不允许跳过**。

---

## 10. 下一关 `Lv13-S10`

验证码做完了。但登录之后呢？

现在的逻辑是：验证码对了，接口返回一个字符串占位。**下一个请求怎么知道你是谁？**

你可以在登录成功后把"用户ID"存在服务端内存里 —— 这就是 **Session**。但它有两个麻烦：

1. 服务重启，所有人被踢下线；
2. 部署两个实例，请求打到另一个实例上，它不认识你。

而且参考文档提到了一个更根本的问题：**为什么不能只靠 Session？**

下一关：**JWT**。

➡️ [`Lv14` · JWT](Lv14-JWT.md)

---

## 附录 A · 追加区

> 追加格式见 [00-维护规范 §3.3](../00-文档使用与维护规范.md)。已写入的条目不得删除。

### A.1 五种类型实测记录（待学习者填写）

| 类型 | 命令 | 实际输出 |
| --- | --- | --- |
| String | 🚧 | 🚧 |
| Hash | 🚧 | 🚧 |
| List | 🚧 | 🚧 |
| Set | 🚧 | 🚧 |
| ZSet | 🚧 | 🚧 |

### A.2 TTL 观察记录（待学习者填写）

| 时刻 | `TTL code:13800138000` |
| --- | --- |
| 刚写入 | 🚧 |
| +1 分钟 | 🚧 |
| +5 分钟 | 🚧（应为 -2） |

*（后续追加自此向下）*

## 附录 B · 踩坑记录 `Lv13-P0n`

| ID | 日期 | 现象 | 原因 | 解决 | 关联实验 |
| --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — |

## 附录 C · 勘误

*（暂无。格式见 [00-维护规范 §4.2](../00-文档使用与维护规范.md)。）*
