# Lv04 · 为什么需要 Service？

> **关卡编号**：`Lv04` ｜ **所属阶段**：第二阶段 · 真正进入 Spring
> **前置关卡**：`Lv03` 真正理解 HTTP（✅） ｜ **状态**：⬜ 未开始
> **对应需求**：`NFR-006`（分层边界） ｜ **对应接口**：`API-S-T0x` 系列 ｜ **对应数据表**：—
> **本关产物**：`Controller → Service` 两层结构成立，Controller 里只剩"接收 + 转交"

---

## 0. 本关速览

| 项目 | 内容 |
| --- | --- |
| 一句话目标 | 亲手写出一个"很垃圾的 Controller"，再用 Service 层把它拆开 |
| 核心知识点 | 分层、职责边界、构造器注入的雏形 |
| 预计耗时 | 🚧 待补充 |
| 难度（1~5） | 3 |
| 关键文件 | `controller/StudentController.java`、`service/StudentService.java` |
| 架构变化 | 从 1 层变 2 层（Controller → Service） |

---

## 1. 本关目标 `Lv04-S1`

1. 能写出一个"所有逻辑都在 Controller 里"的接口，并**说清它垃圾在哪**；
2. 能说出至少 4 条"Controller 里不该有的东西"；
3. 能把上面的代码重构成 `Controller → Service`，且接口行为不变；
4. 能画出本关结束时的两层结构图；
5. 能回答："如果一个 Controller 有 30 个接口，会怎样？"

📎 参考（`Consult.txt`）：

> 第 4 关：为什么需要 Service？
> 先故意写一个很垃圾的 Controller

---

## 2. 为什么学 `Lv04-S2`

先制造问题 —— 这是参考文档明确要求的做法。

### 2.1 先写一个"很垃圾的 Controller"

📎 参考（`Consult.txt` · 原文）：

> @RestController
> public class StudentController {
>
>     @GetMapping("/student/{id}")
>     public Student getStudent(@PathVariable Integer id) {
>
>         // 查询数据库
>         // 判断权限
>         // 业务处理
>         // 返回数据
>
>         return xxx;
>     }
> }

### 2.2 然后开始制造问题

📎 参考（`Consult.txt` · 原文）：

> 然后我们开始制造问题：
> 如果一个 Controller 有 30 个接口怎么办？

把问题列全：

| # | 问题 | 后果 |
| --- | --- | --- |
| 1 | 30 个接口 = 30 段"查询 + 判权 + 业务 + 返回" | 这个类几千行，谁都不敢改 |
| 2 | 两个接口需要同一段业务逻辑 | 复制粘贴，改一处忘一处 |
| 3 | 以后要加 Redis 缓存 | 得在 30 个地方各加一遍 |
| 4 | 以后要加 `@Transactional` | 事务边界无处安放（见 [Lv12](Lv12-事务.md)） |
| 5 | 想写单元测试 | 必须启动整个 Web 环境才能测一段业务逻辑 |
| 6 | 换个前端 / 加个定时任务也要用同一段逻辑 | 只能调 HTTP 接口，或再复制一遍 |

📌 结论先行：

> **Controller 只该做两件事：把 HTTP 请求翻译成方法调用，把结果翻译成 HTTP 响应。**
> 其余全部交给 Service。

---

## 3. 环境准备 `Lv04-S3`

| # | 项目 | 要求 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | Lv03 已通关 | 已有可跑的 `StudentController`（无数据库，返回假数据） | Postman 能调通 | ⬜ |
| 2 | 包结构 | 已能新建 `service` 包 | 见 [07-代码规范 §1](../07-代码规范与工程规范.md#1-工程结构与包结构) | ⬜ |

🚧 待补充：若 Lv03 未保留 `StudentController`，需先补回。

---

## 4. 手把手写代码 `Lv04-S4`

### 4.1 改造前（垃圾版）

```java
@RestController
public class StudentController {

    @GetMapping("/student/{id}")
    public String getStudent(@PathVariable Integer id) {
        // 查询数据库
        // 判断权限
        // 业务处理
        // 返回数据
        // 🚧 待补充：写出真实可运行版本（先用假数据，如 if (id == 1) return "张三";
    }
}
```

### 4.2 改造后

**目录结构**

```
src/main/java/com/campus
├── CampusApplication.java
├── controller
│   └── StudentController.java
└── service
    └── StudentService.java      ← 本关新增
```

**`service/StudentService.java`**

```java
@Service
public class StudentService {

    // 🚧 待补充：把 Controller 里的"查询 / 判权 / 业务"搬到这里
}
```

**`controller/StudentController.java`**

```java
@RestController
public class StudentController {

    private final StudentService studentService;

    public StudentController(StudentService studentService) {
        this.studentService = studentService;
    }

    @GetMapping("/student/{id}")
    public String getStudent(@PathVariable Integer id) {
        return studentService.getStudent(id);
    }
}
```

📎 参考（`Consult.txt` · 最终）：

> 最终：
> @RestController
> public class StudentController {
>
>     private final StudentService studentService;
>
>     public StudentController(StudentService studentService) {
>         this.studentService = studentService;
>     }
> }

### 4.3 运行与验证

🚧 待补充：改造前后接口返回**完全一致**，这是重构成功的判定标准。

⚠️ 本关结束时需要解决一个问题：`StudentService` 是谁创建、谁传进构造器的？
👉 **先别急着回答**。你会本能地想去 `new StudentService()`。那正是下一关要讲的事。

📌 本关的分层结构（原文）：

> Controller
>     ↓
> Service

---

## 5. 你自己敲 `Lv04-S5`

- [ ] 不看 §4，先自己写一版"垃圾 Controller"（3 个接口，逻辑全在里面）
- [ ] 数一数这个类有多少行，把行数记在附录 A
- [ ] 再自己重构出 `StudentService`，把行数变化也记下来
- [ ] 回答：`StudentService` 现在被创建了几次？

---

## 6. 故意制造错误 `Lv04-S6`

### `Lv04-E01` · Service 里写 HTTP 相关的东西

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 让 Service 方法返回 `Result<String>`，或让 Service 接收 `HttpServletRequest` |
| 预期现象 | 🚧 待补充（提示：编译能过吗？运行会怎样？） |
| 实际现象 | 🚧 待补充 |
| 原因 | 🚧 待补充（提示：业务层不该知道"HTTP 长什么样"） |
| 恢复动作 | Service 返回普通业务对象，由 Controller 包装 |
| 状态 | ⬜ |

### `Lv04-E02` · 手动 `new` 一个 Service

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把 `public StudentController(StudentService s)` 改成在方法里 `new StudentService()` |
| 预期现象 | 🚧 待补充（提示：这能跑吗？为什么？） |
| 实际现象 | 🚧 待补充 |
| 原因 | 🚧 待补充 |
| 状态 | ⬜ |

📌 `Lv04-E02` 是通向 Lv05 IOC 的桥。**做完这个实验，你就已经感觉到 Lv05 的问题了。**

### `Lv04-E03` · Controller 注入 Mapper

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 让 Controller 直接调用 Mapper（Lv07 之后回填本实验） |
| 预期现象 | 🚧 待补充 |
| 原因 | 🚧 待补充（违反 `NFR-006`，见 [04 §6](../04-系统架构与技术演进.md#6-边界与硬约定)） |
| 状态 | ⬜ 待 Lv07 后回填 |

---

## 7. 解释原理 `Lv04-S7`

> 必须依次回答 [09 §4 的五个问题](../09-关卡教学与交付模板.md#4-每关必答的五个问题)。

1. **没有它会发生什么？** 🚧 待补充（用 §2 的 6 条问题回答）
2. **它怎么解决的？** 🚧 待补充
3. **实验验证了什么？** 见 `Lv04-E01` ~ `Lv04-E02`
4. **一句话结论** 🚧 待补充
5. **架构哪一层变了？** 从 1 层变 2 层（同步 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) 的 Lv04 行）

### 分层职责表（本关必须记住）

| 层 | 只做 | 绝不做 |
| --- | --- | --- |
| Controller | 接收 HTTP、参数绑定、调用 Service、返回响应 | 业务判断、直接查库 |
| Service | 业务规则、编排、事务边界 | 感知 `HttpServletRequest`、返回 `Result` |

📌 完整版见 [04-系统架构 §2](../04-系统架构与技术演进.md#2-分层职责)，本关只记两行。

⚠️ 本节不得出现未在 §4~§6 出现过的新名词。（`@Service`、IOC、DI 等留到 Lv05/Lv06 讲，本关**不要**展开。）

---

## 8. 小练习 `Lv04-S8`

### `Lv04-Q01` 数行数

把改造前后的 `StudentController` 行数记下来，算出减少了多少。

### `Lv04-Q02` 复用逻辑

写两个接口（`GET /student/{id}` 与 `GET /student/{id}/detail`），让它们**共用同一个 Service 方法**的一部分逻辑。

### `Lv04-Q03` 反向验证

如果**只有一层**（不要 Service），实现"添加学生前检查是否重名"这个规则，然后在三个不同接口里都要用到它 —— 数一数你要写几遍。

📌 答案写到本关「附录 A · 追加区」，**不要覆盖题目**。

---

## 9. 通关标准 `Lv04-S9`

> 全部勾选才算 ✅ 通关。勾选后到 [10-学习进度记录](../10-学习进度记录.md) 登记。

- [ ] `Lv04-A01` 亲手写过一版"垃圾 Controller"，并能列出它至少 4 个问题
- [ ] `Lv04-A02` 能独立重构出 `Controller → Service`，且接口行为完全不变
- [ ] `Lv04-A03` 能不看资料画出两层结构图，并说清各层职责
- [ ] `Lv04-A04` `Lv04-E01`、`Lv04-E02` 已完成，且能解释 `E02` 的现象
- [ ] `Lv04-A05` `Lv04-Q01` ~ `Lv04-Q03` 已完成
- [ ] `Lv04-A06` 代码是自己敲的，不是复制的
- [ ] `Lv04-A07` 能说出"如果一个 Controller 有 30 个接口"的三个具体后果
- [ ] `Lv04-A08` 本关新增内容已按 [00-维护规范](../00-文档使用与维护规范.md) 登记

---

## 10. 下一关 `Lv04-S10`

你现在写出了这个：

```java
private final StudentService studentService;

public StudentController(StudentService studentService) {
    this.studentService = studentService;
}
```

但**没有人调用过这个构造器**。那 `studentService` 是谁给的？

如果你刚才在 `Lv04-E02` 里试过 `new StudentService()`，你大概已经发现：
自己 `new` 是能跑的 —— 但那不是这条路要你走的路。

下一关回答一个问题：**为什么 Controller 自己 `new` 不好？**

➡️ [`Lv05` · IOC](Lv05-IOC.md)

---

## 附录 A · 追加区

> 追加格式见 [00-维护规范 §3.3](../00-文档使用与维护规范.md)。已写入的条目不得删除。

### A.1 行数记录（待学习者填写）

| 版本 | 行数 | 日期 |
| --- | --- | --- |
| 垃圾版 `StudentController` | 🚧 待填 | — |
| 重构后 `StudentController` | 🚧 待填 | — |
| 重构后 `StudentService` | 🚧 待填 | — |

*（后续追加自此向下）*

## 附录 B · 踩坑记录 `Lv04-P0n`

| ID | 日期 | 现象 | 原因 | 解决 | 关联实验 |
| --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — |

## 附录 C · 勘误

*（暂无。格式见 [00-维护规范 §4.2](../00-文档使用与维护规范.md)。）*
