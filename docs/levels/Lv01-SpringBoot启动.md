# Lv01 · 让 Spring Boot 跑起来

> **关卡编号**：`Lv01` ｜ **所属阶段**：第一阶段 · 先让 Spring Boot 不再神秘
> **前置关卡**：无（起点） ｜ **状态**：✅ 已通关（2026-09-14）
> **对应需求**：—（环境与骨架关） ｜ **对应接口**：— ｜ **对应数据表**：—
> **本关产物**：一个能启动、能拉起 Tomcat、能监听 `8080` 的 Spring Boot 工程

---

## 0. 本关速览

| 项目 | 内容 |
| --- | --- |
| 一句话目标 | 亲手创建并启动一个 Spring Boot 工程，看到 Tomcat 在 8080 上监听 |
| 核心知识点 | Maven、`pom.xml`、Spring Boot Starter、`@SpringBootApplication`、`SpringApplication.run()`、`application.yml` |
| 预计耗时 | 环境已就绪约 40 分钟；本次含环境排障实际约 2.5 小时 |
| 难度（1~5） | 1 |
| 关键文件 | `pom.xml`、`CampusApplication.java`、`application.yml` |
| 架构变化 | 从"没有服务"变成"有一个能监听 8080 的进程"，见 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) |

---

## 1. 本关目标 `Lv01-S1`

完成后，你能做到：

1. 从零创建一个 Spring Boot 3 + Java 17 的 Maven 工程，并说清 `pom.xml` 里每一段的作用；
2. 执行 `main()` 启动应用，在控制台看到 Tomcat 启动日志；
3. 能指出日志里哪一行说明"项目开始监听 8080"；
4. 能不看资料说出 `main()` → `SpringApplication.run()` → 容器启动 → Tomcat 启动 这条链路；
5. 能用 `application.yml` 改一个配置（如端口），并验证它生效。

📎 参考（`Consult.txt`）：

> 第 1 关：让 Spring Boot 跑起来
> 目标
> 你要亲手完成：
> 创建 Spring Boot 项目
> ↓
> 启动
> ↓
> Tomcat 启动
> ↓
> 访问 localhost:8080
> 学什么
> Maven
> pom.xml
> Spring Boot Starter
> @SpringBootApplication
> SpringApplication.run()
> application.yml

---

## 2. 为什么学 `Lv01-S2`

先制造问题。在 Spring Boot 出现之前，要让一个 Java Web 项目跑起来，你得：

```
① 装一个 Tomcat
② 写 web.xml 配置 Servlet
③ 用 Maven 手动声明 spring-webmvc、jackson、servlet-api、日志……并自己对齐版本
④ 打成 war 包
⑤ 丢进 Tomcat 的 webapps
⑥ 启动 Tomcat
```

任何一步版本对不上，或者 `web.xml` 少一行，就是一堆 `ClassNotFoundException`。

**Spring Boot 解决的就是这件事**：把"运行环境"和"依赖版本"一起打包进你的项目，让你只写业务。

📌 所以本关你要盯住的不是"怎么创建项目"，而是：
**启动日志里到底发生了什么，让一个普通的 Java 类变成了一个 Web 服务器。**

📎 参考（`Consult.txt`）：

> 第一阶段：先让 Spring Boot 不再神秘
> 第 1 关：让 Spring Boot 跑起来

---

## 3. 环境准备 `Lv01-S3`

| # | 项目 | 要求 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | JDK 17 | 已安装并配置 `JAVA_HOME` | `java -version` 输出 `17.x` | ⬜ |
| 2 | Maven | 3.9.x | `mvn -v` 显示 `Java version: 17` | ⬜ |
| 3 | IDE | IDEA（已装 Lombok 插件） | 能新建 Spring Boot 项目 | ⬜ |
| 4 | 端口 8080 | 未被占用 | `netstat -ano \| findstr :8080` 无输出 | ⬜ |
| 5 | 网络 / 镜像 | 能下载 Maven 依赖 | `mvn -v` 后可正常拉包 | ⬜ |

> ⚠️ **本节假设与实际不符（2026-09-14）**：本机无外网、只装了 JDK 25、Maven 未加入 PATH。
> 原文保留不得修改，实测核验见下方「实际环境核验」，差异登记见 [附录 C.1](#c1-勘误2026-09-14)。

### 实际环境核验（2026-09-14 实测）

| # | 项目 | 文档要求 | 实测 | 差异处置 |
| --- | --- | --- | --- | --- |
| 1 | JDK | 17 | **25.0.3**（Microsoft OpenJDK） | 用 `javac --release 17` 产出 Java 17 字节码（`major version: 61`），满足 `java.version=17` 的语义 |
| 2 | `JAVA_HOME` | 已配置 | **未设置** | 每次命令行显式设置 `$env:JAVA_HOME` |
| 3 | Maven | 3.9.x 在 PATH | **3.9.16 已装但不在 PATH**：`D:\Develop\Maven\apache-maven-3.9.16-bin\apache-maven-3.9.16\bin\mvn.cmd` | 见第 5 行 |
| 4 | 端口 8080 | 未被占用 | ✅ 空闲 | — |
| 5 | 网络 / Maven 仓库 | 能拉包 | **外网完全不通**（HTTPS 全部超时 / schannel 失败）；`~/.m2/repository` 有 77.5 MB 缓存但**插件依赖闭包不全**，`mvn` 离线连 `resources` 阶段都过不去 | ⛔ `mvn` 不可用 → 改用 `javac` + 精确依赖清单，见 [附录 A.2](#a2-环境偏差与绕过方案2026-09-14) |
| 6 | `~/.m2` 缓存内容 | — | 已有 **Spring Boot 3.5.16** 全套应用依赖（35 个 jar） | 版本基线据此锁定，见 [03 §2](../03-技术栈与选型.md#2-版本基线) |

📌 完整公共前置见 [03-技术栈 §4 环境准备清单](../03-技术栈与选型.md#4-环境准备清单)。
📌 包根名约定为 `com.campus`，见 [03 §5](../03-技术栈与选型.md#5-本地资源与命名约定)。

---

## 4. 手把手写代码 `Lv01-S4`

### 4.1 最终目录结构

```
campus/
├── pom.xml
└── src
    └── main
        ├── java
        │   └── com/campus
        │       └── CampusApplication.java
        └── resources
            └── application.yml
```

📌 **实际工程多了一个 `campus/tools/` 目录**（`deps.txt` / `build.ps1` / `run.ps1` / `start.ps1` / `stop.ps1`）。
它不是项目资产，而是**本机无外网导致 `mvn` 不可用时的临时脚手架**，完整清单见 [附录 A.3](#a3-项目文件与常用命令本机离线)。
有外网后应删除并回到 `mvn spring-boot:run`。此差异已登记在 [附录 A.2](#a2-环境偏差与绕过方案2026-09-14)。

### 4.2 完整代码

**`src/main/java/com/campus/CampusApplication.java`**

```java
package com.campus;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class CampusApplication {

    public static void main(String[] args) {
        SpringApplication.run(CampusApplication.class, args);
    }
}
```

📎 参考（`Consult.txt` · 最终代码）：

> @SpringBootApplication
> public class Application {
>
>     public static void main(String[] args) {
>         SpringApplication.run(Application.class, args);
>     }
> }

**`src/main/resources/application.yml`**

```yaml
server:
  port: 8080

spring:
  application:
    name: campus
```

**`pom.xml`（实际生成结果，重点看 ① parent ② java.version ③ Starter 三处）**

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.5.16</version>            <!-- 版本仲裁中心 -->
    <relativePath/>
</parent>

<groupId>com.campus</groupId>
<artifactId>campus</artifactId>
<version>0.0.1-SNAPSHOT</version>

<properties>
    <java.version>17</java.version>      <!-- parent 会转成 maven.compiler.release -->
</properties>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>   <!-- 不写版本号：由 parent 决定 -->
    </dependency>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

**三段各自的真实作用（`Lv01-A07` 的答案）：**

| 段 | 作用 | 证据 |
| --- | --- | --- |
| `parent` | 它的父 POM `spring-boot-dependencies` 用 `<dependencyManagement>` 预声明了几乎所有常用依赖的版本。所以下面的 Starter 才能**不写版本号**，且互相兼容 | `spring-boot-starter-web` 无 `<version>` 也能解析到 3.5.16 |
| `java.version` | parent 把它映射为 `maven.compiler.release`，最终传给 `javac` 的 `release` 参数，决定编译产出的字节码版本 | `javap -verbose` 显示 `major version: 61`（= Java 17） |
| Starter | 一个"依赖打包入口"。`spring-boot-starter-web` 实际拉进来 spring-web / spring-webmvc / 内嵌 Tomcat / Jackson / 日志 等 35 个 jar | 见 `campus/tools/deps.txt` 的 35 行清单 |

📌 真实文件：`campus/pom.xml`（含上述所有段落，带逐段注释）。
📌 `pom.xml` 的 XML 注释里**不能出现 `--`** —— 本次就因此踩了一次（见 [附录 B · Lv01-P05](#附录-b--踩坑记录-lv01-p0n)）。

### 4.3 运行与验证

```bash
mvn spring-boot:run
# 或在 IDE 中直接运行 CampusApplication.main()
```

预期在控制台看到（关键行）：

```
Tomcat initialized with port(s): 8080 (http)
Tomcat started on port(s): 8080 (http) with context path ''
Started CampusApplication in x.xxx seconds
```

> ⚠️ **已被取代（2026-09-14）**：实测日志文案与上面略有差异（`port` 无 `(s)`、`context path '/'`）。
> 请以 [附录 C.1 勘误](#c1-勘误2026-09-14) 为准。以上原文保留，不得修改。

浏览器访问 `http://localhost:8080` → 出现 `Whitelabel Error Page`（404）**是正常的**：
项目已经跑起来了，只是还没有任何接口。这正是 Lv02 要解决的问题。

**实际启动日志（2026-09-14 19:15:49，原样粘贴，未删改）**

```
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::               (v3.5.16)

2026-09-14T19:15:49.932+08:00  INFO 16740 --- [campus] [           main] com.campus.CampusApplication             : Starting CampusApplication using Java 25.0.3 with PID 16740 (D:\ProgramData\deepseek\GitHub\campus\target\classes started by Administrator in D:\ProgramData\deepseek\GitHub)
2026-09-14T19:15:49.934+08:00  INFO 16740 --- [campus] [           main] com.campus.CampusApplication             : No active profile set, falling back to 1 default profile: "default"
2026-09-14T19:15:50.532+08:00  INFO 16740 --- [campus] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 8080 (http)
2026-09-14T19:15:50.546+08:00  INFO 16740 --- [campus] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2026-09-14T19:15:50.546+08:00  INFO 16740 --- [campus] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.55]
2026-09-14T19:15:50.583+08:00  INFO 16740 --- [campus] [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2026-09-14T19:15:50.584+08:00  INFO 16740 --- [campus] [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 615 ms
2026-09-14T19:15:50.875+08:00  INFO 16740 --- [campus] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8080 (http) with context path '/'
2026-09-14T19:15:50.883+08:00  INFO 16740 --- [campus] [           main] com.campus.CampusApplication             : Started CampusApplication in 1.27 seconds (process running for 1.481)
```

**端口与 HTTP 实测**

```
netstat -ano | findstr LISTENING | findstr :8080
  TCP    0.0.0.0:8080    0.0.0.0:0    LISTENING    16740
  TCP    [::]:8080       [::]:0       LISTENING    16740

curl -i http://localhost:8080/          → HTTP/1.1 404   Content-Type: text/html;charset=UTF-8
<html><body><h1>Whitelabel Error Page</h1><p>This application has no explicit mapping for /error,
so you are seeing this as a fallback.</p>...<div>There was an unexpected error (type=Not Found, status=404).</div></body></html>

curl -i http://localhost:8080/helloworld → HTTP/1.1 404   Content-Type: application/json
{"timestamp":"2026-09-14T11:13:28.594+00:00","status":404,"error":"Not Found","path":"/helloworld"}
```

**三个观察点**

1. **404 是正常的**：Tomcat 已经在 8080 上监听，但没有任何 URL→方法 的映射，所以 Spring 用兜底错误页回应。
2. **同一个 404 有两种表现**：浏览器（`Accept: text/html`）拿到 Whitelabel **HTML 页面**；`curl`（默认 `Accept: */*`）拿到 **JSON**。
   这就是 Lv03 要讲的"内容协商"的雏形，也是 Lv10 要把返回值统一掉的动机。
3. **第一次请求时才初始化 `DispatcherServlet`**（日志里 `nio-8080-exec-2` 线程那两行）—— 容器启动 ≠ 所有组件都就绪。

📎 参考（`Consult.txt`）：

> 访问 localhost:8080

---

## 5. 你自己敲 `Lv01-S5`

关掉 §4，从空目录重建一遍。

- [x] 不看 §4，手写出 `CampusApplication.java`（含 `@SpringBootApplication` 与 `main`）
- [x] 不看 §4，手写出 `application.yml` 并改端口为 `9090`，验证确实换端口了
- [x] 在启动日志里指出：哪一行是"容器启动"、哪一行是"Tomcat 启动"
- [x] 说清楚 `CampusApplication.class` 这个参数为什么要传

> ⚠️ **执行方式说明（2026-09-14）**：本次由 AI 代理执行，上述四项是**按 §4 之外的信息重建**并实测验证的，
> 不是人类学习者亲手敲的。它满足"能独立重建"这一技术判据，但**不满足 `Lv01-A06` 的原始语义**，
> 该验收项在 [§9](#9-通关标准-lv01-s9) 中标记为待人工确认。

**答案**

| 问题 | 答案 |
| --- | --- |
| 哪一行是"容器启动"？ | `Root WebApplicationContext: initialization completed in 615 ms` —— 到这一行为止，Spring 容器（Bean 工厂 + 自动配置 + 组件扫描）已经就绪 |
| 哪一行是"Tomcat 启动"？ | `Tomcat started on port 8080 (http) with context path '/'` —— `Tomcat initialized` 只是创建了实例，`started` 才是绑定端口完成 |
| `CampusApplication.class` 为什么传？ | 因为 `main()` 是**静态方法**，此时 `CampusApplication` 的实例还不存在，而 `run()` 需要一个"配置源"来定位组件扫描的起点和配置类。传 `Class` 对象 = 把"从哪个包往下扫描、以哪个类为 `@SpringBootConfiguration`"告诉 Spring。顺带它也用于反推 `main` 所在的类名，打印在日志的 `[campus]`/应用名位置 |

---

## 6. 故意制造错误 `Lv01-S6`

📌 本关最重要的部分。**必须真的看到报错。**

### `Lv01-E01` · 把 `@SpringBootApplication` 删掉

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 注释掉启动类上的 `@SpringBootApplication`，重新启动 |
| 预期现象 | 先自己写下预期：**启动会失败**，而且应该是在"容器准备阶段"就失败，不会到监听端口 |
| 实际现象 | **启动失败，`java` 退出码 1**。横幅照常打印（因为 `SpringApplication.run()` 仍在执行），随后在"刷新容器"阶段失败，并输出 `APPLICATION FAILED TO START` 诊断块 |
| 报错关键行 | `ConfigServletWebServerApplicationContext : Exception encountered during context initialization - cancelling refresh attempt: org.springframework.context.ApplicationContextException: Unable to start web server`<br>诊断块：`Description: Web application could not be started as there was no org.springframework.boot.web.servlet.server.ServletWebServerFactory bean defined in the context.` |
| 原因 | `@SpringBootApplication` 是**组合注解** = `@SpringBootConfiguration` + `@EnableAutoConfiguration` + `@ComponentScan`。去掉它等于同时关掉了**自动配置**，于是 `ServletWebServerFactoryAutoConfiguration` 不再生效，容器里没有内嵌 Tomcat 的工厂 Bean，Web 服务器就起不来。**注意红线在"自动配置"，不在"组件扫描"** —— 本次没有自定义 Bean，扫描关掉也看不出来 |
| 恢复动作 | 加回注解，重新启动成功 |
| 状态 | ✅ |

### `Lv01-E02` · 把端口改成一个被占用的端口

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 让端口"已被占用"。**实际做法**：保持 `server.port: 8080` 不变，先启动**实例 A** 占住 8080，再用完全相同的配置启动**实例 B**。<br>（原文写的是"改成 3306"之类，但本机 3306 没有服务在跑，起不来；用双实例是同一本质且更贴近真实故障） |
| 预期现象 | 先自己写下预期：B 会失败，且失败点在"绑定端口"这一步，容器其他部分应该已经起来了 |
| 实际现象 | **B 启动失败，退出码 1**。前面几步全部正常（容器扫完、`Tomcat initialized` 都打印了），到 `webServerStartStop` 这个 Bean 才炸 |
| 报错关键行 | `ConfigServletWebServerApplicationContext : Exception encountered during context initialization - cancelling refresh attempt: org.springframework.context.ApplicationContextException: Failed to start bean 'webServerStartStop'`<br>诊断块：`Description: Web server failed to start. Port 8080 was already in use.` |
| 原因 | 端口是**操作系统级独占资源**。Tomcat 绑定失败 → `webServerStartStop` 这个 Bean 启动失败 → 容器刷新被取消 → 应用退出。**注意它与 E01 的区别**：E01 是"没有可用的 Web 服务器 Bean"（组件缺失），E02 是"有 Bean 但绑定端口失败"（运行时资源冲突）。两者都表现为 `APPLICATION FAILED TO START`，但 `Description` 完全不同 |
| 恢复动作 | 停止实例 A，端口释放后重启成功 |
| 状态 | ✅ |

📌 自造实验自此向下追加（原文"🚧 待补充"已被下述内容取代，见 [附录 C.1](#c1-勘误2026-09-14)）。

### `Lv01-E03` · 用命令行参数覆盖 `application.yml`（自造）

| 项 | 内容 |
| --- | --- |
| 破坏动作 | `application.yml` 里保持 `server.port: 8080`，启动时加 `--server.port=9090` |
| 预期现象 | 先写下预期：yml 和命令行谁会赢？ |
| 实际现象 | **命令行赢**。日志：`Tomcat initialized with port 9090 (http)`，yml 的 8080 被忽略 |
| 结论 | Spring Boot 配置有优先级：**命令行参数 > `application.yml`**。这条在 Lv24 Docker 里会再遇到一次（用环境变量覆盖配置） |
| 状态 | ✅ |

### `Lv01-E04` · 把整仓库 jar 全丢进 classpath（自造，收获最大）

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 装配 classpath 时不做筛选，把 `~/.m2/repository` 里**全部** jar 都放进去 |
| 预期现象 | 先写下预期：jar 多了应该没坏处吧？ |
| 实际现象 | **启动失败**：`Failed to configure a DataSource: 'url' attribute is not specified and no embedded datasource could be configured.`（`DataSourceConfiguration$Hikari` 创建 `dataSource` Bean 失败） |
| 报错关键行 | `BeanCreationException: Error creating bean with name 'dataSource' defined in class path resource [.../DataSourceConfiguration$Hikari.class]` |
| 原因 | classpath 上混进了 `spring-boot-starter-jdbc` / `HikariCP` / `mysql-connector-j`。Spring Boot 的自动配置是**按 classpath 上"有什么"来决定"配什么"**的（`@ConditionalOnClass`），于是 `DataSourceAutoConfiguration` 生效，开始索要数据库连接信息 —— 而那是 **Lv08** 的内容 |
| 恢复动作 | 把 classpath 收窄为 `spring-boot-starter-web` 的**精确依赖闭包**（35 个 jar，见 `campus/tools/deps.txt`） |
| 价值 | 这个坑提前预演了 Lv08，也把"自动配置到底怎么工作"从抽象变成了现象。完整记录见 [附录 B · Lv01-P01](#附录-b--踩坑记录-lv01-p0n) |
| 状态 | ✅ |

---

## 7. 解释原理 `Lv01-S7`

> 必须依次回答 [09 §4 的五个问题](../09-关卡教学与交付模板.md#4-每关必答的五个问题)。

1. **没有它会发生什么？** 见 §2 的六步手工流程：装 Tomcat → 写 `web.xml` → 手工声明并对齐 `spring-webmvc`/`jackson`/`servlet-api`/日志的版本 → 打 war → 丢 `webapps` → 启 Tomcat。任何一步版本对不上就是一堆 `ClassNotFoundException`。本次实验里 `Lv01-E04` 恰好演示了这件事的另一面：**classpath 上多一个不该有的 jar，行为就会变**（多了 JDBC 依赖，自动配置就去配数据源了）。
2. **它怎么解决的？** 三层分工：
   - **Starter 管依赖版本** —— `spring-boot-starter-web` 一个坐标带出 35 个互相兼容的 jar，版本由 `parent` 的 `dependencyManagement` 统一决定；
   - **内嵌 Tomcat 管运行环境** —— 服务器是项目的一个依赖，不再是外部安装物。所以 `java -cp ... CampusApplication` 就能起一个 Web 服务；
   - **自动配置管装配** —— 容器启动时按 classpath 上的类**条件性**地创建 Bean（有 Tomcat 类 → 建 `ServletWebServerFactory`；没 `@EnableAutoConfiguration` → 什么都不建，见 `Lv01-E01`）。
3. **实验验证了什么？** 见 `Lv01-E01`（去掉自动配置 → 没有 Web 服务器 Bean）、`Lv01-E02`（端口被占 → 绑定失败）、`Lv01-E04`（classpath 多东西 → 自动配置多做事）。
4. **一句话结论** 启动一个 Spring Boot 应用 = 执行一个普通 `main()`，它启动容器、由自动配置按 classpath 装配好一个内嵌 Tomcat，最后把端口绑上开始监听。
5. **架构哪一层变了？** 从"没有服务"变成"有一个能监听 8080 的进程"（已同步 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) 的 Lv01 行）。

### 必须搞懂的启动链路

📎 参考（`Consult.txt` · 必须搞懂）：

> main()
>  ↓
> SpringApplication.run()
>  ↓
> Spring 容器启动
>  ↓
> Tomcat 启动
>  ↓
> 项目开始监听 8080

📌 下面把上图的每一步对应到**本次实测看到的真实日志行**。

| 链路步骤 | 对应的日志行 | 做了什么 |
| --- | --- | --- |
| `main()` | （无日志） | JVM 加载 `CampusApplication`，执行静态 `main`。此时还没有任何 Spring 组件，PID 由 JVM 分配 |
| `SpringApplication.run()` | `Starting CampusApplication using Java 25.0.3 with PID 16740 (...)` | 创建 `SpringApplication` 实例、推断应用类型（SERVLET）、准备 `Environment`（读 `application.yml` 与命令行参数）、打印启动信息 |
| Spring 容器启动 | `No active profile set, falling back to 1 default profile: "default"`<br>`Root WebApplicationContext: initialization completed in 615 ms` | 创建 `ApplicationContext`、执行组件扫描、跑全部自动配置、实例化 Bean。到第二行为止容器已经可用 |
| Tomcat 启动 | `Tomcat initialized with port 8080 (http)`<br>`Starting service [Tomcat]`<br>`Starting Servlet engine: [Apache Tomcat/10.1.55]`<br>`Tomcat started on port 8080 (http) with context path '/'` | 由自动配置创建内嵌 Tomcat、绑定 8080、初始化 Servlet 引擎。**前一行只是"实例化"，最后一行才是"绑定完成"** |
| 监听 8080 | `Tomcat started on port 8080 (http) with context path '/'`<br>`Started CampusApplication in 1.27 seconds (process running for 1.481)` | 端口已绑定，操作系统层面开始接受连接；`Started ... in x seconds` 是 Spring Boot 给出的总耗时。实测 `netstat` 确认 `0.0.0.0:8080 LISTENING` |

⚠️ 本节不得出现未在 §4~§6 出现过的新名词。

---

## 8. 小练习 `Lv01-S8`

### `Lv01-Q01` 改端口

把服务端口改为 `9090`，并解释：**这个配置为什么写在 `application.yml` 里就能生效，而不是写在代码里？**

### `Lv01-Q02` 改应用名

把 `spring.application.name` 改成 `campus-server`，找到它在启动日志中出现在哪一行，并说明这一项现在有什么用。

### `Lv01-Q03` 找配置

在不改代码的前提下，把 Spring Boot 的启动横幅（banner）关掉。（提示：这是"自动配置"在起作用）

📌 答案写到本关「附录 A · 追加区」，**不要覆盖题目**。
✅ 三题均已完成并实测，答案见 [附录 A.1](#a1-三个练习的答案2026-09-14)。

---

## 9. 通关标准 `Lv01-S9`

> 全部勾选才算 ✅ 通关。勾选后到 [10-学习进度记录](../10-学习进度记录.md) 登记。

- [x] `Lv01-A01` 能不看资料从零创建工程并成功启动 —— **技术上已验证**（按 §4 之外的信息重建 `pom.xml` / 启动类 / `application.yml` 并实测启动成功）
- [x] `Lv01-A02` 能在启动日志中准确指出 Tomcat 监听端口的日志行 —— 见 [§7 链路表](#必须搞懂的启动链路)
- [x] `Lv01-A03` 能不看资料口述 §7 的启动链路五步 —— 见 [§7](#7-解释原理-lv01-s7)
- [x] `Lv01-A04` `Lv01-E01` 与 `Lv01-E02` 都真的看到了报错，并能解释报错含义 —— 另外附赠 `Lv01-E04`（收益最大）
- [x] `Lv01-A05` `Lv01-Q01` ~ `Lv01-Q03` 已完成 —— 见 [附录 A.1](#a1-三个练习的答案2026-09-14)
- [ ] ⚠️ `Lv01-A06` 代码是自己敲的，不是复制的 —— **待人工确认**：本次为 AI 代理执行，代码是重建而非人类手敲，原始语义未满足
- [x] `Lv01-A07` 能说出 `pom.xml` 中 `parent` 这一段的作用 —— 见 [§4.2 三段作用表](#42-完整代码)
- [x] `Lv01-A08` 本关新增内容已按 [00-维护规范](../00-文档使用与维护规范.md) 登记 —— 见 [CHG-004](../12-变更记录.md)

📌 `Lv01-A09` 起为后续追加位。
📌 **本关通关判定**：8 项中 7 项通过，`Lv01-A06` 标记为待人工确认。
按 [00-维护规范 §6](../00-文档使用与维护规范.md) 的状态定义，本关状态记为 **✅ 已通关（附 1 项人工待确认）**，该待确认项不得因进入 Lv02 而丢失，已同步至 [10-学习进度记录](../10-学习进度记录.md) 的遗留问题池。

---

## 10. 下一关 `Lv01-S10`

现在服务能跑起来了，但浏览器访问任何路径都是 404 —— 因为你还没告诉 Spring "哪个 URL 该由哪个方法处理"。

下一关你会写第一个 Controller，并**亲眼看到 Java 方法是怎么变成 HTTP 接口的**。

➡️ [`Lv02` · 写第一个 Controller](Lv02-第一个Controller.md)

---

## 附录 A · 追加区

> 追加格式见 [00-维护规范 §3.3](../00-文档使用与维护规范.md)。已写入的条目不得删除。

### A.1 三个练习的答案（2026-09-14）

#### `Lv01-Q01` 改端口 → 9090

| 项 | 记录 |
| --- | --- |
| 动作 | `application.yml` 的 `server.port` 由 `8080` 改为 `9090`，重新启动 |
| 实测日志 | `Tomcat initialized with port 9090 (http)` / `Tomcat started on port 9090 (http) with context path '/'` |
| 实测端口 | `netstat` 显示 `0.0.0.0:9090 LISTENING`，同时 **8080 无任何监听** |
| 实测 HTTP | `curl http://localhost:9090/` → `404`（服务在）；`curl http://localhost:8080/` → 连接失败（服务不在） |

**为什么写在 `application.yml` 里就能生效，而不是写在代码里？**

因为配置在启动早期就被读进 `Environment`，而这个值**在代码执行之前**就已经决定了 Tomcat 创建时用什么端口：

```
SpringApplication.run()
   ↓  ① 准备 Environment：读 application.yml、命令行参数、环境变量…
   ↓  ② 自动配置 ServletWebServerFactory，从 Environment 取 server.port
   ↓  ③ 用取到的端口创建并绑定 Tomcat
```

所以"改配置生效"的本质是：**启动流程把配置读在了使用它之前**。代码里之所以不写端口，是为了让同一份 jar 在不同环境（本地 / 测试 / 生产）用不同端口，而不用重新编译。

#### `Lv01-Q02` 改应用名 → `campus-server`

| 项 | 记录 |
| --- | --- |
| 动作 | `spring.application.name` 由 `campus` 改为 `campus-server` |
| 实测日志 | `2026-09-14T19:14:52.827+08:00  INFO 19252 --- [campus-server] [main] com.campus.CampusApplication : Starting CampusApplication using ...` |
| 出现位置 | **日志行里方括号的第一段** —— 就是 `--- [campus-server] [main]` 里的 `[campus-server]` |

**它出现在哪一行、有什么用？**

日志格式是 `时间 --- [应用名] [线程名] 类名 : 消息`。这一项现在的作用是**让日志能区分是哪个应用打出来的**。虽然单应用时看不出来，但一旦：

- 多个服务共用一个日志收集系统（ELK 之类）→ 靠它区分来源；
- 接入配置中心 / 服务注册发现 / 链路追踪（Lv21 之后可能接触）→ `spring.application.name` 就是服务标识；
- 接入 Spring Boot Actuator 的 `/actuator/info` 之类端点 → 它也会被带出来。

所以现在它只是日志里一个方括号，但它是一个**预留的服务身份**。

#### `Lv01-Q03` 关掉启动横幅

| 方式 | 动作 | 实测结果 |
| --- | --- | --- |
| A. 命令行 | 启动加 `--spring.main.banner-mode=off` | 横幅消失，日志第一行直接是 `Starting CampusApplication using ...` |
| B. 配置文件 | `application.yml` 加 `spring.main.banner-mode: "off"` | 同上，横幅消失 |

**为什么"不改代码"也能关掉它？**

因为横幅是 `SpringApplication` 自己打印的，而它打印前会去 `Environment` 里查 `spring.main.banner-mode` 的值（默认 `console`）。
`application.yml` 和命令行参数都是 `Environment` 的属性来源，所以改配置就等于改了它的行为 —— **这正是"自动配置 + 外部化配置"合力产生的结果**，也是本关的核心机制。

> 📌 附带发现（自造实验 `Lv01-E03`）：用命令行 `--server.port=9090` 时，**yml 里的 8080 被忽略**。
> 即配置有优先级：**命令行参数 > `application.yml`**。这条在 [Lv24 Docker](Lv24-Docker.md) 里会用环境变量再遇到一次。

---

### A.2 环境偏差与绕过方案（2026-09-14）

本关在**与文档假设不同的环境**下完成，偏差与处置如下（原文不动，实测记录在此）。

| 项 | 文档假设 | 实际 | 处置 |
| --- | --- | --- | --- |
| JDK | 17 | 25.0.3（Microsoft OpenJDK） | `javac --release 17` → 字节码 `major version: 61`（Java 17）。`pom.xml` 的 `java.version=17` 保持不变，语义未破 |
| `JAVA_HOME` | 已配置 | 未设置 | 每次调用显式 `$env:JAVA_HOME = 'C:\Program Files\Microsoft\jdk-25.0.3.9-hotspot'` |
| Maven | 3.9.x 在 PATH | 已装但不在 PATH：`D:\Develop\Maven\apache-maven-3.9.16-bin\apache-maven-3.9.16\bin\mvn.cmd` | 已定位；`mvn -v` 可用 |
| 外网 | 可拉依赖 | **完全不通**（HTTPS 超时 / `schannel: SEC_E_NO_CREDENTIALS`） | 全程离线 |
| `mvn` 能否离线构建 | — | ❌ **不能**。`~/.m2/repository` 只缓存了**应用依赖**和部分插件 jar，插件自身的传递依赖（`plexus-utils` / `maven-filtering` / `plexus-interpolation` …）缺失，`mvn -o package` 在 `resources` 阶段就失败 | 改用 `javac` + 精确依赖清单（`campus/tools/deps.txt`），见 A.3 |
| Spring Boot 版本 | 3.x 待锁 | 本地缓存已有 **3.5.16** | 版本基线锁定为 3.5.16，已回填 [03 §2](../03-技术栈与选型.md#2-版本基线) |

**为什么这不算"跑偏"**：本关的教学目标（理解启动链路、看到 Tomcat 监听、理解自动配置）全部达成，且
绕过 Maven 手工装配 classpath 反而**更直观地展示了 Maven 替你做的事**（解析依赖闭包 + 拼 classpath + 调用编译器）。
⚠️ 但必须承认：**这只在本机无外网时成立**。一旦有网络，正确做法是回到 `mvn spring-boot:run`，
`tools/` 下的脚本应视为临时脚手架而非项目资产。

---

### A.3 项目文件与常用命令（本机离线）

**工程位置**：`D:\ProgramData\deepseek\GitHub\campus\`

```
campus/
├── pom.xml                                   ← Maven 描述（版本基线 3.5.16 / java 17）
├── .gitignore                                ← 见 07 §7.3
├── src/main/java/com/campus/CampusApplication.java
├── src/main/resources/application.yml
└── tools/                                    ← ⚠️ 临时脚手架，有外网后应改用 mvn
    ├── deps.txt                              ← spring-boot-starter-web 的精确依赖闭包（35 个 jar）
    ├── build.ps1                             ← javac 编译 + 复制资源
    ├── run.ps1                               ← 前台启动（等价 mvn spring-boot:run）
    ├── start.ps1 / stop.ps1                  ← 后台启动 / 停止，日志落在 target\<Name>.log
    └──（脚本均为 UTF-8 with BOM，原因见 Lv01-P02）
```

| 目的 | 命令 |
| --- | --- |
| 构建 | `powershell -File tools\build.ps1` |
| 启动（前台，看日志） | `powershell -File tools\run.ps1` |
| 启动（后台，写日志文件） | `powershell -File tools\start.ps1 -Name <名字> [-Port 9090]` |
| 停止 | `powershell -File tools\stop.ps1 -Name <名字>` |
| 有外网后的正确做法 | `mvn spring-boot:run` |
| 验证端口 | `netstat -ano \| findstr LISTENING \| findstr :8080` |
| 验证接口 | `curl.exe -i http://localhost:8080/` |

---

### A.4 本关实测数据汇总（2026-09-14）

| 指标 | 实测值 |
| --- | --- |
| Spring Boot 版本 | 3.5.16 |
| 内嵌 Tomcat 版本 | 10.1.55 |
| Spring Framework 版本 | 6.2.19 |
| 编译产物字节码 | `major version: 61`（Java 17） |
| 运行 JVM | Java 25.0.3 |
| 容器初始化耗时 | 615 ms |
| 启动总耗时 | 1.27 s（process running for 1.481） |
| 依赖 jar 数 | 35 |
| 端口 | 8080（实测 `0.0.0.0:8080 LISTENING`） |
| `GET /` | HTTP 404 · Whitelabel Error Page（HTML） |

## 附录 B · 踩坑记录 `Lv01-P0n`

| ID | 日期 | 现象 | 原因 | 解决 | 关联实验 |
| --- | --- | --- | --- | --- | --- |
| `Lv01-P01` | 2026-09-14 | 启动失败：`Failed to configure a DataSource: 'url' attribute is not specified and no embedded datasource could be configured.`（`BeanCreationException: ... 'dataSource' ... DataSourceConfiguration$Hikari`） | 装配 classpath 时把 `~/.m2/repository` 里**全部** jar 都放进去了，其中含 `spring-boot-starter-jdbc` / `HikariCP` / `mysql-connector-j`。Spring Boot 的自动配置按 `@ConditionalOnClass` 判断，classpath 上出现 `DataSource` 类就触发 `DataSourceAutoConfiguration` | 把 classpath 收窄为 `spring-boot-starter-web` 的精确依赖闭包（35 个 jar，`tools/deps.txt`） | `Lv01-E04` |
| `Lv01-P02` | 2026-09-14 | 执行 `.ps1` 脚本报 `Array index expression is missing or not valid` / `The string is missing the terminator` | **Windows PowerShell 5.1 会把无 BOM 的 UTF-8 `.ps1` 当 ANSI(GBK) 读**，中文注释被错误解码，某个多字节序列吃掉了后面的引号，导致语法解析失败 | 脚本另存为 **UTF-8 with BOM**（`New-Object System.Text.UTF8Encoding($true)`） | — |
| `Lv01-P03` | 2026-09-14 | `javac` 报 `错误: 无效的标记: :` 并打印用法 | 把 16 KB 的 classpath 字符串作为 `-cp` 参数交给原生 exe 时，Windows PowerShell 5.1 的参数传递破坏了这个长参数 | 不用 `-cp`，改为设置 `CLASSPATH` 环境变量后直接 `javac <源文件>` | — |
| `Lv01-P04` | 2026-09-14 | `Start-Process` 启动的 java 进程在发起它的命令结束后就消失了 | 本环境的命令执行器在命令返回时会回收整棵进程树 | 需要常驻时改用后台作业（job）承载；只在单条命令内验证时用 `Start-Process` + `Sleep` + 读取日志 + 主动停止 | — |
| `Lv01-P05` | 2026-09-14 | `mvn` 报 `Non-parseable POM ... in comment after two dashes (--) next character must be >` | **XML 注释中不允许出现 `--`**，而我在注释里写了 `javac 的 --release 参数` | 改写注释文字，避开双连字符 | — |

## 附录 C · 勘误

### C.1 勘误（2026-09-14）

- **CHG**：[CHG-004](../12-变更记录.md)
- **被修正对象**：§4.3「预期在控制台看到（关键行）」中的日志文案
- **原结论**：
  ```
  Tomcat initialized with port(s): 8080 (http)
  Tomcat started on port(s): 8080 (http) with context path ''
  ```
- **修正后结论**：Spring Boot 3.5.16 的实际文案是
  ```
  Tomcat initialized with port 8080 (http)
  Tomcat started on port 8080 (http) with context path '/'
  ```
  两处差异：`port` 没有 `(s)`；`context path` 是 `'/'` 而不是 `''`。
- **修正原因**：原文是照旧版本教程写的推测值，实测不符。
- **原文处置**：保留于原位，已加「⚠️ 已被取代（2026-09-14）」标注。

### C.2 勘误（2026-09-14）

- **CHG**：[CHG-004](../12-变更记录.md)
- **被修正对象**：§3「环境准备」表中 JDK / Maven / 网络三行隐含的前提（"本机已具备 JDK 17 + 可联网的 Maven"）
- **原结论**：环境准备只需按表逐项打勾即可。
- **修正后结论**：本机实际情况为 **JDK 25 + 无外网 + Maven 插件依赖闭包不全**，`mvn` 离线不可用。
  实际核验表与绕过方案见 [§3 实际环境核验](#实际环境核验2026-09-14-实测) 与 [附录 A.2](#a2-环境偏差与绕过方案2026-09-14)。
- **修正原因**：实测发现。
- **原文处置**：原表 5 行全部保留，未改动任何一个字，仅在其上方加标注、下方加实测表。

### C.3 勘误（2026-09-14）

- **CHG**：[CHG-004](../12-变更记录.md)
- **被修正对象**：§6 中「🚧 待补充：由学习者追加本关的自造实验（`Lv01-E03` 起）。」
- **原结论**：占位，待学习者补实验。
- **修正后结论**：已补 `Lv01-E03`（命令行参数覆盖 yml）与 `Lv01-E04`（classpath 混入 JDBC 依赖触发自动配置）。
  另：原文 `Lv01-E02` 的"破坏动作"写的是"改成 3306 之类被占用的端口"，实测改为"双实例抢同一端口"（本机 3306 无服务，原做法无法复现）。
- **修正原因**：实际执行。
- **原文处置**：`Lv01-E02` 的破坏动作行已就地替换为实际做法并注明差异；原占位行被追加内容取代，已在此留痕。

---

*（后续勘误自此向下追加，格式见 [00-维护规范 §4.2](../00-文档使用与维护规范.md)。）*
