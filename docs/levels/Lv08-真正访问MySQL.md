# Lv08 · 真正访问 MySQL

> **关卡编号**：`Lv08` ｜ **所属阶段**：第三阶段 · 开始接数据库
> **前置关卡**：`Lv07` 引入 MyBatis（✅） ｜ **状态**：⬜ 未开始
> **对应需求**：`FR-S-003`（查询单个学生） ｜ **对应接口**：`API-S-003` ｜ **对应数据表**：`T-student`
> **本关产物**：一条从 HTTP 到 MySQL 再回来的完整链路，能查出**真实数据库里的数据**

---

## 0. 本关速览

| 项目 | 内容 |
| --- | --- |
| 一句话目标 | 建库建表、连上 MySQL，第一次看到"我写的 Java 代码真的把数据库里的数据拿出来了" |
| 核心知识点 | 数据源配置、连接池、`student` 表、完整 JDBC 链路、`Entity` |
| 预计耗时 | 🚧 待补充 |
| 难度（1~5） | 3 |
| 关键文件 | `application.yml`、`db/01-schema.sql`、`entity/Student.java`、`StudentMapper.xml` |
| 架构变化 | 数据持久化落地，出现 **Entity** |

---

## 1. 本关目标 `Lv08-S1`

1. 能创建 `campus` 库与 `student` 表，并插入至少 3 条测试数据；
2. 能配置好数据源（URL / 用户名 / 密码 / 驱动），并让项目启动时连接成功；
3. 能说出**完整链路的每一段**：`Controller → Service → Mapper → MyBatis → JDBC → MySQL`；
4. 能通过 HTTP 接口查出数据库里**真实存在的**学生数据；
5. 能说清 `Entity` 的字段与表的列是怎么对应上的（驼峰映射）。
6. 能说清连接池解决的是什么问题。

📎 参考（`Consult.txt`）：

> 第 8 关：真正访问 MySQL
> 创建：
> student
> 表：
> id
> name
> age
> gender
> class_name
> 然后：
> Controller
>  ↓
> Service
>  ↓
> Mapper
>  ↓
> MyBatis
>  ↓
> JDBC
>  ↓
> MySQL
> 你会第一次看到：
> 我写的 Java 代码真的把数据库里的数据拿出来了。

---

## 2. 为什么学 `Lv08-S2`

Lv07 结束时，你的代码"看起来"能查数据了，但其实：

- `student` 表不存在 → 执行 SQL 必然报 `Table 'campus.student' doesn't exist`
- 数据库没连上 → 连 SQL 都发不出去

**问题**：代码写得再对，"数据从哪来"这件事没解决，链路就是断的。

📌 本关的价值不在于"配一个数据源"，而在于：

> **你会第一次亲眼看到一次完整的跨层、跨进程调用** ——
> 你写的 Java 方法，最终变成了一条 SQL，跑在另一个进程（MySQL）里，再把结果搬回来变成 Java 对象。

这是从"写代码"到"做系统"的分界线。

---

## 3. 环境准备 `Lv08-S3`

| # | 项目 | 要求 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | MySQL 8.x 已安装并启动 | 能连接 | `mysql -u root -p -e "select version();"` | ⬜ |
| 2 | 数据库客户端 | Navicat / DBeaver / IDEA Database | 能建库建表 | ⬜ |
| 3 | 驱动依赖 | `mysql-connector-j` | `pom.xml` 中有该依赖 | ⬜ |
| 4 | 库名 | `campus` | 见 [03 §5](../03-技术栈与选型.md#5-本地资源与命名约定) | ⬜ |
| 5 | 字符集 | `utf8mb4` | 建库语句中指定 | ⬜ |
| 6 | 密码管理 | **不得把真实密码提交到 Git** | 见 [07 §7.3](../07-代码规范与工程规范.md#73-必须提交--禁止提交) | ⬜ |

---

## 4. 手把手写代码 `Lv08-S4`

### 4.1 建库建表

```sql
CREATE DATABASE IF NOT EXISTS campus DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE campus;

CREATE TABLE student (
    id         INT          NOT NULL AUTO_INCREMENT COMMENT '主键',
    name       VARCHAR(50)  NOT NULL               COMMENT '姓名',
    age        INT          NULL                   COMMENT '年龄',
    gender     VARCHAR(10)  NULL                   COMMENT '性别',
    class_name VARCHAR(50)  NULL                   COMMENT '班级',
    PRIMARY KEY (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '学生表';
```

📎 参考（`Consult.txt` · 表的字段）：

> 创建：
> student
> 表：
> id
> name
> age
> gender
> class_name

📌 **本关只建这 5 个字段。** 其他字段（`student_no`、`avatar_url`、`create_time`…）按 [05 §3.2](../05-数据库设计.md) 在后续关卡追加。

**初始化数据（至少 3 条）：**

```sql
INSERT INTO student (name, age, gender, class_name) VALUES
('张三', 20, 'M', '计科2101'),
('李四', 21, 'F', '计科2101'),
('王五', 19, 'M', '软工2102');
```

📌 语句保存到 `src/main/resources/db/01-schema.sql` 与 `02-data.sql`，见 [05 §7](../05-数据库设计.md#7-脚本文件约定)。

### 4.2 数据源配置

```yaml
spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/campus?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai
    username: root
    password: 🚧 待补充（不要提交真实密码）
```

⚠️ `serverTimezone` 必须设置。不设置时区，时间字段会出现 8 小时偏差或直接报错。

### 4.3 Entity

```java
package com.campus.entity;

import lombok.Data;

@Data
public class Student {
    private Integer id;
    private String name;
    private Integer age;
    private String gender;
    private String className;      // ← 对应 class_name
}
```

📌 `className` 与 `class_name` 的对应关系由 `map-underscore-to-camel-case: true` 提供（Lv07 已配）。
📌 `@Data` 来自 Lombok —— 如果 IDE 报红但能编译，是插件没装（见 [03 §4](../03-技术栈与选型.md#4-环境准备清单) E-10）。

### 4.4 补全 Mapper 与 Service

```java
@Mapper
public interface StudentMapper {
    Student getById(Integer id);
    // 🚧 待补充：Lv07 的 Q01 已写好的其他方法
}
```

```java
@Service
public class StudentService {
    private final StudentMapper studentMapper;

    public StudentService(StudentMapper studentMapper) {
        this.studentMapper = studentMapper;
    }

    public Student getStudent(Integer id) {
        return studentMapper.getById(id);
    }
}
```

### 4.5 完整链路（关掉本书，自己画一遍）

📎 参考（`Consult.txt` · 完整链路）：

> Controller
>  ↓
> Service
>  ↓
> Mapper
>  ↓
> MyBatis
>  ↓
> JDBC
>  ↓
> MySQL

🚧 待补充：把每一层在**你的代码里**对应到具体文件/类名。

| 链路环节 | 我的代码里对应什么 |
| --- | --- |
| Controller | 🚧 待填 |
| Service | 🚧 待填 |
| Mapper | 🚧 待填 |
| MyBatis | 🚧 待填 |
| JDBC | 🚧 待填 |
| MySQL | 🚧 待填 |

### 4.6 运行与验证

```
GET http://localhost:8080/student/1
→ {"id":1,"name":"张三","age":20,"gender":"M","className":"计科2101"}
```

📌 **本关最重要的一刻**：在数据库客户端里把 `张三` 改成 `张三丰`，刷新接口，看到返回变了。
这一步才真正证明"数据是从数据库来的"，而不是代码里写死的。

🚧 待补充：实际执行记录。

---

## 5. 你自己敲 `Lv08-S5`

- [ ] 不看 §4，手写建库建表语句并执行
- [ ] 不看 §4，写 `Student` 实体，字段与表列一一对应
- [ ] 不看 §4，写数据源配置，启动成功
- [ ] 不看 §4，画一遍完整链路六段
- [ ] 做一次"改数据库 → 刷新接口"的验证

---

## 6. 故意制造错误 `Lv08-S6`

### `Lv08-E01` · 把密码改错

| 项 | 内容 |
| --- | --- |
| 破坏动作 | `password` 改成一个错误值 |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 报错关键行 | 🚧 待补充 |
| 原因 | 🚧 待补充 |
| 恢复动作 | 改回正确密码 |
| 状态 | ⬜ |

### `Lv08-E02` · 库名写错

| 项 | 内容 |
| --- | --- |
| 破坏动作 | URL 里的库名改成 `campus2` |
| 预期现象 | 🚧 待补充 |
| 报错关键行 | 🚧 待补充 |
| 状态 | ⬜ |

### `Lv08-E03` · 表不存在

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把表 `DROP TABLE student`（或 SQL 里写成 `students`） |
| 预期现象 | 🚧 待补充（提示：这是启动期错误还是请求期错误？） |
| 报错关键行 | 🚧 待补充 |
| 恢复动作 | 重新建表 |
| 状态 | ⬜ |

### `Lv08-E04` · 关掉驼峰映射（回填 Lv07-E05）

| 项 | 内容 |
| --- | --- |
| 破坏动作 | `map-underscore-to-camel-case: false` |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充（预期：`className` 为 `null`，其余字段正常） |
| 原因 | 🚧 待补充 |
| 恢复动作 | 改回 `true` |
| 状态 | ⬜ |

### `Lv08-E05` · `${}` 注入（回填 Lv07-E04）

| 项 | 内容 |
| --- | --- |
| 破坏动作 | XML 里把 `#{id}` 改成 `${id}`，请求 `/student/1 OR 1=1` |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 原因 | 🚧 待补充（预编译 vs 拼接） |
| 恢复动作 | 改回 `#{}` |
| 状态 | ⬜ |

### `Lv08-E06` · 返回 `null`

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 访问一个不存在的 id（如 `/student/99999`） |
| 预期现象 | 🚧 待补充（提示：现在返回什么？这就是 Lv11 要解决的问题） |
| 实际现象 | 🚧 待补充 |
| 状态 | ⬜ |

### `Lv08-E07` · 忘了 `serverTimezone`

| 项 | 内容 |
| --- | --- |
| 破坏动作 | URL 里去掉 `serverTimezone` |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 状态 | ⬜ |

---

## 7. 解释原理 `Lv08-S7`

> 必须依次回答 [09 §4 的五个问题](../09-关卡教学与交付模板.md#4-每关必答的五个问题)。

1. **没有它会发生什么？** 🚧 待补充
2. **它怎么解决的？** 🚧 待补充
3. **实验验证了什么？** 见 `Lv08-E01` ~ `Lv08-E07`
4. **一句话结论** 🚧 待补充
5. **架构哪一层变了？** 持久化落地（同步 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) 的 Lv08 行）
   📌 并在 [04 §5.3 第三阶段快照](../04-系统架构与技术演进.md#53-第三阶段结束时lv09-后-学生管理系统-v10) 补图（Lv09 后一并补）

### 必须能答的问题

| 问题 | 答案 |
| --- | --- |
| 一次请求最终变成了什么 SQL？在哪能看到它？ | 🚧 待补充（提示：开 MyBatis 的 SQL 日志） |
| 数据库连接是在**每次请求**时新建的吗？ | 🚧 待补充（提示：连接池） |
| 连接池解决什么问题？ | 🚧 待补充 |
| `Entity` 的 `className` 是怎么从 `class_name` 变过来的？ | 🚧 待补充 |
| `Controller` 有没有"知道"过 MySQL 的存在？ | 🚧 待补充 |

⚠️ 本节不得出现未在 §4~§6 出现过的新名词。

---

## 8. 小练习 `Lv08-S8`

### `Lv08-Q01` 打开 SQL 日志

打开 MyBatis / JDBC 的 SQL 打印，让每次查询都在控制台显示真实执行的 SQL 与参数。

### `Lv08-Q02` 查全部

实现 `GET /student` 返回全部学生，并做一次"改数据库 → 刷新接口"的验证。

### `Lv08-Q03` 换一个字段类型

把 `age` 改成 `VARCHAR`，观察实体里改成 `String` 与**不改**分别会怎样。

### `Lv08-Q04` 多数据源思考

如果项目要同时连两个库，当前配置够用吗？如果要改，需要动哪些地方？

📌 答案写到本关「附录 A · 追加区」，**不要覆盖题目**。

---

## 9. 通关标准 `Lv08-S9`

> 全部勾选才算 ✅ 通关。勾选后到 [10-学习进度记录](../10-学习进度记录.md) 登记。

- [ ] `Lv08-A01` 能独立建库建表并插入测试数据
- [ ] `Lv08-A02` 能独立配好数据源并启动成功
- [ ] `Lv08-A03` 通过 HTTP 接口查出了**数据库里真实存在**的数据
- [ ] `Lv08-A04` 完成了"改数据库 → 刷新接口 → 结果变化"的验证（**本关核心证据**）
- [ ] `Lv08-A05` 能不看资料画出完整链路六段，并对应到自己代码的文件
- [ ] `Lv08-A06` 能说清连接池解决什么问题、驼峰映射做了什么
- [ ] `Lv08-A07` `Lv08-E01` ~ `Lv08-E07` 中至少完成四个，且都真的看到了报错
- [ ] `Lv08-A08` 回填了 `Lv07-E04`（`${}` 注入）与 `Lv07-E05`（驼峰映射）
- [ ] `Lv08-A09` `Lv08-Q01` ~ `Lv08-Q04` 已完成
- [ ] `Lv08-A10` 真实密码没有被提交到 Git
- [ ] `Lv08-A11` 建表语句已归档到 `resources/db/` 并登记到 [05 §7](../05-数据库设计.md#7-脚本文件约定)
- [ ] `Lv08-A12` 代码是自己敲的，不是复制的
- [ ] `Lv08-A13` 本关新增内容已按 [00-维护规范](../00-文档使用与维护规范.md) 登记

📌 `Lv08-A04` 是本关的核心，**不允许跳过**。

---

## 10. 下一关 `Lv08-S10`

现在只有一个 `getById` 能跑。

`POST /student`（Lv03 写的）现在是什么状态？它有没有真的把数据写进数据库？删掉一个学生，数据库里真的少了一行吗？

下一关：把 CRUD 四条路全部打通，做出 **学生管理系统 V1.0**。

➡️ [`Lv09` · 完成 CRUD](Lv09-完成CRUD.md)

---

## 附录 A · 追加区

> 追加格式见 [00-维护规范 §3.3](../00-文档使用与维护规范.md)。已写入的条目不得删除。

### A.1 链路验证记录（待学习者填写）

| 观察项 | 记录 |
| --- | --- |
| 实际执行的 SQL（日志原文） | 🚧 待填 |
| 改库后接口返回是否变化 | 🚧 待填 |
| 启动耗时 | 🚧 待填 |

*（后续追加自此向下）*

## 附录 B · 踩坑记录 `Lv08-P0n`

| ID | 日期 | 现象 | 原因 | 解决 | 关联实验 |
| --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — |

## 附录 C · 勘误

*（暂无。格式见 [00-维护规范 §4.2](../00-文档使用与维护规范.md)。）*
