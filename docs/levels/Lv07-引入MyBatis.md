# Lv07 · 引入 MyBatis

> **关卡编号**：`Lv07` ｜ **所属阶段**：第三阶段 · 开始接数据库
> **前置关卡**：`Lv06` DI / Bean（✅） ｜ **状态**：⬜ 未开始
> **对应需求**：—（持久层引入） ｜ **对应接口**：无变化（Service 内部改造） ｜ **对应数据表**：`T-student`（本关不建表）
> **本关产物**：出现 **Mapper 层**，三层结构 `Controller → Service → Mapper` 成立

---

## 0. 本关速览

| 项目 | 内容 |
| --- | --- |
| 一句话目标 | 用 Mapper 接口替代手写 JDBC，并说清"Mapper 到底是什么" |
| 核心知识点 | `@Mapper`、`@MapperScan`、`@Select`/`@Insert`/`@Update`/`@Delete`、XML 映射 |
| 预计耗时 | 🚧 待补充 |
| 难度（1~5） | 4 |
| 关键文件 | `mapper/StudentMapper.java`、`resources/mapper/StudentMapper.xml`、`pom.xml` |
| 架构变化 | 从 2 层变 3 层（Controller-Service-Mapper） |

---

## 1. 本关目标 `Lv07-S1`

1. 能说清"手写 JDBC"的重复劳动具体是哪些；
2. 能写出一个 `@Mapper` 接口，并让 Service 注入它、调用它；
3. 能分别用**注解**和 **XML** 各实现一次 `getById`；
4. 能回答本关的核心问题：**Mapper 到底是什么？**（它是一个接口，但为什么能调用？）
5. 能说清 `#{}` 与 `${}` 的区别，以及为什么前者能防 SQL 注入。

📎 参考（`Consult.txt`）：

> 第 7 关：引入 MyBatis
> 首先建立：
> Controller ↓ Service ↓ Mapper
> 写：
> @Mapper
> public interface StudentMapper {
>     Student getById(Integer id);
> }
> 然后学习：
> @Mapper
> @MapperScan
> @Select
> @Insert
> @Update
> @Delete
> 以及 XML：
> <select id="getById">
>     SELECT *
>     FROM student
>     WHERE id = #{id}
> </select>
> 这一关重点理解：
> Mapper 到底是什么？

---

## 2. 为什么学 `Lv07-S2`

先制造问题。Service 里要查一个学生，手写 JDBC 是这样：

```java
public Student getStudent(Integer id) {
    Student student = null;
    try (Connection conn = DriverManager.getConnection(url, user, pwd);
         PreparedStatement ps = conn.prepareStatement("SELECT * FROM student WHERE id = ?")) {
        ps.setInt(1, id);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                student = new Student();
                student.setId(rs.getInt("id"));
                student.setName(rs.getString("name"));
                student.setAge(rs.getInt("age"));
                student.setGender(rs.getString("gender"));
                student.setClassName(rs.getString("class_name"));
            }
        }
    } catch (SQLException e) {
        throw new RuntimeException(e);
    }
    return student;
}
```

**问题清单：**

| # | 问题 | 后果 |
| --- | --- | --- |
| 1 | 每个查询都要写一遍连接、语句、遍历 | 大量重复代码 |
| 2 | 手工 `rs.getXxx` 一列列映射 | 加一个字段要改所有查询 |
| 3 | SQL 混在 Java 字符串里 | 无法格式化、无法高亮、拼错只能在运行时报错 |
| 4 | 异常处理到处 try-catch | 业务被噪声淹没 |
| 5 | 业务逻辑与数据访问混在一起 | 违反 `NFR-006` |

**MyBatis 解决的就是第 1、2、4 条**：你只写一个接口和 SQL，剩下的它做。

📌 本关**不建表、不连数据库**也能进行：MyBatis 会先生成 Mapper 的实现，你只要看到"接口被注入成功、能调用"就够了。
真正的数据库连接留给 Lv08。

---

## 3. 环境准备 `Lv07-S3`

| # | 项目 | 要求 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | Lv06 已通关 | 容器能管理 Bean | 启动成功 | ⬜ |
| 2 | 依赖 | 加入 `mybatis-spring-boot-starter` | `pom.xml` 中有该依赖 | ⬜ |
| 3 | 依赖登记 | 已在 [03 附录 A](../03-技术栈与选型.md#附录-a--追加区) 登记 | 表格中有该行 | ⬜ |
| 4 | 版本 | 必须选**支持 Spring Boot 3** 的 MyBatis Starter | 见 [03 §2](../03-技术栈与选型.md#2-版本基线) | ⬜ |

⚠️ **易错点**：Spring Boot 3 使用 `jakarta.*`。使用 Spring Boot 2 时代的 MyBatis Starter 版本会出现 `javax.*` 找不到的编译/启动错误。

🚧 待补充：实际选定的版本号（回填 [03 §2](../03-技术栈与选型.md#2-版本基线)）。

---

## 4. 手把手写代码 `Lv07-S4`

### 4.1 目录结构

```
src/main/java/com/campus
├── controller/StudentController.java
├── service/StudentService.java
└── mapper/StudentMapper.java            ← 本关新增

src/main/resources
└── mapper/StudentMapper.xml             ← 本关新增（XML 版本）
```

### 4.2 Mapper 接口

```java
package com.campus.mapper;

import com.campus.entity.Student;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface StudentMapper {

    Student getById(Integer id);
}
```

📎 参考（`Consult.txt`）：

> @Mapper
> public interface StudentMapper {
>
>     Student getById(Integer id);
> }

### 4.3 XML 映射

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.campus.mapper.StudentMapper">

    <select id="getById" resultType="com.campus.entity.Student">
        SELECT *
        FROM student
        WHERE id = #{id}
    </select>

</mapper>
```

📎 参考（`Consult.txt`）：

> <select id="getById">
>     SELECT *
>     FROM student
>     WHERE id = #{id}
> </select>

⚠️ `namespace` 必须与 Mapper 接口的**全限定名**一致，`id` 必须与方法名一致。这两处对不上，报错会在**启动或调用时**才出现。

### 4.4 注解版（与 XML 二选一，本关两种都要写一遍）

```java
@Mapper
public interface StudentMapper {

    @Select("SELECT * FROM student WHERE id = #{id}")
    Student getById(Integer id);
}
```

📌 注解与 XML **不要同时存在同一个方法上**（会冲突）。

### 4.5 `@MapperScan` 与配置

```java
@SpringBootApplication
@MapperScan("com.campus.mapper")        // 批量扫描，替代逐个 @Mapper
public class CampusApplication {
    public static void main(String[] args) {
        SpringApplication.run(CampusApplication.class, args);
    }
}
```

```yaml
mybatis:
  mapper-locations: classpath:mapper/*.xml
  configuration:
    map-underscore-to-camel-case: true    # class_name → className
```

📌 `map-underscore-to-camel-case` 一旦开启，**`className` 的映射关系就被确定下来了**，见 [07 §2](../07-代码规范与工程规范.md#2-命名规范)。该决定写入 [05 §3](../05-数据库设计.md)。

### 4.6 Service 调用 Mapper

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

### 4.7 验证

🚧 待补充：Lv08 之前数据库尚未连接，本关的验证方式是"启动成功 + Mapper Bean 能注入成功"（可用构造方法日志证明）。

---

## 5. 你自己敲 `Lv07-S5`

- [ ] 不看 §4，手写 `@Mapper` 接口 + XML 映射，跑通
- [ ] 不看 §4，再用纯注解方式写一遍
- [ ] 回答：Mapper 是接口，没有实现类，为什么能调用？

---

## 6. 故意制造错误 `Lv07-S6`

### `Lv07-E01` · `namespace` 写错

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把 XML 的 `namespace` 改成不存在的类名 |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 报错关键行 | 🚧 待补充 |
| 原因 | 🚧 待补充 |
| 恢复动作 | 改回全限定名 |
| 状态 | ⬜ |

### `Lv07-E02` · XML 文件没被扫描到

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把 XML 换个目录（不在 `mapper-locations` 匹配范围内） |
| 预期现象 | 🚧 待补充（提示：是启动报错还是调用报错？） |
| 实际现象 | 🚧 待补充 |
| 报错关键行 | 🚧 待补充 |
| 恢复动作 | 移回 `resources/mapper/` |
| 状态 | ⬜ |

### `Lv07-E03` · 方法名与 XML `id` 不一致

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 接口方法叫 `getById`，XML 的 `id` 写成 `selectById` |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充 |
| 报错关键行 | 🚧 待补充 |
| 状态 | ⬜ |

### `Lv07-E04` · 用 `${}` 代替 `#{}`

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把 `#{id}` 改成 `${id}` |
| 预期现象 | 🚧 待补充（提示：只在 Lv08 真正查询后才有可观察差异） |
| 实际现象 | 🚧 待补充（**Lv08 后回填**） |
| 原因 | 🚧 待补充（预编译 vs 字符串拼接 → SQL 注入） |
| 状态 | ⬜ 待 Lv08 后回填 |

### `Lv07-E05` · 关掉驼峰映射

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把 `map-underscore-to-camel-case` 设为 `false` |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充（**Lv08 后回填**：`className` 会是 null） |
| 状态 | ⬜ 待 Lv08 后回填 |

---

## 7. 解释原理 `Lv07-S7`

> 必须依次回答 [09 §4 的五个问题](../09-关卡教学与交付模板.md#4-每关必答的五个问题)。

1. **没有它会发生什么？** 🚧 待补充（见 §2 的 5 条问题）
2. **它怎么解决的？** 🚧 待补充
3. **实验验证了什么？** 见 `Lv07-E01` ~ `Lv07-E05`
4. **一句话结论** 🚧 待补充
5. **架构哪一层变了？** 出现 Mapper 层（同步 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) 的 Lv07 行）

### 本关核心问题：Mapper 到底是什么？

| 层次 | 答案 |
| --- | --- |
| 表面看 | 🚧 待补充（一个没有实现类的 interface） |
| 实际上 | 🚧 待补充（提示：启动时为它生成了代理实现，并注册进容器） |
| 证据 | 🚧 待补充（提示：它能被构造器注入成功，说明容器里有它的 Bean） |
| 与普通 Bean 的区别 | 🚧 待补充 |

⚠️ 本节不得出现未在 §4~§6 出现过的新名词。

---

## 8. 小练习 `Lv07-S8`

### `Lv07-Q01` 补全 CRUD

给 `StudentMapper` 补上 `insert` / `update` / `delete` / `selectAll` 四个方法及对应 SQL（先不跑，Lv08 再跑）。

### `Lv07-Q02` 注解 vs XML

同一个 `selectAll`，用注解写一遍，再用 XML 写一遍，比较两者在"SQL 复杂起来之后"的可维护性。

### `Lv07-Q03` 参数多值

写一个 `selectByNameAndClass(String name, String className)`，处理多参数场景（提示：`@Param`）。

📌 答案写到本关「附录 A · 追加区」，**不要覆盖题目**。

---

## 9. 通关标准 `Lv07-S9`

> 全部勾选才算 ✅ 通关。勾选后到 [10-学习进度记录](../10-学习进度记录.md) 登记。

- [ ] `Lv07-A01` 能手写 `@Mapper` 接口 + XML 映射，并成功注入到 Service
- [ ] `Lv07-A02` 能用纯注解方式实现同一个查询
- [ ] `Lv07-A03` 能不看资料回答"Mapper 是接口为什么能调用"，并给出证据
- [ ] `Lv07-A04` 能说清 `@Mapper` 与 `@MapperScan` 的区别
- [ ] `Lv07-A05` 能说清 `#{}` 与 `${}` 的区别
- [ ] `Lv07-A06` `Lv07-E01` ~ `Lv07-E03` 中至少完成两个，且真的看到了报错
- [ ] `Lv07-A07` `Lv07-Q01` ~ `Lv07-Q03` 已完成
- [ ] `Lv07-A08` 依赖已登记到 [03 附录 A](../03-技术栈与选型.md#附录-a--追加区) 与版本基线
- [ ] `Lv07-A09` 代码是自己敲的，不是复制的
- [ ] `Lv07-A10` 本关新增内容已按 [00-维护规范](../00-文档使用与维护规范.md) 登记

---

## 10. 下一关 `Lv07-S10`

`StudentMapper` 写好了，但 `student` 表**还不存在**，数据库也**还没连上**。

现在的代码一旦真的执行 `getById`，会直接抛连接异常。

下一关：建库建表，让 `SELECT * FROM student WHERE id = #{id}` 真的跑在一张真实的表上。

➡️ [`Lv08` · 真正访问 MySQL](Lv08-真正访问MySQL.md)

---

## 附录 A · 追加区

> 追加格式见 [00-维护规范 §3.3](../00-文档使用与维护规范.md)。已写入的条目不得删除。

### A.1 MyBatis 版本与配置记录（待学习者填写）

| 项 | 记录 |
| --- | --- |
| `mybatis-spring-boot-starter` 版本 | 🚧 待填 |
| 是否开启驼峰映射 | 🚧 待填 |
| 最终选择：注解 or XML | 🚧 待填 |

*（后续追加自此向下）*

## 附录 B · 踩坑记录 `Lv07-P0n`

| ID | 日期 | 现象 | 原因 | 解决 | 关联实验 |
| --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — |

## 附录 C · 勘误

*（暂无。格式见 [00-维护规范 §4.2](../00-文档使用与维护规范.md)。）*
