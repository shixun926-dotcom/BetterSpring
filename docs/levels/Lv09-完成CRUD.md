# Lv09 · 完成 CRUD

> **关卡编号**：`Lv09` ｜ **所属阶段**：第三阶段 · 开始接数据库
> **前置关卡**：`Lv08` 真正访问 MySQL（✅） ｜ **状态**：⬜ 未开始
> **对应需求**：`FR-S-001` ~ `FR-S-005` ｜ **对应接口**：`API-S-001` ~ `API-S-005` ｜ **对应数据表**：`T-student`
> **本关产物**：**学生管理系统 V1.0** —— 一个真正能用的后端服务

---

## 0. 本关速览

| 项目 | 内容 |
| --- | --- |
| 一句话目标 | 把增删改查四条路全部打通，做出第一个完整可用的系统 |
| 核心知识点 | RESTful 语义落地、`@PostMapping`/`@PutMapping`/`@DeleteMapping`、`@RequestBody`、`@PathVariable` |
| 预计耗时 | 🚧 待补充 |
| 难度（1~5） | 3 |
| 关键文件 | `StudentController.java`、`StudentService.java`、`StudentMapper.java` + XML |
| 架构变化 | 三层结构完整闭环，**第一个里程碑 M3** |

📌 本关是第一个**里程碑**：`M3 · 有数据`，见 [08 §5](../08-关卡总览与路线图.md#5-阶段通关里程碑)。
完成后建议打 Git tag `m3-v1.0`。

---

## 1. 本关目标 `Lv09-S1`

1. 能完整实现 5 个接口：`POST /students`、`GET /students`、`GET /students/{id}`、`PUT /students/{id}`、`DELETE /students/{id}`；
2. 每个接口都能在 Postman 跑通，并**在数据库客户端里验证数据真的变了**；
3. 能说清 `GET` / `POST` / `PUT` / `DELETE` 分别对应"对资源的什么操作"；
4. 能说清"新增"为什么用 `POST` 而不是 `GET`；
5. 能说清 `PUT` 的语义（整体替换还是局部更新），以及本项目选择了哪一种。

📎 参考（`Consult.txt`）：

> 第 9 关：完成 CRUD
> 这个阶段我们把学生管理系统真正做出来。
> Create  POST   /students
> Read    GET    /students
>         GET    /students/1
> Update  PUT    /students/1
> Delete  DELETE /students/1
> 最终：
> 学生管理系统 V1.0
> 已经可以用了。

---

## 2. 为什么学 `Lv09-S2`

Lv08 只打通了"查一个"。但一个管理系统如果只有"查"，它就不是系统。

先制造问题：

| # | 问题 | 后果 |
| --- | --- | --- |
| 1 | 只有 `GET /student/{id}` | 无法录入新学生 |
| 2 | 无法列出全部学生 | 用户看不到任何东西 |
| 3 | 无法修改 | 录错了只能去数据库里改 |
| 4 | 无法删除 | 数据只增不减 |
| 5 | 接口名一会儿 `/student`、一会儿 `/students` | 前端根本无法预期 |

**CRUD 解决的就是第 1~4 条；RESTful 命名解决第 5 条。**

📌 参考文档的路径全部用的是 **复数 `/students`**（注意与 Lv03 教学期的 `/student` 不同）。
这个变化必须在 [06-接口规范](../06-接口规范.md) 登记清楚 —— 教学期接口 `API-S-T*` 保留为历史，不删除。

---

## 3. 环境准备 `Lv09-S3`

| # | 项目 | 要求 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | Lv08 已通关 | 能查出真实数据 | `GET /student/1` 有数据 | ⬜ |
| 2 | Postman 集合 | 已建 `campus-api` 且含环境变量 `baseUrl` | 见 [06 §8](../06-接口规范.md#8-postman-集合约定) | ⬜ |
| 3 | 数据库客户端 | 可实时查看 `student` 表 | 能执行 `SELECT` | ⬜ |

📌 本关起，**每写完一个接口就要在 Postman 里建一条对应请求**（命名 `API-S-00X 描述`），而不是最后一起补。

---

## 4. 手把手写代码 `Lv09-S4`

### 4.1 接口清单（对照 [06 §6.1](../06-接口规范.md#61-学生管理-api-s-)）

| ID | 方法 | 路径 | 说明 | 需求 |
| --- | --- | --- | --- | --- |
| `API-S-001` | `POST` | `/students` | 新增学生 | `FR-S-001` |
| `API-S-002` | `GET` | `/students` | 查询列表 | `FR-S-002` |
| `API-S-003` | `GET` | `/students/{id}` | 查询单个 | `FR-S-003` |
| `API-S-004` | `PUT` | `/students/{id}` | 修改 | `FR-S-004` |
| `API-S-005` | `DELETE` | `/students/{id}` | 删除 | `FR-S-005` |

### 4.2 Controller

```java
@RestController
@RequestMapping("/students")
public class StudentController {

    private final StudentService studentService;

    public StudentController(StudentService studentService) {
        this.studentService = studentService;
    }

    @PostMapping
    public String add(@RequestBody Student student) { ... }          // 🚧 待补充

    @GetMapping
    public List<Student> list() { ... }                              // 🚧 待补充

    @GetMapping("/{id}")
    public Student get(@PathVariable Integer id) { ... }             // 🚧 待补充

    @PutMapping("/{id}")
    public String update(@PathVariable Integer id,
                         @RequestBody Student student) { ... }       // 🚧 待补充

    @DeleteMapping("/{id}")
    public String delete(@PathVariable Integer id) { ... }           // 🚧 待补充
}
```

⚠️ 注意此处返回值是**裸的** `Student` / `List<Student>` / `String`。
这正是 Lv10 要解决的问题 —— **不要在本关提前统一返回**（参考文档把 Lv10 独立出来是有意为之）。

### 4.3 Service

```java
@Service
public class StudentService {

    private final StudentMapper studentMapper;

    public StudentService(StudentMapper studentMapper) {
        this.studentMapper = studentMapper;
    }

    // 🚧 待补充：list / getById / add / update / delete 五个方法
}
```

### 4.4 Mapper 接口 + XML

```java
@Mapper
public interface StudentMapper {
    Student getById(Integer id);
    List<Student> selectAll();
    int insert(Student student);
    int update(Student student);
    int deleteById(Integer id);
}
```

```xml
<!-- 🚧 待补充：五条 SQL
     <select id="selectAll" resultType="com.campus.entity.Student">
         SELECT * FROM student
     </select>
     <insert id="insert" useGeneratedKeys="true" keyProperty="id"> ... </insert>
     ...
-->
```

📌 `useGeneratedKeys="true" keyProperty="id"` 让自增主键回填到实体里 —— 这是一个容易漏掉、但后期非常关键的细节。

### 4.5 运行与验证（每个接口都要做双边验证）

| # | Postman 操作 | 数据库客户端验证 |
| --- | --- | --- |
| 1 | `POST /students` 新增一条 | `SELECT * FROM student` 多了一行 |
| 2 | `GET /students` | 行数与数据库一致 |
| 3 | `GET /students/{id}` | 字段值与数据库一致 |
| 4 | `PUT /students/{id}` 改姓名 | 数据库里该行姓名已变 |
| 5 | `DELETE /students/{id}` | 数据库里该行消失 |

📌 **"接口返回对了"不等于"数据库对了"。** 必须两边都看。

🚧 待补充：实际执行记录 + 截图/粘贴。

---

## 5. 你自己敲 `Lv09-S5`

- [ ] 不看 §4，独立写出 5 个接口（Controller → Service → Mapper → XML）
- [ ] 每个接口都做一次"Postman + 数据库客户端"双边验证
- [ ] 说清楚为什么路径用 `/students`（复数）而不是 `/student`

---

## 6. 故意制造错误 `Lv09-S6`

### `Lv09-E01` · `@PostMapping` 改成 `@GetMapping`

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 新增接口的注解改成 `@GetMapping`，用原来的 `POST` 请求访问 |
| 预期现象 | 🚧 待补充（提示：HTTP 405 还是 404？） |
| 实际现象 | 🚧 待补充 |
| 状态码 / 报错 | 🚧 待补充 |
| 原因 | 🚧 待补充 |
| 状态 | ⬜ |

### `Lv09-E02` · `PUT` 不传完整对象

| 项 | 内容 |
| --- | --- |
| 破坏动作 | `PUT` 时只传 `{ "name": "张三丰" }`，其余字段不传 |
| 预期现象 | 🚧 待补充（提示：其它字段会变成 `null` 写进库吗？这就是 PUT 的语义问题） |
| 实际现象 | 🚧 待补充 |
| 原因 | 🚧 待补充 |
| 恢复动作 | 传完整对象，或改用局部更新策略 |
| 状态 | ⬜ |

📌 这个实验直接关系到 [06 附录 B B.5](../06-接口规范.md#附录-b--待决事项) 与 `FR-S-011`。

### `Lv09-E03` · 删除不存在的数据

| 项 | 内容 |
| --- | --- |
| 破坏动作 | `DELETE /students/99999` |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充（提示：影响行数是多少？接口返回什么？） |
| 原因 | 🚧 待补充 |
| 状态 | ⬜ |

### `Lv09-E04` · 新增时传重复的字段类型

| 项 | 内容 |
| --- | --- |
| 破坏动作 | `POST` 时把 `age` 传成字符串 `"abc"` |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 报错关键行 | 🚧 待补充 |
| 状态 | ⬜ |

### `Lv09-E05` · 中文字段乱码

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 建表时把字符集改成 `latin1`（或 URL 去掉 `characterEncoding`） |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充（提示：`??` 或问号） |
| 恢复动作 | 改回 `utf8mb4` |
| 状态 | ⬜ |

### `Lv09-E06` · 缺少 `@RequestBody`

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 新增接口去掉 `@RequestBody` |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充（提示：参数会是什么？） |
| 状态 | ⬜ |

---

## 7. 解释原理 `Lv09-S7`

> 必须依次回答 [09 §4 的五个问题](../09-关卡教学与交付模板.md#4-每关必答的五个问题)。

1. **没有它会发生什么？** 🚧 待补充
2. **它怎么解决的？** 🚧 待补充
3. **实验验证了什么？** 见 `Lv09-E01` ~ `Lv09-E06`
4. **一句话结论** 🚧 待补充
5. **架构哪一层变了？** 三层闭环完成（同步 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) 的 Lv09 行）

### 必须能答的问题

| 问题 | 答案 |
| --- | --- |
| `GET` / `POST` / `PUT` / `DELETE` 各对应什么操作？ | 🚧 待补充 |
| 为什么新增用 `POST` 不用 `GET`？ | 🚧 待补充 |
| `PUT` 是"整体替换"还是"局部更新"？我们选了哪个？ | 🚧 待补充 |
| 为什么路径用复数 `/students`？ | 🚧 待补充 |
| `useGeneratedKeys` 解决了什么问题？ | 🚧 待补充 |

⚠️ 本节不得出现未在 §4~§6 出现过的新名词。（统一返回、异常处理、参数校验留到 Lv10/Lv11/Lv15。）

---

## 8. 小练习 `Lv09-S8`

### `Lv09-Q01` 条件查询

实现 `GET /students?name=张` 按姓名模糊查询（`LIKE`）。

### `Lv09-Q02` 局部更新

为 `PUT` 设计一个"只更新传入字段"的方案，并说明它和"整体替换"的取舍。

### `Lv09-Q03` 学号

给 `student` 表加 `student_no` 字段（按 [05 §3.2](../05-数据库设计.md) 追加，不修改已有字段），并让新增接口接收它。

### `Lv09-Q04` 批量删除

设计一个 `DELETE /students?ids=1,2,3` 的接口，说明它与单个删除的取舍。

📌 答案写到本关「附录 A · 追加区」，**不要覆盖题目**。

---

## 9. 通关标准 `Lv09-S9`

> 全部勾选才算 ✅ 通关。勾选后到 [10-学习进度记录](../10-学习进度记录.md) 登记。

- [ ] `Lv09-A01` 5 个接口全部实现，且**每个都在 Postman 跑通**
- [ ] `Lv09-A02` 5 个接口全部做了一次"数据库客户端双边验证"（**本关核心证据**）
- [ ] `Lv09-A03` 能不看资料说清四种 HTTP 方法各自的语义与选择理由
- [ ] `Lv09-A04` 能说清 `PUT` 的语义选择，并指出它对前端的影响
- [ ] `Lv09-A05` `Lv09-E01` ~ `Lv09-E06` 中至少完成四个，且都真的看到了报错
- [ ] `Lv09-A06` `Lv09-Q01` ~ `Lv09-Q04` 中至少完成两个
- [ ] `Lv09-A07` 代码是自己敲的，不是复制的
- [ ] `Lv09-A08` [06 §6.1](../06-接口规范.md#61-学生管理-api-s-) 中 `API-S-001` ~ `API-S-005` 状态已更新
- [ ] `Lv09-A09` 教学期接口 `API-S-T01` ~ `API-S-T03` 已按 [06 §6.1.1](../06-接口规范.md#611-教学期中间态接口lv02--lv08会被替换) 标注（**未删除**）
- [ ] `Lv09-A10` 已在 [04 §5.3](../04-系统架构与技术演进.md#53-第三阶段结束时lv09-后-学生管理系统-v10) 补上本阶段架构快照
- [ ] `Lv09-A11` 已打 Git tag `m3-v1.0`（见 [08 §5](../08-关卡总览与路线图.md#5-阶段通关里程碑)）
- [ ] `Lv09-A12` 本关新增内容已按 [00-维护规范](../00-文档使用与维护规范.md) 登记

📌 **本关是第一个里程碑 M3。全部勾选后，你的项目第一次可以放到 GitHub 上给人看。**

---

## 10. 下一关 `Lv09-S10`

现在你的接口返回的东西长这样：

```
GET /students/1        → {"id":1,"name":"张三","age":20,"gender":"M","className":"计科2101"}
POST /students         → "添加成功"
GET /students          → [{"id":1,...},{"id":2,...}]
DELETE /students/1     → "删除成功"
```

**问题**：前端拿到这四种完全不同的东西，该怎么统一处理？

- 有的是对象，有的是数组，有的是一个字符串；
- 想知道"成功还是失败"，得靠猜状态码；
- 想显示错误信息，没有统一字段。

下一关：**统一返回结果**。

➡️ [`Lv10` · 统一返回结果](Lv10-统一返回结果.md)

---

## 附录 A · 追加区

> 追加格式见 [00-维护规范 §3.3](../00-文档使用与维护规范.md)。已写入的条目不得删除。

### A.1 V1.0 验收记录（待学习者填写）

| 接口 | Postman 结果 | 数据库验证结果 | 日期 |
| --- | --- | --- | --- |
| `API-S-001` | 🚧 | 🚧 | — |
| `API-S-002` | 🚧 | 🚧 | — |
| `API-S-003` | 🚧 | 🚧 | — |
| `API-S-004` | 🚧 | 🚧 | — |
| `API-S-005` | 🚧 | 🚧 | — |

*（后续追加自此向下）*

## 附录 B · 踩坑记录 `Lv09-P0n`

| ID | 日期 | 现象 | 原因 | 解决 | 关联实验 |
| --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — |

## 附录 C · 勘误

*（暂无。格式见 [00-维护规范 §4.2](../00-文档使用与维护规范.md)。）*
