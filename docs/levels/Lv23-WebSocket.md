# Lv23 · WebSocket

> **关卡编号**：`Lv23` ｜ **所属阶段**：第九阶段 · 把它变成一个真正的项目
> **前置关卡**：`Lv22` RabbitMQ（✅） ｜ **状态**：⬜ 未开始
> **对应需求**：`FR-N-002` ｜ **对应接口**：`API-N-*` ｜ **对应数据表**：—
> **本关产物**：成绩录入后实时推送给在线学生

---

## 0. 本关速览

| 项目 | 内容 |
| --- | --- |
| 一句话目标 | 实现服务端主动推送，并说清它与轮询、MQ 的区别 |
| 核心知识点 | 长连接、握手升级、`WebSocketHandler`、服务端推送、广播与会话管理 |
| 预计耗时 | 🚧 待补充 |
| 难度（1~5） | 4 |
| 关键文件 | `config/WebSocketConfig.java`、`handler/NoticeWebSocketHandler.java` |
| 架构变化 | 出现**服务端主动推送**通道 |

📌 本关是**扩展关卡**（`FR-N-002` 标记为"扩展"）。若时间有限可降低深度，但**必须能说清"为什么 HTTP 做不到"**。

---

## 1. 本关目标 `Lv23-S1`

1. 能说清 HTTP 的"请求-响应"模型为什么无法让服务端主动开口；
2. 能说清算轮询与长连接在**请求量**上的具体差距（会用数字说话）；
3. 能建立 WebSocket 端点并完成一次握手；
4. 能实现"服务端向指定用户推送一条消息"和"向所有在线用户广播"；
5. 能说清 WebSocket 与 [Lv22](Lv22-RabbitMQ.md) 的 MQ **不是一回事**（一个面向浏览器，一个面向服务端）；
6. 能说出长连接带来的新问题（连接数、心跳、断线重连、多实例广播）。

📎 参考（`Consult.txt`）：

> 后面甚至可以加入：
> Redis
> RabbitMQ
> WebSocket
> Spring Security
> Docker
> Nginx
> Vue3

📌 参考文档把 `RabbitMQ` 与 `WebSocket` 相邻列出，这个顺序设计得很好：
**它们解决的是同一个问题的两半** —— 服务端之间怎么异步（MQ），服务端怎么主动通知浏览器（WebSocket）。

---

## 2. 为什么学 `Lv23-S2`

先制造问题。

**需求**：教师录入成绩后，学生页面上的成绩**立即**更新。

**方案一：学生手动刷新**

用户得自己点。体验差，而且学生不知道什么时候该点。

**方案二：轮询（前端定时请求）**

```js
setInterval(() => fetch('/scores/my'), 3000);   // 每 3 秒问一次
```

算一笔账：

| 项 | 数值 |
| --- | --- |
| 在线学生 | 1000 人 |
| 轮询间隔 | 3 秒 |
| 每秒请求数 | 1000 ÷ 3 ≈ **333 次/秒** |
| 一次成绩变更 | 可能几小时才发生一次 |
| 有效请求占比 | **接近于 0** |

**99% 以上的请求都是在问"变了吗"，答案都是"没有"。**

服务器每秒被白问 333 次，数据库被白查 333 次。

**方案三：服务端主动推送（WebSocket）**

连接建立后**一直保持**，服务端有消息就直接推过去。

| 项 | 数值 |
| --- | --- |
| 连接数 | 1000 条（一直保持） |
| 空闲时的请求数 | **0** |
| 有变更时 | 只推给相关的那几个人 |

📌 核心区别：

| 模型 | 谁先开口 |
| --- | --- |
| HTTP | **只能客户端先开口** |
| WebSocket | **双方都可以随时开口** |

⚠️ 注意：WebSocket **不是**"更快的 HTTP"。它是一条**全双工长连接**，握手时借用了一次 HTTP，之后就完全是另一个协议了。

---

## 3. 环境准备 `Lv23-S3`

| # | 项目 | 要求 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | Lv22 已通关 | MQ 链路可用 | 消费者能收到消息 | ⬜ |
| 2 | 依赖 | `spring-boot-starter-websocket` | `pom.xml` 中有该依赖 | ⬜ |
| 3 | 依赖登记 | 已登记到 [03 附录 A](../03-技术栈与选型.md#附录-a--追加区) | 表格中有该行 | ⬜ |
| 4 | 测试客户端 | 能连 WebSocket 的工具 | Postman / Apifox / 浏览器控制台 / `wscat` | ⬜ |
| 5 | 成绩功能 | 至少有一个可触发的成绩变更 | 见 [Lv21](Lv21-SpringSecurity.md) Q04 | ⬜ |

⚠️ **与 [Lv21](Lv21-SpringSecurity.md) 的冲突**：Spring Security 的过滤器链默认会拦住 `/ws/**`。必须显式放行或做 Token 校验，否则握手直接 401。
**这是本关第一个坑，建议先按 §6 的 `Lv23-E05` 亲手踩一次。**

---

## 4. 手把手写代码 `Lv23-S4`

### 4.1 配置

```java
@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(noticeHandler, "/ws/notice")
                .setAllowedOriginPatterns("*");    // 🚧 生产环境必须限定来源
    }
}
```

⚠️ `setAllowedOrigins("*")` 在生产是安全问题（跨站 WebSocket 劫持）。学习阶段可用，**上线前必须收紧**。

### 4.2 握手与身份

```
客户端：GET /ws/notice
        Upgrade: websocket
        Connection: Upgrade
        Sec-WebSocket-Key: xxx
        （可带 Authorization 或 ?token=xxx）

服务端：101 Switching Protocols
        ↓
        之后就是 WebSocket 帧，不再是 HTTP
```

📌 **浏览器原生 `WebSocket` API 不支持自定义请求头**，所以 Token 通常通过**查询参数**传递。
这与 `NFR-004`（Token 不得出现在 URL）冲突 —— 是一个已知的取舍，**必须在本关记录理由**。

🚧 待补充：本项目选择的方案（查询参数 / 子协议 / Cookie）与理由。

### 4.3 Handler

```java
@Component
@Slf4j
public class NoticeWebSocketHandler extends TextWebSocketHandler {

    // 保存在线会话：userId → WebSocketSession
    private static final Map<Long, WebSocketSession> SESSIONS = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        // 🚧 待补充：取出 userId，放入 SESSIONS
    }

    @Override
    public void handleTextMessage(WebSocketSession session, TextMessage message) {
        // 🚧 待补充：处理客户端发来的消息（本项目可能不需要）
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        // 🚧 待补充：从 SESSIONS 移除（**不清理就是内存泄漏**）
    }

    /** 推送给指定用户 */
    public void sendTo(Long userId, String text) { /* 🚧 待补充 */ }

    /** 广播 */
    public void broadcast(String text) { /* 🚧 待补充 */ }
}
```

⚠️ `SESSIONS` 用 `ConcurrentHashMap`，因为多个连接会并发增删。
⚠️ `WebSocketSession` 的 `sendMessage` **不是线程安全的**，并发推送同一会话会抛 `IllegalStateException`。

### 4.4 业务触发

```java
// 成绩录入成功后推送
public void updateScore(Integer studentId, ...) {
    scoreMapper.update(...);
    noticeWebSocketHandler.sendTo(studentId, "你的成绩已更新");
}
```

📌 **本关与 [Lv22](Lv22-RabbitMQ.md) 的组合用法**（推荐）：
成绩录入 → 投递 MQ → 消费者 → WebSocket 推送。
这样可以避免"业务线程被 WebSocket 写入阻塞"，也让推送可以重试。
🚧 待补充：本项目是否采用这个组合。

### 4.5 运行与验证

```
① 客户端（浏览器控制台）连接：
   const ws = new WebSocket('ws://localhost:8080/ws/notice?token=xxx');
   ws.onmessage = e => console.log(e.data);

② 用 Postman 调用"录入成绩"接口
③ 客户端控制台**立刻**收到："你的成绩已更新"
④ 断开客户端，再录入成绩 → 看服务端报什么错
```

🚧 待补充：实际观察记录。

### 4.6 长连接带来的新问题（本关必答）

| # | 问题 | 说明 | 对策 |
| --- | --- | --- | --- |
| 1 | 连接数占用内存 | 每个连接一个 `WebSocketSession` | 限制单机连接数、水平扩展 |
| 2 | 断线不知道 | 网络中断时服务端可能不知道 | 心跳（ping/pong） |
| 3 | 断线后消息丢失 | 用户离线时推送不到 | 落库 + 上线后拉取未读 |
| 4 | 多实例广播 | 实例 A 的推送到不了连在实例 B 的用户 | 用 Redis 发布订阅 / MQ 广播 |
| 5 | 内存泄漏 | 会话没清理 | `afterConnectionClosed` 必须 `remove` |
| 6 | 与 Security 冲突 | 握手被拦 | 显式放行 + 握手时校验 Token |

📌 第 4 条正好把 [Lv13](Lv13-Redis.md) 和 [Lv22](Lv22-RabbitMQ.md) 串起来了 —— **这就是"扩展能力"之间互相咬合的地方。**

---

## 5. 你自己敲 `Lv23-S5`

- [ ] 不看 §4，建立 WebSocket 端点并成功握手
- [ ] 不看 §4，实现"连接时把 session 存进 Map"
- [ ] 不看 §4，实现向指定用户推送
- [ ] 完成 §4.5 的四步验证
- [ ] 回答：WebSocket 与 MQ 分别解决什么问题？

---

## 6. 故意制造错误 `Lv23-S6`

### `Lv23-E01` · 客户端连不上（路径不对）

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 客户端连 `/ws/notices`（多一个 s） |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充（浏览器控制台报什么？） |
| 状态 | ⬜ |

### `Lv23-E02` · 会话没清理

| 项 | 内容 |
| --- | --- |
| 破坏动作 | `afterConnectionClosed` 里不 `remove` |
| 预期现象 | 🚧 待补充（提示：Map 越来越大 → 内存泄漏；给已关闭会话发消息会抛异常） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 加上 `remove` |
| 状态 | ⬜ |

### `Lv23-E03` · 给已断开的会话发消息

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 客户端断开后，服务端仍对它 `sendMessage` |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充（异常类型？会不会影响其他推送？） |
| 恢复动作 | 发送前判断 `session.isOpen()`，并 try-catch |
| 状态 | ⬜ |

📌 **这个坑很关键**：一个用户的连接断了，不应导致给其他人推送也失败。

### `Lv23-E04` · 并发推送同一会话

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 多线程同时对同一个 session `sendMessage` |
| 预期现象 | 🚧 待补充（`IllegalStateException: TEXT_PARTIAL_WRITING`） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 对 session 加锁，或用 `ConcurrentWebSocketSessionDecorator` |
| 状态 | ⬜ |

### `Lv23-E05` · Security 拦住了握手

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 不把 `/ws/**` 加入 [Lv21](Lv21-SpringSecurity.md) 的白名单 |
| 预期现象 | 🚧 待补充（握手 401 / 403） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 加入白名单，并在握手里自己校验 Token |
| 状态 | ⬜ |

📌 **这是本关最可能先遇到的坑。**

### `Lv23-E06` · 没有心跳

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 不加心跳，模拟网络中断（拔网线 / 代理超时） |
| 预期现象 | 🚧 待补充（服务端以为连接还在，实际已经废了） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 加心跳 + 超时清理 |
| 状态 | ⬜ |

### `Lv23-E07` · 跨域被拒

| 项 | 内容 |
| --- | --- |
| 破坏动作 | `setAllowedOrigins` 限定为某个来源，用另一个来源连 |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 状态 | ⬜ |

### `Lv23-E08` · 多实例推送失败

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 启动两个实例，用户连 A，业务请求打到 B |
| 预期现象 | 🚧 待补充（**推不到**） |
| 实际现象 | 🚧 待补充 |
| 恢复方向 | Redis 发布订阅 / MQ 广播 |
| 状态 | ⬜ |

---

## 7. 解释原理 `Lv23-S7`

> 必须依次回答 [09 §4 的五个问题](../09-关卡教学与交付模板.md#4-每关必答的五个问题)。

1. **没有它会发生什么？** 🚧 待补充（用 §2 的 333 次/秒算账）
2. **它怎么解决的？** 🚧 待补充
3. **实验验证了什么？** 见 `Lv23-E01` ~ `Lv23-E08`
4. **一句话结论** 🚧 待补充
5. **架构哪一层变了？** 出现服务端推送通道（同步 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) 的 Lv23 行）

### 必须能答的问题

| 问题 | 答案 |
| --- | --- |
| HTTP 为什么不能让服务端主动开口？ | 🚧 待补充 |
| WebSocket 与 HTTP 是什么关系？ | 🚧 待补充（握手借用一次 HTTP，之后是独立协议） |
| WebSocket 与 MQ 是一回事吗？ | 🚧 待补充（一个面向浏览器，一个面向服务端） |
| 长连接带来哪些新问题？ | 🚧 待补充（用 §4.6 的六条） |
| Token 为什么这里要放 URL？与 `NFR-004` 冲突吗？ | 🚧 待补充（记录取舍理由） |

⚠️ 本节不得出现未在 §4~§6 出现过的新名词（`Docker` 留到 [Lv24](Lv24-Docker.md)）。

---

## 8. 小练习 `Lv23-S8`

### `Lv23-Q01` 加心跳

实现服务端定时 ping、客户端 pong，超时未响应则关闭会话。

### `Lv23-Q02` 未读消息补偿

设计一个方案：用户离线时的推送落库，用户上线后主动拉取未读。

### `Lv23-Q03` 与 MQ 组合

把推送链路改成"业务 → MQ → 消费者 → WebSocket 推送"，说明这样改的好处。

### `Lv23-Q04` 多实例方案

用 Redis 发布订阅实现两个实例之间的推送转发。

### `Lv23-Q05` 更新文档

把 Token 传递方式的取舍写进 [06 §5](../06-接口规范.md#5-认证约定) 与 [附录 A](../06-接口规范.md#附录-a--追加区)，并登记 `CHG-*`。

📌 答案写到本关「附录 A · 追加区」，**不要覆盖题目**。

---

## 9. 通关标准 `Lv23-S9`

> 全部勾选才算 ✅ 通关。勾选后到 [10-学习进度记录](../10-学习进度记录.md) 登记。

- [ ] `Lv23-A01` 能不看资料说清 HTTP 为什么做不到服务端主动推送
- [ ] `Lv23-A02` **能算清轮询的请求量差距**，并用数字说明（本关核心）
- [ ] `Lv23-A03` WebSocket 端点建立成功，能完成握手
- [ ] `Lv23-A04` 实现了"向指定用户推送"，并在客户端**实时收到**
- [ ] `Lv23-A05` 实现了会话清理（`afterConnectionClosed`）
- [ ] `Lv23-A06` 能说清 WebSocket 与 MQ 的区别
- [ ] `Lv23-A07` 能说出长连接带来的至少 4 个新问题
- [ ] `Lv23-A08` 完成了 `Lv23-E02`（内存泄漏）与 `Lv23-E05`（Security 拦截）
- [ ] `Lv23-A09` `Lv23-E01` ~ `Lv23-E08` 中至少完成五个
- [ ] `Lv23-A10` `Lv23-Q01` ~ `Lv23-Q05` 中至少完成两个
- [ ] `Lv23-A11` Token 传递方式的取舍已记录到文档
- [ ] `Lv23-A12` 依赖已登记到 [03 附录 A](../03-技术栈与选型.md#附录-a--追加区)
- [ ] `Lv23-A13` 代码是自己敲的，不是复制的
- [ ] `Lv23-A14` 本关新增内容已按 [00-维护规范](../00-文档使用与维护规范.md) 登记

---

## 10. 下一关 `Lv23-S10`

现在你的项目已经**很完整**了。

但它现在只存在于**你的这台电脑上**。

换一台电脑，你需要：
装 JDK 17、配 `JAVA_HOME`、装 Maven、装 MySQL 并建库、装 Redis、装 RabbitMQ……

而你的同事可能装的是 MySQL 5.7，或者 Redis 版本不一样，或者端口被占用。

**"在我机器上能跑"** 这句话，是后端最经典的问题。

还有一个更实际的场景：**你要把它部署到服务器上**。服务器上没有 IDEA，你也不该在上面手装一堆中间件。

下一关：**Docker**。

➡️ [`Lv24` · Docker](Lv24-Docker.md)

---

## 附录 A · 追加区

> 追加格式见 [00-维护规范 §3.3](../00-文档使用与维护规范.md)。已写入的条目不得删除。

### A.1 轮询账目（待学习者填写，用你自己项目的数字）

| 项 | 数值 |
| --- | --- |
| 假设在线人数 | 🚧 |
| 轮询间隔 | 🚧 |
| 每秒请求数 | 🚧 |
| 有效请求占比 | 🚧 |

### A.2 WebSocket 验证记录（待学习者填写）

| 步骤 | 结果 |
| --- | --- |
| 握手成功 | 🚧 |
| 收到推送 | 🚧 |
| 断开后清理 | 🚧 |
| 与 MQ 的组合方式 | 🚧 |

*（后续追加自此向下）*

## 附录 B · 踩坑记录 `Lv23-P0n`

| ID | 日期 | 现象 | 原因 | 解决 | 关联实验 |
| --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — |

## 附录 C · 勘误

*（暂无。格式见 [00-维护规范 §4.2](../00-文档使用与维护规范.md)。）*
