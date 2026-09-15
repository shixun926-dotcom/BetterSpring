# Lv16 · DTO / VO

> **关卡编号**：`Lv16` ｜ **所属阶段**：第八阶段 · 从"会写"变成"像公司"
> **前置关卡**：`Lv15` 参数校验（✅） ｜ **状态**：⬜ 未开始
> **对应需求**：`NFR-003`（附带）、`FR-S-011` ｜ **对应接口**：全部（出入参对象改造） ｜ **对应数据表**：全部
> **本关产物**：`Entity / DTO / VO` 三层对象模型落地，接口出入参与表结构解耦

---

## 0. 本关速览

| 项目 | 内容 |
| --- | --- |
| 一句话目标 | 说清 Entity / DTO / VO 各是什么、为什么必须分开，并落地到全部接口 |
| 核心知识点 | 三层对象模型、字段裁剪、越权防护、转换职责 |
| 预计耗时 | 🚧 待补充 |
| 难度（1~5） | 4 |
| 关键文件 | `entity/`、`dto/`、`vo/`、Controller 与 Service 签名 |
| 架构变化 | 层间传输对象与数据库实体解耦 |

📌 参考文档对本关的定位（**原文**）：

> 第 16 关：DTO / VO
> 开始理解：
> Entity
> DTO
> VO
> 例如：
> StudentEntity
>      ↓
> StudentDTO
>      ↓
> StudentVO
> 这是很多初学者看公司项目时非常容易懵的地方。

---

## 1. 本关目标 `Lv16-S1`

1. 能用自己的话说清 `Entity` / `DTO` / `VO` 三者的**用途差别**（不是背定义）；
2. 能画出 `Entity ← DTO`、`Entity → VO` 的转换方向，并说清为什么不许反向；
3. 能把 Lv09 起的全部接口改成"DTO 进、VO 出"；
4. 能举出**一个具体的越权 / 信息泄露例子**，说明不分离会造成什么后果；
5. 能说清转换代码该放在哪一层（以及为什么不该在 Controller 里写一堆 `set`）。

📎 参考（`Consult.txt`）：

> 例如：
> StudentEntity
>      ↓
> StudentDTO
>      ↓
> StudentVO

---

## 2. 为什么学 `Lv16-S2`

先制造问题。现在你的接口签名是这样的：

```java
public Result<Void> add(@Valid @RequestBody Student student)   // Student 是 Entity
public Result<Student> get(@PathVariable Integer id)          // 返回的也是 Entity
public Result<List<Student>> list()                           // 还是 Entity
```

**Entity 就是数据库表的镜像。于是：**

| # | 问题 | 具体后果 |
| --- | --- | --- |
| 1 | **前端能"猜"到表结构** | 返回的 JSON 字段 = 表的列，改表 = 改接口契约 |
| 2 | **越权写入** | 新增时前端多传一个 `id: 999` 或 `deleted: 1`，你的代码照收 |
| 3 | **敏感字段泄露** | `user` 表加个 `password` 字段，`GET /users` 直接把密码哈希吐出去 |
| 4 | **改表牵连全链路** | 表加一个内部字段，所有接口的返回都变了 |
| 5 | **接口无法独立演进** | 前端需要的"班级名 + 班主任名"这种组合，Entity 里根本没有 |

**第 3 条是真会出事的。** 你可以亲手试一次：
给 `Student` 实体加一个 `internalRemark` 字段（代表内部备注），不改任何 Controller，
`GET /students` 立刻就把这个内部字段暴露给了所有前端。

📌 一句话记住三种对象：

| 对象 | 面向谁 | 一句话 |
| --- | --- | --- |
| `Entity` | 数据库 | **表长什么样，我就长什么样** |
| `DTO`（Data Transfer Object） | 外部输入 | **我决定"允许你传什么进来"** |
| `VO`（View Object） | 外部输出 | **我决定"让你看到什么"** |

---

## 3. 环境准备 `Lv16-S3`

| # | 项目 | 要求 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | Lv15 已通关 | 已有 `StudentDTO` 与校验 | 校验失败返回 400 | ⬜ |
| 2 | 包结构 | `dto` / `vo` / `entity` 三个包都存在 | 见 [07 §1](../07-代码规范与工程规范.md#1-工程结构与包结构) | ⬜ |
| 3 | 规范已读 | [04 §6](../04-系统架构与技术演进.md#6-边界与硬约定) 第 4 条 | 已理解"Entity 不得直接作为出入参" | ⬜ |

---

## 4. 手把手写代码 `Lv16-S4`

### 4.1 目录结构

```
com/campus
├── entity
│   └── Student.java          ← 对应 T-student
├── dto
│   ├── StudentCreateDTO.java ← 新增入参
│   └── StudentUpdateDTO.java ← 修改入参
└── vo
    └── StudentVO.java        ← 出参
```

📌 DTO 的命名策略待定（见 [附录 B](#附录-b--待决事项)）：可以一个 `StudentDTO` 复用，也可以 `Create`/`Update` 分开。

### 4.2 三个对象

```java
// Entity —— 表映射，字段与表一一对应
@Data
public class Student {
    private Integer id;
    private String name;
    private Integer age;
    private String gender;
    private String className;
    // 未来可能有 create_time / update_time / deleted ...
}

// DTO —— 入参：只包含"允许外部传入"的字段
@Data
public class StudentCreateDTO {
    @NotBlank(message = "姓名不能为空")
    private String name;
    @NotNull @Min(0) @Max(150)
    private Integer age;
    @NotBlank
    private String gender;
    private String className;
    // 注意：没有 id、没有 createTime、没有 deleted
}

// VO —— 出参：只包含"允许外部看到"的字段
@Data
public class StudentVO {
    private Integer id;
    private String name;
    private Integer age;
    private String gender;
    private String className;
    // 可以比 Entity 多（如 className 之外再拼一个 teacherName）
    // 也可以比 Entity 少（排除内部字段）
}
```

### 4.3 转换职责

```java
// Service 里负责 Entity ↔ DTO/VO 的转换
public StudentVO getStudent(Integer id) {
    Student entity = studentMapper.getById(id);
    if (entity == null) throw new BusinessException(ErrorCode.NOT_FOUND, "学生不存在");
    return toVO(entity);            // 🚧 待补充：转换方法
}
```

| 转换 | 谁做 | 为什么 |
| --- | --- | --- |
| DTO → Entity | Service | Service 是业务边界的入口 |
| Entity → VO | Service | 同上；Controller 不应知道 Entity 结构 |
| VO → DTO | ⛔ 不允许 | 方向错了，说明分层有误 |

📌 转换代码放哪待定，见 [07 附录 B B.3](../07-代码规范与工程规范.md#附录-b--待决事项)（手写 / 静态工厂 / MapStruct）。

### 4.4 Controller 改造

```java
@PostMapping
public Result<Void> add(@Valid @RequestBody StudentCreateDTO dto) { ... }   // 入参 DTO

@GetMapping("/{id}")
public Result<StudentVO> get(@PathVariable Integer id) { ... }              // 出参 VO

@GetMapping
public Result<List<StudentVO>> list() { ... }                               // 出参 VO
```

📌 改造完成后，[04 §6](../04-系统架构与技术演进.md#6-边界与硬约定) 第 4 条（Entity 不得直接作为接口出入参）才算真正满足。

### 4.5 运行与验证（必须做的三个对比）

| # | 实验 | 预期 |
| --- | --- | --- |
| 1 | 新增时多传一个 `"id": 999` | **被忽略**（DTO 里没这个字段） |
| 2 | 查询返回的 JSON | 只包含 VO 里的字段，**不含内部字段** |
| 3 | 给 Entity 加一个 `internalRemark` 字段 | 接口返回**不变**（因为 VO 没有它） |

📌 第 3 条是本关最有力的证据：**改表不再影响接口。**

🚧 待补充：实际执行记录。

---

## 5. 你自己敲 `Lv16-S5`

- [ ] 不看 §4，为"新增学生"和"修改学生"各写一个 DTO
- [ ] 不看 §4，写 `StudentVO`，把全部接口改成"DTO 进、VO 出"
- [ ] 做一次"给 Entity 加字段"的实验，验证接口返回不变
- [ ] 画一次转换方向图，并标出不允许的方向

---

## 6. 故意制造错误 `Lv16-S6`

### `Lv16-E01` · 用 Entity 直接接收入参（核心观察）

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 新增接口改回 `@RequestBody Student`，请求里带 `"id": 999` |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充（提示：id 被写进去了吗？数据被覆盖了吗？） |
| 原因 | 🚧 待补充（越权写入） |
| 状态 | ⬜ |

### `Lv16-E02` · 返回 Entity 泄露内部字段

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 给 `Student` Entity 加 `private String internalRemark;`，接口返回 Entity |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充（提示：**立刻泄露**） |
| 恢复动作 | 改为返回 VO |
| 状态 | ⬜ |

### `Lv16-E03` · 用户表返回密码

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 写一个返回 `User` Entity 的接口（[05 §4](../05-数据库设计.md#4-t-user--用户表lv14-引入) 有 `password` 字段） |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充（提示：密码哈希出现在 JSON 里） |
| 恢复动作 | 改为返回 `UserVO` |
| 状态 | ⬜ |

📌 这是本关最值得亲手做一次的实验。

### `Lv16-E04` · DTO 里带 `id` 却又在校验中忽略

| 项 | 内容 |
| --- | --- |
| 破坏动作 | DTO 里保留 `id` 字段，但新增时不使用它 |
| 预期现象 | 🚧 待补充（前端会误以为可以传 id） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 从 DTO 里去掉 `id` |
| 状态 | ⬜ |

### `Lv16-E05` · 在 Controller 里做转换

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 在 Controller 里写 `vo.setName(entity.getName())` 一长串 |
| 预期现象 | 🚧 待补充（能跑，但违反分层） |
| 原因 | 🚧 待补充（Controller 不该知道 Entity 结构；复用与测试都变差） |
| 状态 | ⬜ |

### `Lv16-E06` · VO 里塞业务判断

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 给 VO 加一个 `public String getLevel() { if (age > 20) return "高年级"; ... }` |
| 预期现象 | 🚧 待补充 |
| 原因 | 🚧 待补充（VO 应只承载展示数据，判断属于 Service） |
| 状态 | ⬜ |

---

## 7. 解释原理 `Lv16-S7`

> 必须依次回答 [09 §4 的五个问题](../09-关卡教学与交付模板.md#4-每关必答的五个问题)。

1. **没有它会发生什么？** 🚧 待补充（用 §2 的五条问题 + `Lv16-E01`/`E02` 的实证）
2. **它怎么解决的？** 🚧 待补充
3. **实验验证了什么？** 见 `Lv16-E01` ~ `Lv16-E06`
4. **一句话结论** 🚧 待补充
5. **架构哪一层变了？** 对象模型解耦（同步 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) 的 Lv16 行）

### 必须能答的问题

| 问题 | 答案 |
| --- | --- |
| Entity / DTO / VO 各面向谁？ | 🚧 待补充 |
| 转换方向为什么不能反向？ | 🚧 待补充 |
| 为什么"改表不该影响接口"？ | 🚧 待补充（引用 `Lv16-E02` 的验证） |
| DTO 与 VO 能不能合并成一个？ | 🚧 待补充 |
| 转换放哪一层？为什么？ | 🚧 待补充 |

⚠️ 本节不得出现未在 §4~§6 出现过的新名词。

---

## 8. 小练习 `Lv16-S8`

### `Lv16-Q01` 新增与修改的 DTO 分组

把 `StudentCreateDTO` 拆成 `Create` 与 `Update` 两个，说明拆与不拆的取舍。

### `Lv16-Q02` VO 组合字段

让 `StudentVO` 额外携带一个"该学生所在班级的班主任姓名"（可以先造一个假数据源），说明 Entity 为什么做不到这件事。

### `Lv16-Q03` 用户接口脱敏

为 `user` 设计 `UserVO`，确保 `password` 永远不会出现在任何接口返回里。

### `Lv16-Q04` 转换工具

把 `Entity ↔ DTO/VO` 的转换抽成一个工具类或静态工厂，减少样板代码。

📌 答案写到本关「附录 A · 追加区」，**不要覆盖题目**。

---

## 9. 通关标准 `Lv16-S9`

> 全部勾选才算 ✅ 通关。勾选后到 [10-学习进度记录](../10-学习进度记录.md) 登记。

- [ ] `Lv16-A01` 能不看资料说清 Entity / DTO / VO 三者各自的用途
- [ ] `Lv16-A02` 全部接口已改为"DTO 进、VO 出"，Entity 不再出现在接口签名里
- [ ] `Lv16-A03` 完成了 `Lv16-E01`（越权写入）与 `Lv16-E02`（字段泄露）两个实验
- [ ] `Lv16-A04` 能画出转换方向图，并说出为什么不能反向
- [ ] `Lv16-A05` 完成过"给 Entity 加字段、接口返回不变"的验证（**本关核心证据**）
- [ ] `Lv16-A06` 能说清转换为什么放在 Service 而不是 Controller
- [ ] `Lv16-A07` `Lv16-E01` ~ `Lv16-E06` 中至少完成四个
- [ ] `Lv16-A08` `Lv16-Q01` ~ `Lv16-Q04` 中至少完成两个
- [ ] `Lv16-A09` [04 §6](../04-系统架构与技术演进.md#6-边界与硬约定) 第 4 条已实际满足
- [ ] `Lv16-A10` [07 附录 B B.3](../07-代码规范与工程规范.md#附录-b--待决事项)（转换方案）已定下并回填结论
- [ ] `Lv16-A11` 代码是自己敲的，不是复制的
- [ ] `Lv16-A12` 本关新增内容已按 [00-维护规范](../00-文档使用与维护规范.md) 登记

📌 `Lv16-A05` 是本关的核心，**不允许跳过**。

---

## 10. 下一关 `Lv16-S10`

回到 Lv14 留下的那个问题。

你现在有 5 个受保护接口，每个接口开头都有这四行：

```java
if (auth == null || !auth.startsWith("Bearer ")) throw new BusinessException(UNAUTHORIZED);
Long userId = jwtUtil.parseUserId(auth.substring(7));
if (userId == null) throw new BusinessException(UNAUTHORIZED);
// ... 然后才是业务
```

**这四行和业务没有任何关系，却出现在了每一个方法里。**

而且更麻烦的是：你迟早会遇到"这个接口只有管理员能调"这种事，那时候这四行会变成十几行。

下一关：**拦截器**。

➡️ [`Lv17` · 拦截器](Lv17-拦截器.md)

---

## 附录 A · 追加区

> 追加格式见 [00-维护规范 §3.3](../00-文档使用与维护规范.md)。已写入的条目不得删除。

### A.1 对象清单（待学习者填写）

| 对象 | 类型 | 面向 | 字段数 | 备注 |
| --- | --- | --- | --- | --- |
| `Student` | Entity | 表 | 🚧 | — |
| `StudentCreateDTO` | DTO | 入参 | 🚧 | — |
| `StudentVO` | VO | 出参 | 🚧 | — |

*（后续追加自此向下）*

## 附录 B · 待决事项

| # | 待决事项 | 影响 | 结论 |
| --- | --- | --- | --- |
| B.1 | DTO 一个复用还是 Create/Update 拆分？ | §4.1 | 🚧 待定 |
| B.2 | 转换用 MapStruct 还是手写？ | §4.3、[07 附录 B](../07-代码规范与工程规范.md#附录-b--待决事项) | 🚧 待定 |
| B.3 | VO 是否允许包含计算字段？ | `Lv16-E06` | 🚧 待定 |

## 附录 C · 勘误

*（暂无。格式见 [00-维护规范 §4.2](../00-文档使用与维护规范.md)。）*
