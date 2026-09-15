# Lv05 · IOC

> **关卡编号**：`Lv05` ｜ **所属阶段**：第二阶段 · 真正进入 Spring
> **前置关卡**：`Lv04` 为什么需要 Service（✅） ｜ **状态**：⬜ 未开始
> **对应需求**：—（机制关） ｜ **对应接口**：无变化 ｜ **对应数据表**：—
> **本关产物**：`StudentService` 由 Spring 容器创建与管理，Controller 不再自己 `new`

---

## 0. 本关速览

| 项目 | 内容 |
| --- | --- |
| 一句话目标 | 亲手把"自己 new 对象"改成"Spring 容器管对象"，并说清 IOC 到底反转了什么 |
| 核心知识点 | IOC（控制反转）、Spring 容器、Bean、`@Service` |
| 预计耗时 | 🚧 待补充 |
| 难度（1~5） | 4 |
| 关键文件 | `service/StudentService.java`、`controller/StudentController.java` |
| 架构变化 | 对象创建权从业务代码转移到容器 |

📌 参考文档指明本关的教法（**原文**）：

> 第 5 关：IOC
> 这一关不背定义。
> 我们先写：
> StudentService service = new StudentService();
> 然后问：
> 为什么 Controller 自己 new 不好？

---

## 1. 本关目标 `Lv05-S1`

1. 能写出 `new StudentService()` 的版本，并说出它至少 3 个坏处；
2. 能把它改成由容器管理的版本（`@Service` + 构造器接收），且接口行为不变；
3. 能用**自己的话**说清"控制反转"里到底什么被反转了；
4. 能说清 Spring 容器是什么、Bean 是什么（**用现象描述，不背定义**）；
5. 能回答：容器是什么时候创建 `StudentService` 的？

📎 参考（`Consult.txt` · 本关最终理解）：

> 最终理解：
> 以前：
> Controller
>    ↓
> new StudentService()
>    ↓
> 自己管理对象
>
> Spring：
> Spring容器
>    ↓
> 创建 StudentService
>    ↓
> 管理 StudentService
>    ↓
> 交给 Controller
> 这就是 IOC。

---

## 2. 为什么学 `Lv05-S2`

### 2.1 先制造问题

📎 参考（`Consult.txt`）：

> 我们先写：
> StudentService service = new StudentService();
> 然后问：
> 为什么 Controller 自己 new 不好？

**亲手写下这个版本：**

```java
@RestController
public class StudentController {

    // 自己在字段上直接 new
    private StudentService studentService = new StudentService();

    @GetMapping("/student/{id}")
    public String getStudent(@PathVariable Integer id) {
        return studentService.getStudent(id);
    }
}
```

### 2.2 它到底哪里不好？

| # | 问题 | 具体后果 |
| --- | --- | --- |
| 1 | **依赖写死** | `StudentService` 想换成 `StudentServiceImplV2`，得改所有 `new` 的地方 |
| 2 | **无法统一管理生命周期** | 每个 `new` 出来一个独立对象；如果 Service 里持有资源（连接、客户端），就泄漏了 |
| 3 | **无法替换实现** | 想 mock 一个假 Service 做测试，做不到（除非改源码） |
| 4 | **依赖链条会失控** | 你 `new` Service，Service 里又 `new` Mapper，Mapper 里又 `new` 别的…… 最后没人说得清谁依赖谁 |
| 5 | **横切功能无处插入** | 想让 Service 自动带事务（Lv12）或日志（Lv18），手写 `new` 出来的对象加不进去 |

📎 参考（`Consult.txt` · 制造问题的方向）：

> 如果一个 Controller 有 30 个接口怎么办？

📌 到了 Lv12 你会看到最狠的一条：**自己 `new` 出来的对象，`@Transactional` 根本不生效。**
到那时你才会真正明白第 5 条的分量。

### 2.3 那怎么办？

> 把"创建对象"和"管理对象"这件事，**从业务代码里拿出去，交给一个统一的容器**。

这就是 **IOC（Inversion of Control，控制反转）**。

---

## 3. 环境准备 `Lv05-S3`

| # | 项目 | 要求 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | Lv04 已通关 | 已有 `Controller → Service` 两层结构 | Postman 可调通 | ⬜ |
| 2 | 能改启动日志观察级别 | 看得清启动过程 | 启动日志可见 | ⬜ |

---

## 4. 手把手写代码 `Lv05-S4`

### 4.1 改造前

```java
public class StudentService {          // 注意：没有任何注解
    public String getStudent(Integer id) { ... }
}

@RestController
public class StudentController {
    private StudentService studentService = new StudentService();   // 自己 new
}
```

### 4.2 改造后

**`service/StudentService.java`**

```java
@Service
public class StudentService {
    // 🚧 待补充：方法体沿用 Lv04 的实现
}
```

📎 参考（`Consult.txt`）：

> 然后让 Spring 接管：
> @Service
> public class StudentService {
> }

**`controller/StudentController.java`**

```java
@RestController
public class StudentController {

    private final StudentService studentService;

    public StudentController(StudentService studentService) {   // 不是 new，是"接收"
        this.studentService = studentService;
    }
}
```

### 4.3 运行与验证

1. 启动项目，接口行为**必须与改造前完全一致**；
2. 在 `StudentService` 的构造方法里加一行日志：

```java
public StudentService() {
    System.out.println("StudentService 被创建了！");   // Lv07 前允许，之后改用 log
}
```

   观察：**这行日志什么时候打印？打印几次？**

🚧 待补充：把实际观察结果记在这里（打印时机 = 项目启动时，不是每次请求；次数 = 1 次）。

📌 这个观察结论非常重要，它直接说明：**对象是容器在启动时创建的，不是每次请求创建的。**

### 4.4 结构对照

📎 参考（`Consult.txt`）：

> 以前：
> Controller ↓ new StudentService() ↓ 自己管理对象
>
> Spring：
> Spring容器 ↓ 创建 StudentService ↓ 管理 StudentService ↓ 交给 Controller

🚧 待补充：把这两张图画到本关「附录 A」，用自己的话标注。

---

## 5. 你自己敲 `Lv05-S5`

- [ ] 不看 §4，先把 Lv04 的版本改回"自己 `new`"，确认能跑
- [ ] 再不看 §4，改成 `@Service` + 构造器接收，确认能跑
- [ ] 在 Service 的构造方法里加日志，记录**创建时机与次数**
- [ ] 回答：改造后，`new StudentService()` 这行代码去哪了？（提示：它没消失，只是不在你手里了）

---

## 6. 故意制造错误 `Lv05-S6`

### `Lv05-E01` · 把 `@Service` 删掉

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 删掉 `StudentService` 上的 `@Service`，**保留** Controller 的构造器注入，启动 |
| 预期现象 | 🚧 待补充（先写预期） |
| 实际现象 | 🚧 待补充 |
| 报错关键行 | 🚧 待补充（记录完整异常类名） |
| 原因 | 🚧 待补充（提示：容器里没有这个 Bean，但有人要它） |
| 恢复动作 | 加回 `@Service`，启动成功 |
| 状态 | ⬜ |

📌 **注意**：这个正式实验在 [Lv06](Lv06-DI与Bean.md) 会再做一次并深挖。本关先做一遍，感受"容器里没有"这件事。真正的深挖留给 Lv06，**本关不要展开 DI 的细节**。

### `Lv05-E02` · 让 Service 变成一个"没人要"的类

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 保留 `@Service`，但让 Controller 改回自己 `new` |
| 预期现象 | 🚧 待补充（提示：会报错吗？Service 构造方法的日志还会打印吗？） |
| 实际现象 | 🚧 待补充 |
| 原因 | 🚧 待补充（提示：`@Service` + 组件扫描 → 容器仍然会创建它） |
| 状态 | ⬜ |

### `Lv05-E03` · 两个 Service 都叫一个名字

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 再写一个 `@Service` 类，与现有类同名（不同包） |
| 预期现象 | 🚧 待补充（提示：Bean 名称冲突） |
| 实际现象 | 🚧 待补充 |
| 报错关键行 | 🚧 待补充 |
| 恢复动作 | 改成不同类名，或用 `@Service("xxx")` 指定名字 |
| 状态 | ⬜ |

---

## 7. 解释原理 `Lv05-S7`

> 必须依次回答 [09 §4 的五个问题](../09-关卡教学与交付模板.md#4-每关必答的五个问题)。

1. **没有它会发生什么？** 🚧 待补充（用 §2.2 的五条）
2. **它怎么解决的？** 🚧 待补充
3. **实验验证了什么？** 见 `Lv05-E01` ~ `Lv05-E03`
4. **一句话结论** 🚧 待补充
5. **架构哪一层变了？** 对象创建权转移（同步 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) 的 Lv05 行）

### 必答：到底"反转"了什么

| 问题 | 你的答案 |
| --- | --- |
| 谁控制什么？反转前 vs 反转后 | 🚧 待补充 |
| Spring 容器是什么？（用现象描述） | 🚧 待补充 |
| Bean 是什么？（用现象描述） | 🚧 待补充 |
| 容器什么时候创建 `StudentService`？（有实验证据） | 🚧 待补充（引用 §4.3 的观察） |

### 一句话结论（本关必须能说出）

📎 参考（`Consult.txt` · 最后才总结）：

> IOC = 对象创建和管理交给Spring

⚠️ 本关**到此为止**。`DI`、`Bean` 的完整含义在 Lv06 展开，本节不要提前讲。
本节不得出现未在 §4~§6 出现过的新名词。

---

## 8. 小练习 `Lv05-S8`

### `Lv05-Q01` 再放一个 Service

新增一个 `CourseService`，也用 `@Service`，并让 `StudentService` 通过构造器依赖它。观察两个对象的创建顺序（靠构造方法里的日志）。

### `Lv05-Q02` 单例验证

在 `StudentService` 里加一个实例字段 `private int count = 0;`，每次调用 `getStudent` 时 `count++` 并打印。
连续请求 3 次，观察 `count` 是 `1,2,3` 还是每次都是 `1`。**这说明容器创建了几个 `StudentService` 对象？**

### `Lv05-Q03` 不用 `@Service`

不用 `@Service`，改用 `@Component`，看是否还能正常启动。（提示：两者在容器眼里有区别吗？）

📌 答案写到本关「附录 A · 追加区」，**不要覆盖题目**。

---

## 9. 通关标准 `Lv05-S9`

> 全部勾选才算 ✅ 通关。勾选后到 [10-学习进度记录](../10-学习进度记录.md) 登记。

- [ ] `Lv05-A01` 亲手写过 `new StudentService()` 的版本，并能说出至少 3 个坏处
- [ ] `Lv05-A02` 能独立改成容器管理版本，且接口行为不变
- [ ] `Lv05-A03` 能用现象（构造方法日志的时机与次数）说明"容器在启动时创建了它，且只创建一次"
- [ ] `Lv05-A04` `Lv05-E01` 已完成，**真的看到了报错**，并能说出异常类名
- [ ] `Lv05-A05` `Lv05-Q01` ~ `Lv05-Q03` 已完成
- [ ] `Lv05-A06` 能不看资料说清"反转了什么"（控制什么、从谁转给谁）
- [ ] `Lv05-A07` 代码是自己敲的，不是复制的
- [ ] `Lv05-A08` 本关新增内容已按 [00-维护规范](../00-文档使用与维护规范.md) 登记

📌 本关**不要求**能说出 DI 与 Bean 的精确定义 —— 那是 Lv06 的验收项。

---

## 10. 下一关 `Lv05-S10`

现在容器会创建 `StudentService` 了。但还有个问题没回答：

**为什么容器创建完 `StudentService` 之后，能自动把它"塞进" `StudentController` 的构造方法？**

没有人调用过 `new StudentController(studentService)` —— 那这个参数是谁传的？

而且还有一件更奇怪的事：`@Service`、`@Component`、`@Repository`、`@Controller` 看起来都在做同一件事，为什么要分四个？

下一关：**DI 与 Bean**。

➡️ [`Lv06` · DI / Bean](Lv06-DI与Bean.md)

---

## 附录 A · 追加区

> 追加格式见 [00-维护规范 §3.3](../00-文档使用与维护规范.md)。已写入的条目不得删除。

### A.1 对象创建时机观察记录（待学习者填写）

| 观察项 | 记录 |
| --- | --- |
| `StudentService` 构造方法日志打印时机 | 🚧 待填 |
| 打印次数（一次启动内） | 🚧 待填 |
| 每次请求会重新创建吗？ | 🚧 待填 |

*（后续追加自此向下）*

## 附录 B · 踩坑记录 `Lv05-P0n`

| ID | 日期 | 现象 | 原因 | 解决 | 关联实验 |
| --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — |

## 附录 C · 勘误

*（暂无。格式见 [00-维护规范 §4.2](../00-文档使用与维护规范.md)。）*
