# Lv02 · 写第一个 Controller

> **关卡编号**：`Lv02` ｜ **所属阶段**：第一阶段 · 先让 Spring Boot 不再神秘
> **前置关卡**：`Lv01` 让 Spring Boot 跑起来（✅） ｜ **状态**：⬜ 未开始
> **对应需求**：—（教学关，产出 `API-S-T01`） ｜ **对应接口**：`API-S-T01` ｜ **对应数据表**：—
> **本关产物**：`GET /hello` 能在浏览器返回 `Hello Spring Boot`

---

## 0. 本关速览

| 项目 | 内容 |
| --- | --- |
| 一句话目标 | 写出第一个 REST 接口，并亲眼看到"Java 方法变成 HTTP 接口" |
| 核心知识点 | `@RestController`、`@GetMapping`、URL 与方法映射 |
| 预计耗时 | 🚧 待补充 |
| 难度（1~5） | 1 |
| 关键文件 | `controller/HelloController.java` |
| 架构变化 | 出现 **Controller 层**（此前只有启动类） |

---

## 1. 本关目标 `Lv02-S1`

1. 能写出一个返回字符串的 `GET` 接口，并在浏览器访问成功；
2. 能说清 `@RestController` 与 `@GetMapping` 各自做了什么；
3. 能通过**改注解的值**，让同一个 Java 方法对应不同的 URL；
4. 能解释"404"与"接口不存在"和"服务没起来"的区别。

📎 参考（`Consult.txt`）：

> 第 2 关：写第一个 Controller
> 目标：
> 浏览器
>  ↓
> GET /hello
>  ↓
> Controller
>  ↓
> 返回 Hello Spring Boot

---

## 2. 为什么学 `Lv02-S2`

Lv01 结束时，你的项目能启动，但浏览器访问 `http://localhost:8080` 只能看到 `Whitelabel Error Page`。

**问题**：Tomcat 收到了请求，但它不知道该把这个请求交给谁。

在 Spring MVC 没出现之前，你要写 `Servlet`、在 `web.xml` 里配置 `<url-pattern>`、手工从 `HttpServletRequest` 里读参数、手工往 `HttpServletResponse` 里写内容：

```java
// Lv02 之前的世界（你不用写，但要知道它存在）
public class HelloServlet extends HttpServlet {
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
        resp.getWriter().write("Hello Spring Boot");
    }
}
```

**Controller 解决的就是这件事**：用一个普通 Java 方法响应一个 URL，其余的交给你不用管的框架。

📌 本关真正的教学点不是"会写 Controller"，而是：

> **Java 方法是怎么变成 HTTP 接口的。**

📎 参考（`Consult.txt` · 核心设计意图）：

> 然后我们故意修改：
> @GetMapping("/hello")
> ↓
> @GetMapping("/student")
> 让你亲眼看到：
> Java 方法是怎么变成 HTTP 接口的。

---

## 3. 环境准备 `Lv02-S3`

| # | 项目 | 要求 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | Lv01 已通关 | 项目可启动 | 启动日志有 `Tomcat started on port(s): 8080` | ⬜ |
| 2 | 浏览器或 Postman | 能发 GET 请求 | 能打开 `http://localhost:8080` | ⬜ |
| 3 | Postman 集合 | 已建 `campus-api` | 见 [06-接口规范 §8](../06-接口规范.md#8-postman-集合约定) | ⬜ |

📌 公共前置见 [03-技术栈 §4](../03-技术栈与选型.md#4-环境准备清单)。

---

## 4. 手把手写代码 `Lv02-S4`

### 4.1 最终目录结构

```
src/main/java/com/campus
├── CampusApplication.java
└── controller
    └── HelloController.java        ← 本关新增
```

📌 `controller` 包此刻正式加入包结构，见 [07-代码规范 §1](../07-代码规范与工程规范.md#1-工程结构与包结构)。

### 4.2 完整代码

**`src/main/java/com/campus/controller/HelloController.java`**

```java
package com.campus.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/hello")
    public String hello() {
        return "Hello Spring Boot";
    }
}
```

📎 参考（`Consult.txt` · 你会写）：

> @RestController
> public class HelloController {
>
>     @GetMapping("/hello")
>     public String hello() {
>         return "Hello Spring Boot";
>     }
> }

### 4.3 运行与验证

```
浏览器访问：http://localhost:8080/hello
预期响应：Hello Spring Boot
```

⚠️ 注意区分：
- 访问 `/hello` 返回字符串 → ✅ 成功
- 访问 `/helloworld` 返回 404 JSON → 服务正常，但这个 URL 没有对应的映射
- 访问 `http://localhost:8080` 连不上 → 服务没启动（回到 Lv01）

---

## 5. 你自己敲 `Lv02-S5`

关掉 §4，从空文件重建一遍。

- [ ] 不看 §4，新建 `HelloController` 并写出 `GET /hello`
- [ ] 不看 §4，自己加一个 `GET /ping` 返回 `pong`，验证可访问
- [ ] 说清楚：`@RestController` 加在类上、`@GetMapping` 加在方法上，这个位置能不能互换？为什么？

---

## 6. 故意制造错误 `Lv02-S6`

📌 本关最重要的实验，直接来自参考文档。

### `Lv02-E01` · 把 `/hello` 改成 `/student`

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把 `@GetMapping("/hello")` 改成 `@GetMapping("/student")`，**重启** |
| 预期现象 | 先自己写下预期：`/hello` 会怎样？`/student` 会怎样？ |
| 实际现象 | 🚧 待补充（做完填） |
| 报错 / 状态码 | 🚧 待补充 |
| 原因 | 🚧 待补充 |
| 恢复动作 | 改回 `/hello`，重启成功 |
| 状态 | ⬜ |

📎 参考（`Consult.txt`）：

> 然后我们故意修改：
> @GetMapping("/hello")
> ↓
> @GetMapping("/student")
> 让你亲眼看到：
> Java 方法是怎么变成 HTTP 接口的。

### `Lv02-E02` · 不重启就改 URL

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 改完注解后**不重启**，直接刷新浏览器 |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 原因 | 🚧 待补充（关联：热部署 / devtools） |
| 状态 | ⬜ |

### `Lv02-E03` · 两个方法映射到同一个 URL

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 再写一个方法，也用 `@GetMapping("/hello")` |
| 预期现象 | 🚧 待补充（提示：这是启动期错误还是运行期错误？） |
| 实际现象 | 🚧 待补充 |
| 报错关键行 | 🚧 待补充 |
| 原因 | 🚧 待补充 |
| 恢复动作 | 改回不同 URL |
| 状态 | ⬜ |

---

## 7. 解释原理 `Lv02-S7`

> 必须依次回答 [09 §4 的五个问题](../09-关卡教学与交付模板.md#4-每关必答的五个问题)。

1. **没有它会发生什么？** 🚧 待补充（提示：见 §2 的 Servlet 写法）
2. **它怎么解决的？** 🚧 待补充（提示：组件扫描找到类 → 读注解建立"URL → 方法"映射表 → 请求进来查表）
3. **实验验证了什么？** 见 `Lv02-E01`、`Lv02-E02`、`Lv02-E03`
4. **一句话结论** 🚧 待补充
5. **架构哪一层变了？** Controller 层出现（同步 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) 的 Lv02 行）

### 关键问题（必须能答）

| 问题 | 答案 |
| --- | --- |
| `@RestController` 做了什么？ | 🚧 待补充 |
| `@GetMapping` 做了什么？ | 🚧 待补充 |
| 返回的 `String` 为什么直接变成了响应体，而不是一个页面名？ | 🚧 待补充 |
| 启动时 Spring 是什么时候知道 `/hello` 存在的？ | 🚧 待补充 |

⚠️ 本节不得出现未在 §4~§6 出现过的新名词。

---

## 8. 小练习 `Lv02-S8`

### `Lv02-Q01` 三个接口

写出 `GET /hello`、`GET /ping`、`GET /version` 三个接口，分别返回不同内容。

### `Lv02-Q02` 返回非字符串

把 `hello()` 的返回类型改成 `int`，返回 `200`，观察响应内容与 `Content-Type` 有什么变化。

### `Lv02-Q03` 类上再映射

在 `HelloController` 类上加 `@RequestMapping("/api")`，观察所有方法路径发生了什么变化，并说明原因。

📌 答案写到本关「附录 A · 追加区」，**不要覆盖题目**。

---

## 9. 通关标准 `Lv02-S9`

> 全部勾选才算 ✅ 通关。勾选后到 [10-学习进度记录](../10-学习进度记录.md) 登记。

- [ ] `Lv02-A01` 能不看资料写出 `GET /hello` 并跑通
- [ ] `Lv02-A02` `Lv02-E01` 已做：**真的看到**改 URL 前后 `/hello` 与 `/student` 的行为差异
- [ ] `Lv02-A03` 能不看资料解释 `@RestController` 与 `@GetMapping` 各自的作用
- [ ] `Lv02-A04` 能说清"404 是服务正常但没这个接口"与"连不上是服务没起来"
- [ ] `Lv02-A05` `Lv02-Q01` ~ `Lv02-Q03` 已完成
- [ ] `Lv02-A06` 代码是自己敲的，不是复制的
- [ ] `Lv02-A07` 已在 Postman 中把 `API-S-T01` 建好并跑通
- [ ] `Lv02-A08` 本关新增内容已按 [00-维护规范](../00-文档使用与维护规范.md) 登记

📌 其中 `Lv02-A02` 是本关的核心验收项，**不允许跳过**。

---

## 10. 下一关 `Lv02-S10`

你现在会写接口了，但只会"用一个 URL 返回一句写死的话"。

真实系统里：`/student/1` 和 `/student/1001` 应该返回不同数据；`GET` 和 `POST` 做的是完全不同的事；前端传过来的是 JSON，不是一个字符串。

下一关我们不学 Spring，**先真正搞懂 HTTP**。

➡️ [`Lv03` · 真正理解 HTTP](Lv03-真正理解HTTP.md)

---

## 附录 A · 追加区

> 追加格式见 [00-维护规范 §3.3](../00-文档使用与维护规范.md)。已写入的条目不得删除。

*（暂无）*

## 附录 B · 踩坑记录 `Lv02-P0n`

| ID | 日期 | 现象 | 原因 | 解决 | 关联实验 |
| --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — |

## 附录 C · 勘误

*（暂无。格式见 [00-维护规范 §4.2](../00-文档使用与维护规范.md)。）*
