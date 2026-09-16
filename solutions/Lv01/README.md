# Lv01 参考解 · 让 Spring Boot 跑起来

> **冻结日期**：2026-09-15 ｜ **git tag**：`lv01-pass`
> **对应讲义**：[`docs/levels/Lv01-SpringBoot启动.md`](../../docs/levels/Lv01-SpringBoot启动.md)
> **验收标准**：与讲义 §9 完全一致（`Lv01-A01` ~ `Lv01-A08`）

> # ⚠️ 先看这个再往下
>
> 如果你还没亲手做过讲义 §6 的实验（删掉 `@SpringBootApplication` 看报错），
> **现在关掉这个文件**。那一关的全部价值就在于你亲眼看到那个报错。
>
> 使用规则见 [`solutions/README.md` §3](../README.md#3-使用规则硬约定)。

---

## 1. 这一关做了什么

一句话：**让一个普通 Java 类变成一个能监听 8080 的 Web 服务。**

具体三件事：

| # | 做了什么 | 结果 |
| --- | --- | --- |
| 1 | 用 Maven + Spring Boot Starter 声明依赖 | 一个坐标带出 35 个互相兼容的 jar，不用手写版本 |
| 2 | 写启动类 `@SpringBootApplication` + `main()` | 容器启动，自动配置按 classpath 装配出一个内嵌 Tomcat |
| 3 | 用 `application.yml` 配置端口与应用名 | 端口 `8080`、应用名 `campus`，改配置即生效，不用改代码 |

**实测结果**（真实日志，非预期值）：

```
Tomcat initialized with port 8080 (http)
Tomcat started on port 8080 (http) with context path '/'
Started CampusApplication in 1.24 seconds
0.0.0.0:8080  LISTENING
GET /  →  HTTP 404  Whitelabel Error Page
```

📌 **404 是正常的** —— 服务已经在跑了，只是还没有任何 URL→方法 的映射。那是 Lv02 的事。

---

## 2. 本关增量文件

⚠️ **Lv01 是起点，所以"增量"就是工程骨架的全部**。
此刻 `solutions/Lv01/campus/` 与仓库根的 `campus/` **内容完全相同** —— 这是正常的，
**从 Lv02 起两者开始分叉**（`campus/` 继续长，`solutions/Lv01/` 冻结不动）。

```
solutions/Lv01/campus/
├── pom.xml                                          工程描述：parent 3.5.16 / java 17 / 三个依赖
├── .gitignore                                       构建产物与敏感配置不入库
├── src/main/java/com/campus/CampusApplication.java  启动类（8 行，全项目的入口）
├── src/main/resources/application.yml               端口 8080 / 应用名 campus
└── tools/                                           ⚠️ 临时脚手架，非项目资产
    ├── deps.txt                                     spring-boot-starter-web 的 35 个依赖 jar 清单
    ├── build.ps1                                    javac 编译 + 复制资源
    ├── run.ps1                                      前台启动（等价 mvn spring-boot:run）
    ├── start.ps1 / stop.ps1                         后台启动 / 停止
```

### 每个文件的重点

**`pom.xml`** —— 只需要看懂三段：

| 段 | 作用 |
| --- | --- |
| `<parent>` | 版本仲裁中心。它的父 POM 用 `<dependencyManagement>` 预声明了几乎所有依赖版本，所以下面的 Starter **不写版本号** |
| `<java.version>17</java.version>` | 被 parent 映射为 `maven.compiler.release`，决定字节码版本（实测 `major version: 61`） |
| `spring-boot-starter-web` | 依赖打包入口。一个坐标 → 35 个 jar（spring-web / spring-webmvc / 内嵌 Tomcat / Jackson / 日志…） |

**`CampusApplication.java`** —— 全部内容：

```java
@SpringBootApplication
public class CampusApplication {
    public static void main(String[] args) {
        SpringApplication.run(CampusApplication.class, args);
    }
}
```

- `@SpringBootApplication` = `@SpringBootConfiguration` + `@EnableAutoConfiguration` + `@ComponentScan`
  → 删掉它，自动配置就关了，容器里没有 `ServletWebServerFactory`，**Web 服务器起不来**（见 §4）
- `CampusApplication.class` 这个参数：`main` 是静态方法，此时还没有实例，而 `run()` 需要一个"配置源"
  来定位组件扫描的起点。传 `Class` 对象 = 告诉 Spring 从哪个包往下扫

**`application.yml`** —— 为什么写在配置里就能生效：

```
SpringApplication.run()
   ↓  ① 准备 Environment：读 application.yml、命令行参数、环境变量
   ↓  ② 自动配置 ServletWebServerFactory 时，从 Environment 取 server.port
   ↓  ③ 用取到的端口创建并绑定 Tomcat
```

配置读在**使用它之前**，所以改 yml 就能改行为，同一份 jar 可以在不同环境用不同端口。

**`tools/`** —— 这是**环境补丁，不是项目资产**。
本机无外网、只有 JDK 25，`mvn` 离线不可用（插件传递依赖缺失），所以用 `javac` + 精确 classpath 绕过。
有外网后应删除，回到 `mvn spring-boot:run`。原因详见讲义附录 A.2。

---

## 3. 怎么独立验证这一关

```powershell
cd solutions\Lv01\campus        # 或者用仓库根的 campus\
powershell -File tools\build.ps1
powershell -File tools\start.ps1 -Name lv01
Start-Sleep 12
# ① 看日志关键行
Select-String -Path target\lv01.log -Pattern 'Tomcat started|Started CampusApplication'
# ② 看端口
netstat -ano | findstr LISTENING | findstr :8080
# ③ 看 HTTP
curl.exe -i http://localhost:8080/
powershell -File tools\stop.ps1 -Name lv01
```

**验收对照**（讲义 §9，全部通过即通关）：

| 项 | 判定依据 |
| --- | --- |
| `Lv01-A01` 能独立创建并启动 | 上面三步全绿 |
| `Lv01-A02` 能指出监听端口的日志行 | `Tomcat started on port 8080 (http) with context path '/'` |
| `Lv01-A03` 能口述启动链路五步 | 见 §5 |
| `Lv01-A04` 两个实验都看到报错 | 见 §4 |
| `Lv01-A05` 三个练习已完成 | 见 §6 |
| `Lv01-A06` **代码是自己敲的** | ⚠️ 看过参考解后必须关掉它重敲一遍 |
| `Lv01-A07` 能说出 `parent` 的作用 | 见 §2 的 `pom.xml` 表 |
| `Lv01-A08` 已按维护规范登记 | 讲义附录 A + `CHG-004` |

---

## 4. 实验对照（讲义 §6）

这一关的真正内容。**如果这四个实验你只看了结论没亲手做，这一关等于没学。**

### `Lv01-E01` · 注释掉 `@SpringBootApplication`

```
WARN  ConfigServletWebServerApplicationContext : Exception encountered during context initialization
      - cancelling refresh attempt: org.springframework.context.ApplicationContextException: Unable to start web server
ERROR o.s.b.d.LoggingFailureAnalysisReporter :

***************************
APPLICATION FAILED TO START
***************************

Description:

Web application could not be started as there was no
org.springframework.boot.web.servlet.server.ServletWebServerFactory bean defined in the context.
```

**根因**：`@SpringBootApplication` 里的 `@EnableAutoConfiguration` 被去掉了
→ `ServletWebServerFactoryAutoConfiguration` 不生效
→ 容器里没有内嵌 Tomcat 的工厂 Bean → Web 服务器起不来。

⚠️ 注意红线在**自动配置**，不在**组件扫描**。当时没有自定义 Bean，扫描关掉也看不出来。

### `Lv01-E02` · 端口被占用

```
WARN  ConfigServletWebServerApplicationContext : Exception encountered during context initialization
      - cancelling refresh attempt: org.springframework.context.ApplicationContextException:
      Failed to start bean 'webServerStartStop'

Description:

Web server failed to start. Port 8080 was already in use.
```

**与 E01 的区别**：E01 是"没有可用的 Web 服务器 Bean"（组件缺失），
E02 是"有 Bean 但绑定端口失败"（运行时资源冲突）。两者都报 `APPLICATION FAILED TO START`，
但 `Description` 完全不同 —— **读报错要读到 `Description` 这一层**。

### `Lv01-E03`（自造）· 命令行参数覆盖 yml

`application.yml` 写 `8080`，启动加 `--server.port=9090` → **命令行赢**。
配置优先级：**命令行参数 > `application.yml`**。Lv24 Docker 会用环境变量再遇到一次。

### `Lv01-E04`（自造，收益最大）· classpath 混入多余依赖

不做筛选、把整个本地仓库的 jar 都丢进 classpath →

```
BeanCreationException: Error creating bean with name 'dataSource' defined in class path resource
[.../DataSourceConfiguration$Hikari.class]:
Failed to instantiate [com.zaxxer.hikari.HikariDataSource]:
Factory method 'dataSource' threw exception with message: Failed to determine a suitable driver class
```

**根因**：classpath 上混进了 `spring-boot-starter-jdbc` / `HikariCP` / `mysql-connector-j`。
Spring Boot 的自动配置是**按 classpath 上"有什么"来决定"配什么"**的（`@ConditionalOnClass`），
于是 `DataSourceAutoConfiguration` 生效，开始索要数据库连接信息 —— 而那是 **Lv08** 的内容。

📌 **这个坑把"自动配置到底怎么工作"从抽象变成了现象。**

---

## 5. 启动链路 ↔ 真实日志行

| 链路步骤 | 真实日志行 | 做了什么 |
| --- | --- | --- |
| `main()` | （无日志） | JVM 加载类，执行静态 `main`。还没有任何 Spring 组件 |
| `SpringApplication.run()` | `Starting CampusApplication using Java 25.0.3 with PID 16740 (...)` | 创建 `SpringApplication`、推断应用类型、准备 `Environment` |
| Spring 容器启动 | `Root WebApplicationContext: initialization completed in 615 ms` | 建容器、组件扫描、跑自动配置、实例化 Bean |
| Tomcat 启动 | `Tomcat initialized with port 8080 (http)` → `Starting service [Tomcat]` → `Starting Servlet engine: [Apache Tomcat/10.1.55]` → `Tomcat started on port 8080 (http) with context path '/'` | **前一行只是实例化，最后一行才是绑定完成** |
| 监听 8080 | `Started CampusApplication in 1.27 seconds` | 端口已绑定，开始接受连接 |

---

## 6. 练习答案（讲义 §8）

### `Lv01-Q01` 改端口 → 9090

改 `application.yml` 的 `server.port: 9090` →
日志变 `Tomcat started on port 9090`，`netstat` 显示 9090 在听，**8080 无监听**。

**为什么写配置就生效**：见 §2 的 `application.yml` 说明 —— 配置读在用它之前。

### `Lv01-Q02` 改应用名 → `campus-server`

改 `spring.application.name` → 日志行变成：

```
INFO 19252 --- [campus-server] [main] com.campus.CampusApplication : Starting CampusApplication ...
                    ↑ 就是这里
```

日志格式是 `时间 --- [应用名] [线程名] 类名 : 消息`。
**它的作用**：多服务共用一个日志系统时区分来源；接入配置中心 / 服务注册 / 链路追踪时作为服务标识。
现在只是日志里一个方括号，但它是**预留的服务身份**。

### `Lv01-Q03` 关掉启动横幅

两种方式都实测有效：

| 方式 | 做法 |
| --- | --- |
| 命令行 | 启动加 `--spring.main.banner-mode=off` |
| 配置文件 | `application.yml` 加 `spring.main.banner-mode: "off"` |

**为什么"不改代码"也能关**：横幅是 `SpringApplication` 自己打印的，打印前会去 `Environment` 查
`spring.main.banner-mode`。`application.yml` 和命令行都是 `Environment` 的属性来源 ——
**这正是"自动配置 + 外部化配置"合力的结果**。

---

## 7. 下一关会怎么变

Lv02 会在 `campus/` 下**新增**一个文件：

```
campus/src/main/java/com/campus/controller/HelloController.java
```

让 `GET /hello` 返回 `Hello Spring Boot`。
`solutions/Lv02/campus/` 里只会放这一个文件（+ 一份 README），不会复制整份工程。

➡️ 讲义：[`docs/levels/Lv02-第一个Controller.md`](../../docs/levels/Lv02-第一个Controller.md)
