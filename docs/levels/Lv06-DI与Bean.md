# Lv06 · DI / Bean

> **关卡编号**：`Lv06` ｜ **所属阶段**：第二阶段 · 真正进入 Spring
> **前置关卡**：`Lv05` IOC（✅） ｜ **状态**：⬜ 未开始
> **对应需求**：`GL-004`（构造器注入） ｜ **对应接口**：无变化 ｜ **对应数据表**：—
> **本关产物**：理解 DI 的四种注解语义，并通过"删掉 `@Service` 会启动失败"真正理解 Bean

---

## 0. 本关速览

| 项目 | 内容 |
| --- | --- |
| 一句话目标 | 说清"依赖是怎么被塞进来的"，以及 Bean 到底是什么 |
| 核心知识点 | 依赖注入、构造器注入、`@Autowired`、`@Component`、`@Service`、`@Repository`、`@Controller`、`@RestController` |
| 预计耗时 | 🚧 待补充 |
| 难度（1~5） | 4 |
| 关键文件 | `controller/StudentController.java`、`service/StudentService.java` |
| 架构变化 | 层与层之间由容器连接，Bean 成为架构的基本单位 |

---

## 1. 本关目标 `Lv06-S1`

1. 能用自己的话说清 DI 与 IOC 的区别（一个管"谁创建"，一个管"怎么进去"）；
2. 能说清 `@Component` / `@Service` / `@Repository` / `@Controller` 的区别；
3. 能说清 `@Controller` 与 `@RestController` 的区别；
4. 能说出**字段注入、`setter` 注入、构造器注入**的区别，并说清本项目为什么统一用构造器注入（`GL-004`）；
5. 完成并解释核心实验：删掉 `@Service` → 启动失败 → 加回 → 成功；
6. 能回答：容器创建完 `StudentService` 后，是谁把它传给了 `StudentController` 的构造方法？

📎 参考（`Consult.txt`）：

> 第 6 关：DI
> 然后进一步研究：
> public StudentController(StudentService studentService)
> 为什么 Spring 能自动传进来？
> 这时候学习：
> 依赖注入
> 构造器注入
> @Autowired
> @Component
> @Service
> @Repository
> @Controller
> @RestController

---

## 2. 为什么学 `Lv06-S2`

Lv05 结束时，你写下了：

```java
public StudentController(StudentService studentService) {
    this.studentService = studentService;
}
```

**但没有任何一行代码调用过这个构造器。**

你既没有 `new StudentController(...)`，也没有给它赋值。那 `studentService` 是哪来的？

**这就是依赖注入要解释的事。**

先制造问题：假设没有 DI，你要自己写这段"装配代码"，它会是什么样？

```java
// 如果没有 DI，你得自己写（伪代码）
StudentMapper mapper = new StudentMapperImpl();
StudentService service = new StudentService(mapper);
StudentController controller = new StudentController(service);
// 而 service 又依赖 Redis、mapper 又依赖 DataSource……
```

📌 参考文档说得更直接：

> ② 让你自己发现问题
> Controller依赖Service
> Service依赖Mapper
> Mapper又依赖其他东西

**依赖会一层层长出去，最后装配代码本身变成一个无人敢动的大泥球。**
DI 做的事就是：这个装配过程，容器替你做了。

---

## 3. 环境准备 `Lv06-S3`

| # | 项目 | 要求 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | Lv05 已通关 | `@Service` 版本可正常启动 | Postman 可调通 | ⬜ |
| 2 | 会看启动失败日志 | 能定位 `Caused by` 根因 | 见 [07 §8](../07-代码规范与工程规范.md#8-测试与调试规范) | ⬜ |

---

## 4. 手把手写代码 `Lv06-S4`

### 4.1 三种注入方式（本关要亲手各写一遍）

**方式一：字段注入（不推荐，`GL-004` 禁止）**

```java
@RestController
public class StudentController {

    @Autowired
    private StudentService studentService;
}
```

**方式二：setter 注入**

```java
@RestController
public class StudentController {

    private StudentService studentService;

    @Autowired
    public void setStudentService(StudentService studentService) {
        this.studentService = studentService;
    }
}
```

**方式三：构造器注入（本项目统一使用，`GL-004`）**

```java
@RestController
public class StudentController {

    private final StudentService studentService;

    public StudentController(StudentService studentService) {
        this.studentService = studentService;
    }
}
```

📌 构造器注入的三个好处（本关必须自己说出来）：

| # | 好处 | 说明 |
| --- | --- | --- |
| 1 | 依赖不可变 | `final`，对象建好之后依赖不可能被换掉 |
| 2 | 依赖不能为空 | 少一个依赖，**编译期/启动期**就暴露，而不是运行到那行才 NPE |
| 3 | 依赖关系显式 | 看构造方法就知道这个类需要什么，不用翻遍字段找 `@Autowired` |

⚠️ 补充：Spring 4.3 之后，**类只有一个构造方法时可以省略 `@Autowired`**。这就是为什么我们的代码里没写 `@Autowired` 也能跑。这个现象要亲手验证一次。

### 4.2 四个注解（本关要写出来对比）

| 注解 | 语义 | 用在 |
| --- | --- | --- |
| `@Component` | 通用组件 | 说不清归哪一层的组件 |
| `@Service` | 业务层 | Service 实现类 |
| `@Repository` | 数据访问层 | 数据访问类 |
| `@Controller` | 控制层（返回视图） | 需要返回页面的 Controller |
| `@RestController` | `@Controller` + `@ResponseBody` | REST 接口（本项目用这个） |

📌 关键认识：**这四个在"让容器扫描到"这件事上作用相同**，区别在**语义**（以及 `@Repository` 会额外做异常转换）。

### 4.3 亲手验证"只有一个构造方法时可省略 `@Autowired`"

1. 先在构造方法上加 `@Autowired`，启动，确认能跑；
2. 删掉 `@Autowired`，启动，确认**还能跑**；
3. 记录结论。

🚧 待补充：实际观察结果。

---

## 5. 你自己敲 `Lv06-S5`

- [ ] 不看 §4，把三种注入方式各写一遍并都能启动成功
- [ ] 不看 §4，把 `@Service` 换成 `@Component`、`@Repository`，各启动一次，记录是否都能跑
- [ ] 亲手验证"省略 `@Autowired`"的现象
- [ ] 回答：容器创建了 `StudentService`，是谁把它传进 `StudentController` 的构造方法的？

---

## 6. 故意制造错误 `Lv06-S6`

📌 本关最重要的实验，**直接来自参考文档**。

### `Lv06-E01` · 删掉 `@Service`（核心实验）

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 删掉 `StudentService` 上的 `@Service`，保留构造器注入，**启动项目** |
| 预期现象 | 先自己写下预期 |
| 实际现象 | 🚧 待补充（**完整粘贴异常**，不要只写"报错了"） |
| 报错关键行 | 🚧 待补充（记录异常类名与 `Caused by`） |
| 原因 | 🚧 待补充 |
| 恢复动作 | 加回 `@Service` → 启动成功 |
| 状态 | ⬜ |

📎 参考（`Consult.txt` · 原文）：

> ④ 做实验
> 删掉@Service
> ↓
> 启动
> ↓
> 报错
> ↓
> 恢复
> ↓
> 启动成功

📌 **这个实验会让你真正理解：Bean 到底是什么。**

### `Lv06-E02` · 两个同类型 Bean

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 写两个都实现同一接口、都标了 `@Service` 的类，让 Controller 按接口注入 |
| 预期现象 | 🚧 待补充（提示：容器不知道该给哪个） |
| 实际现象 | 🚧 待补充 |
| 报错关键行 | 🚧 待补充 |
| 原因 | 🚧 待补充 |
| 恢复动作 | 用 `@Primary` 或 `@Qualifier("xxx")` 指定 |
| 状态 | ⬜ |

### `Lv06-E03` · 循环依赖

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 让 `AService` 构造器依赖 `BService`，`BService` 构造器依赖 `AService` |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 报错关键行 | 🚧 待补充 |
| 原因 | 🚧 待补充（提示：构造器注入无法解决循环依赖，字段注入在某些版本可以） |
| 状态 | ⬜ |

### `Lv06-E04` · Bean 不在扫描范围内

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把 `StudentService` 移到一个启动类扫描不到的包（如 `com.other`），保留 `@Service` |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 原因 | 🚧 待补充（提示：组件扫描的起点是启动类所在包） |
| 恢复动作 | 移回 `com.campus` 下 |
| 状态 | ⬜ |

---

## 7. 解释原理 `Lv06-S7`

> 必须依次回答 [09 §4 的五个问题](../09-关卡教学与交付模板.md#4-每关必答的五个问题)。

1. **没有它会发生什么？** 🚧 待补充（用 §2 的"装配代码"说明）
2. **它怎么解决的？** 🚧 待补充
3. **实验验证了什么？** 见 `Lv06-E01` ~ `Lv06-E04`
4. **一句话结论** 🚧 待补充
5. **架构哪一层变了？** 层与层通过容器连接（同步 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) 的 Lv06 行）

### 必须能给出的三个总结

📎 参考（`Consult.txt` · **最后才总结**）：

> ⑤ 最后才总结
> IOC = 对象创建和管理交给Spring
> DI = Spring把对象注入给需要它的对象
> Bean = Spring容器管理的对象

🚧 待补充：用**你自己的话**重写上面三句，并各配一个来自本关代码的例子。

| 概念 | 原文总结 | 我的重写 | 我的代码例子 |
| --- | --- | --- | --- |
| IOC | 对象创建和管理交给Spring | 🚧 | 🚧 |
| DI | Spring把对象注入给需要它的对象 | 🚧 | 🚧 |
| Bean | Spring容器管理的对象 | 🚧 | 🚧 |

### 必须回答的机制问题

| 问题 | 答案 |
| --- | --- |
| 是谁调用了 `StudentController` 的构造方法？ | 🚧 待补充 |
| 容器怎么知道要传 `StudentService`？ | 🚧 待补充（提示：按类型） |
| 为什么 `@Service` 删掉后启动就失败，而不是运行到那行才失败？ | 🚧 待补充 |
| `@Service` 和 `@Component` 在容器眼里有区别吗？ | 🚧 待补充（用 `Lv06-E01` 之外的自测结果回答） |

⚠️ 本节不得出现未在 §4~§6 出现过的新名词。

---

## 8. 小练习 `Lv06-S8`

### `Lv06-Q01` 三层链

写 `Controller → Service → Helper`（Helper 也用 `@Component`），验证三层都能被注入。

### `Lv06-Q02` 换注解

把 `@Service` 换成 `@Component`，再把 `@Repository` 也试一遍，记录哪些能跑、哪些不能，并解释。

### `Lv06-Q03` 用 `@Qualifier`

针对 `Lv06-E02` 的场景，分别用 `@Primary` 和 `@Qualifier` 解决一次，比较两种方式的差别。

### `Lv06-Q04` 依赖为空

把构造器注入改成字段注入但不加 `@Autowired`，启动并调用接口，观察报什么错（是 NPE 还是别的）。**这解释了为什么构造器注入更好。**

📌 答案写到本关「附录 A · 追加区」，**不要覆盖题目**。

---

## 9. 通关标准 `Lv06-S9`

> 全部勾选才算 ✅ 通关。勾选后到 [10-学习进度记录](../10-学习进度记录.md) 登记。

- [ ] `Lv06-A01` **核心实验 `Lv06-E01` 已完成**：真的看到删掉 `@Service` 后的启动失败，并能完整读出异常类名
- [ ] `Lv06-A02` 能不看资料说出 IOC / DI / Bean 的区别，并各举一个本项目里的例子
- [ ] `Lv06-A03` 能手写三种注入方式，并说清为什么本项目统一用构造器注入（`GL-004`）
- [ ] `Lv06-A04` 能说清 `@Component` / `@Service` / `@Repository` / `@Controller` / `@RestController` 的区别
- [ ] `Lv06-A05` 亲手验证过"只有一个构造方法时可省略 `@Autowired`"
- [ ] `Lv06-A06` `Lv06-E02` ~ `Lv06-E04` 中至少完成两个
- [ ] `Lv06-A07` `Lv06-Q01` ~ `Lv06-Q04` 已完成
- [ ] `Lv06-A08` 代码是自己敲的，不是复制的
- [ ] `Lv06-A09` 能不看资料回答："是谁把 `StudentService` 传进 Controller 构造方法的？"
- [ ] `Lv06-A10` 本关新增内容已按 [00-维护规范](../00-文档使用与维护规范.md) 登记

📌 `Lv06-A01` 是本关的核心，**参考文档明确要求这个实验必须做**。

---

## 10. 下一关 `Lv06-S10`

现在你的 Service 里返回的还是**假数据**。整个链路只到 Service 就断了。

真实系统里，数据要从数据库来。而在 Java 里访问数据库，最原始的写法是这样的：

```java
Connection conn = DriverManager.getConnection(url, user, pwd);
PreparedStatement ps = conn.prepareStatement("SELECT * FROM student WHERE id = ?");
ps.setInt(1, id);
ResultSet rs = ps.executeQuery();
// 然后手工把 rs 的每一列取出来，set 进 Student 对象...
```

而且这段代码要在每个查询里重复一遍。

下一关：把这些重复代码拿掉，引入 **Mapper 层**。

➡️ [`Lv07` · 引入 MyBatis](Lv07-引入MyBatis.md)

---

## 附录 A · 追加区

> 追加格式见 [00-维护规范 §3.3](../00-文档使用与维护规范.md)。已写入的条目不得删除。

### A.1 核心实验记录 `Lv06-E01`（待学习者填写）

| 观察项 | 记录 |
| --- | --- |
| 异常类名 | 🚧 待填 |
| `Caused by` 根因 | 🚧 待填 |
| 恢复后启动耗时变化 | 🚧 待填 |

*（后续追加自此向下）*

## 附录 B · 踩坑记录 `Lv06-P0n`

| ID | 日期 | 现象 | 原因 | 解决 | 关联实验 |
| --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — |

## 附录 C · 勘误

*（暂无。格式见 [00-维护规范 §4.2](../00-文档使用与维护规范.md)。）*
