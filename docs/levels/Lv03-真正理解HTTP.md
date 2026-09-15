# Lv03 · 真正理解 HTTP

> **关卡编号**：`Lv03` ｜ **所属阶段**：第一阶段 · 先让 Spring Boot 不再神秘
> **前置关卡**：`Lv02` 写第一个 Controller（✅） ｜ **状态**：⬜ 未开始
> **对应需求**：—（教学关，产出 `API-S-T02`、`API-S-T03`） ｜ **对应接口**：`API-S-T02`、`API-S-T03` ｜ **对应数据表**：—
> **本关产物**：路径参数、查询参数、请求体三种传参方式全部跑通

---

## 0. 本关速览

| 项目 | 内容 |
| --- | --- |
| 一句话目标 | 搞懂 HTTP 方法与三类传参，并能把它们映射到 Java 方法参数上 |
| 核心知识点 | `GET`/`POST`/`PUT`/`DELETE`、`@PathVariable`、`@RequestParam`、`@RequestBody`、JSON ↔ Java 对象 |
| 预计耗时 | 🚧 待补充 |
| 难度（1~5） | 3 |
| 关键文件 | `controller/HelloController.java`（或新建 `StudentController.java`） |
| 架构变化 | Controller 具备完整出入参能力，出现 **DTO 雏形** |

📌 参考文档对本关的评价（**原文**）：

> 第 3 关：真正理解 HTTP
> 这一关非常重要。

---

## 1. 本关目标 `Lv03-S1`

1. 能说清 `GET` / `POST` / `PUT` / `DELETE` 的语义差别，以及"为什么不能全用 GET"；
2. 能说出 `GET /student/1` 和 `POST /student` 的本质区别；
3. 能用 `@PathVariable` 接收路径参数、`@RequestParam` 接收查询参数、`@RequestBody` 接收 JSON 请求体；
4. 能用自己的话解释 **JSON → Java 对象** 这个过程；
5. 能用 Postman 分别发出这四类请求，并解释每个请求的 `Body` / `Params` 各填在哪。

📎 参考（`Consult.txt`）：

> 第 3 关：真正理解 HTTP
> 这一关非常重要。
> 我们不急着学 Spring。
> 直接研究：
> GET
> POST
> PUT
> DELETE
> 然后：
> GET /student/1
> 和：
> POST /student
> 有什么区别。
> 再学：
> PathVariable
> RequestParam
> RequestBody

---

## 2. 为什么学 `Lv03-S2`

先制造问题。

Lv02 的接口是这样的：

```java
@GetMapping("/hello")
public String hello() { return "Hello Spring Boot"; }
```

**问题一：不同的人要看到不同的数据。**
`/student/1` 和 `/student/1001` 是两个不同的学生，但 URL 里只有一个地方是变的 —— 你怎么把这个 `1` 拿到方法里？

**问题二：新增和查询是两件完全不同的事，但 URL 长得一样。**
`/student` 既可以"查列表"，也可以"新增一个"。如果只靠 URL，你分不清。
（这就是为什么需要 HTTP 方法 —— 它表达的是**对资源的操作意图**。）

**问题三：前端传过来的是一段 JSON 文本，不是一个 Java 对象。**
```json
{ "name": "张三", "age": 20, "gender": "M", "className": "计科2101" }
```
这段文本怎么变成 `Student` 对象？

📌 本关要记住的核心判断：

> **URL 说明"操作哪个资源"，HTTP 方法说明"做什么操作"，请求体携带"怎么做"。**

---

## 3. 环境准备 `Lv03-S3`

| # | 项目 | 要求 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | Lv02 已通关 | `/hello` 可访问 | 浏览器返回 `Hello Spring Boot` | ⬜ |
| 2 | Postman | 能切换 GET/POST/PUT/DELETE | 能新建请求并选方法 | ⬜ |
| 3 | Postman | 能设置 `Body → raw → JSON` | 能发出带 JSON 体的请求 | ⬜ |

---

## 4. 手把手写代码 `Lv03-S4`

### 4.1 路径参数 `@PathVariable`

```java
@GetMapping("/student/{id}")
public String getStudent(@PathVariable Integer id) {
    return "学生：" + id;
}
```

📎 参考（`Consult.txt`）：

> 例如：
> @GetMapping("/student/{id}")
> public String getStudent(@PathVariable Integer id) {
>     return "学生：" + id;
> }
> 然后：
> /student/1001
> ↓
> id = 1001

**验证**

```
GET http://localhost:8080/student/1001
→ 学生：1001

GET http://localhost:8080/student/1
→ 学生：1
```

⚠️ 关键观察：URL 里 `{id}` 这个名字，和 `@PathVariable Integer id` 的**参数名**必须一致。
如果写 `@PathVariable("id") Integer sid`，就是用注解显式指定名字。

### 4.2 请求体 `@RequestBody`

先准备一个接收对象（这是本关的 DTO 雏形）：

```java
package com.campus.dto;

public class Student {
    private Integer id;
    private String name;
    private Integer age;
    private String gender;
    private String className;

    // 🚧 待补充：getter / setter（或用 Lombok @Data）
}
```

```java
@PostMapping("/student")
public String addStudent(@RequestBody Student student) {
    return "添加成功";
}
```

📎 参考（`Consult.txt`）：

> 再学习：
> @PostMapping("/student")
> public String addStudent(@RequestBody Student student) {
>     return "添加成功";
> }
> 你会真正理解：
> JSON
>  ↓
> Java对象
> 这个过程。

**验证**

```
POST http://localhost:8080/student
Content-Type: application/json

{ "name": "张三", "age": 20, "gender": "M", "className": "计科2101" }

→ 添加成功
```

📌 **本关必须做的动作**：在 `addStudent` 方法里打断点或加一行打印，**亲眼看到 `student` 对象里真的有值**。
只看到 `添加成功` 三个字，等于没学这一关。

### 4.3 查询参数 `@RequestParam`

```java
// 🚧 待补充：Consult.txt 未给出示例，由学习者按同一思路补全
// 提示：GET /student?page=1&pageSize=10
```

### 4.4 四种 HTTP 方法的对照实践

| 方法 | 语义 | 本关要写的接口 | 参数位置 |
| --- | --- | --- | --- |
| `GET` | 查询 | `GET /student/{id}` | 路径 |
| `GET` | 查询（带条件） | `GET /student?page=1` | 查询串 |
| `POST` | 新增 | `POST /student` | 请求体 |
| `PUT` | 修改 | 🚧 待补充 | 路径 + 请求体 |
| `DELETE` | 删除 | 🚧 待补充 | 路径 |

---

## 5. 你自己敲 `Lv03-S5`

关掉 §4 重建一遍。

- [ ] 不看 §4，写出 `GET /student/{id}` 并跑通 `/student/1001`
- [ ] 不看 §4，写出 `POST /student` + `@RequestBody`，并在方法里打印出 `student.getName()`
- [ ] 自己补出 `PUT` 与 `DELETE` 两个接口
- [ ] 说清楚：`@PathVariable` 和 `@RequestParam` 取值的位置分别在哪一段 URL 上

---

## 6. 故意制造错误 `Lv03-S6`

📌 本关最重要的部分。**必须真的看到报错。**

### `Lv03-E01` · `{id}` 与参数名不一致

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把 `@GetMapping("/student/{id}")` 改成 `/student/{sid}`，但方法参数仍写 `@PathVariable Integer id` |
| 预期现象 | 🚧 待补充（提示：是启动期报错还是访问时报错？） |
| 实际现象 | 🚧 待补充 |
| 报错关键行 | 🚧 待补充 |
| 原因 | 🚧 待补充 |
| 恢复动作 | 名字改回一致，或写 `@PathVariable("sid")` |
| 状态 | ⬜ |

### `Lv03-E02` · 路径参数传非数字

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 访问 `/student/abc`（`id` 声明为 `Integer`） |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 报错关键行 | 🚧 待补充 |
| 原因 | 🚧 待补充（提示：类型转换失败） |
| 恢复动作 | 访问 `/student/1` |
| 状态 | ⬜ |

### `Lv03-E03` · `POST` 请求不带 `Content-Type`

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 在 Postman 里把 `Content-Type` 去掉（或选 `text/plain`）发 JSON |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 报错关键行 | 🚧 待补充 |
| 原因 | 🚧 待补充 |
| 恢复动作 | 设回 `application/json` |
| 状态 | ⬜ |

### `Lv03-E04` · 用 `GET` 发 `POST` 的请求

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 用 `GET /student` 但带上 JSON 请求体 |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 原因 | 🚧 待补充（提示：GET 的语义与 body 的关系） |
| 状态 | ⬜ |

---

## 7. 解释原理 `Lv03-S7`

> 必须依次回答 [09 §4 的五个问题](../09-关卡教学与交付模板.md#4-每关必答的五个问题)。

1. **没有它会发生什么？** 🚧 待补充（见 §2 的三个问题）
2. **它怎么解决的？** 🚧 待补充
3. **实验验证了什么？** 见 `Lv03-E01` ~ `Lv03-E04`
4. **一句话结论** 🚧 待补充
5. **架构哪一层变了？** Controller 具备完整出入参能力（同步 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) 的 Lv03 行）

### 必须能答的问题

| 问题 | 答案 |
| --- | --- |
| `GET /student/1` 和 `POST /student` 有什么区别？ | 🚧 待补充 |
| HTTP 方法在这里到底起到了什么作用？ | 🚧 待补充 |
| JSON 是怎么变成 `Student` 对象的？谁做的？ | 🚧 待补充 |
| 为什么 `@RequestBody` 只能有一个？ | 🚧 待补充（提示：一个请求体） |
| `@PathVariable` / `@RequestParam` / `@RequestBody` 三者取值位置 | 🚧 待补充 |

### JSON → Java 对象的完整链路

```
前端发出：
{ "name": "张三", "age": 20, ... }
        ↓  HTTP Body (application/json)
Spring MVC 的 HttpMessageConverter
        ↓  按字段名匹配
new Student() + setName("张三") + setAge(20) ...
        ↓
addStudent(Student student)   ← 你在这里拿到有值的对象
```

🚧 待补充：把你实际打断点看到的对象值记在这里。

⚠️ 本节不得出现未在 §4~§6 出现过的新名词。

---

## 8. 小练习 `Lv03-S8`

### `Lv03-Q01` 多路径参数

实现 `GET /student/{id}/score/{courseId}`，返回两个参数拼接的结果。

### `Lv03-Q02` 默认值

给 `@RequestParam` 加 `defaultValue`，让 `GET /student` 不传 `page` 时默认 `page = 1`。

### `Lv03-Q03` 可选参数

让 `@RequestParam` 变成可选（`required = false`），观察不传时的值是什么。

### `Lv03-Q04` 四方法全写

把 `Student` 的 `GET`（列表 + 单个）、`POST`、`PUT`、`DELETE` 五个接口全部写出来 —— 这就是 Lv09 的雏形，只是此刻还没有数据库。

📌 答案写到本关「附录 A · 追加区」，**不要覆盖题目**。

---

## 9. 通关标准 `Lv03-S9`

> 全部勾选才算 ✅ 通关。勾选后到 [10-学习进度记录](../10-学习进度记录.md) 登记。

- [ ] `Lv03-A01` `@PathVariable` / `@RequestParam` / `@RequestBody` 三种传参都能独立写出并跑通
- [ ] `Lv03-A02` 能在方法里**看到** `@RequestBody` 反序列化后对象里的真实值（不是只看到"添加成功"）
- [ ] `Lv03-A03` 能不看资料说清 `GET /student/1` 与 `POST /student` 的区别
- [ ] `Lv03-A04` `Lv03-E01` ~ `Lv03-E04` 中至少完成三个，且都真的看到了报错
- [ ] `Lv03-A05` `Lv03-Q01` ~ `Lv03-Q04` 已完成
- [ ] `Lv03-A06` 代码是自己敲的，不是复制的
- [ ] `Lv03-A07` 已在 Postman 中建立 `API-S-T02`、`API-S-T03` 并跑通
- [ ] `Lv03-A08` 能说出 HTTP 方法各自对应 [06-接口规范 §6](../06-接口规范.md#6-接口清单) 中哪些 `API-*`
- [ ] `Lv03-A09` 本关新增内容已按 [00-维护规范](../00-文档使用与维护规范.md) 登记

📌 `Lv03-A02` 是本关核心验收项，**不允许跳过**。

---

## 10. 下一关 `Lv03-S10`

现在你有了 5 个接口，而且它们的参数处理、返回值拼装、甚至"该返回什么"的判断，全都挤在 `HelloController` / `StudentController` 这**一个类**里。

**如果一个 Controller 有 30 个接口怎么办？**

下一关我们会**故意先写一个很垃圾的 Controller**，然后让问题自己暴露出来。

➡️ [`Lv04` · 为什么需要 Service](Lv04-为什么需要Service.md)

---

## 附录 A · 追加区

> 追加格式见 [00-维护规范 §3.3](../00-文档使用与维护规范.md)。已写入的条目不得删除。

*（暂无）*

## 附录 B · 踩坑记录 `Lv03-P0n`

| ID | 日期 | 现象 | 原因 | 解决 | 关联实验 |
| --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — |

## 附录 C · 勘误

*（暂无。格式见 [00-维护规范 §4.2](../00-文档使用与维护规范.md)。）*
