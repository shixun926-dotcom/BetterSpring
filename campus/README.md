# campus · 校园综合管理系统（后端）

> Spring Boot 3.5.16 ｜ Java 17（编译目标） ｜ 端口 8080
> 当前进度：**Lv01 · 让 Spring Boot 跑起来 ✅**
> 项目文档集在 [`../docs/`](../docs/README.md)，本文件只讲**怎么把工程跑起来**。
> 仓库：<https://github.com/shixun926-dotcom/BetterSpring>

---

## 1. 当前状态

| 项 | 状态 |
| --- | --- |
| 工程骨架 | ✅ `pom.xml` / `CampusApplication` / `application.yml` |
| 启动 | ✅ 实测 `Started CampusApplication in 1.27 seconds`，`0.0.0.0:8080 LISTENING` |
| 业务接口 | ⬜ 无（`GET /` 返回 404 是正常的，Lv02 才有第一个接口） |
| 数据库 / Redis / MQ | ⬜ 未接入（分别从 Lv08 / Lv13 / Lv22 开始） |

---

## 2. ⚠️ 本机环境的特殊说明（重要）

**本项目当前**在这台机器上**不能**用 `mvn spring-boot:run` 启动，原因有两条：

1. 本机**无外网**，而 `~/.m2/repository` 只缓存了应用依赖，Maven **插件自身的传递依赖不全**，
   `mvn -o package` 会在 `resources` 阶段就失败；
2. 本机只装了 **JDK 25**（无 JDK 17），`JAVA_HOME` 也未设置。

因此 `tools/` 下有一套**临时脚手架**，用 JDK 自带的 `javac` + 精确 classpath 完成构建与启动。

> 📌 **`tools/` 不是项目资产，是环境补丁。**
> 一旦在有外网、有 JDK 17 的机器上开发，应删除整个 `tools/` 目录，回到标准 Maven 流程。
> 完整的环境偏差记录见 [`../docs/levels/Lv01-SpringBoot启动.md`](../docs/levels/Lv01-SpringBoot启动.md) 附录 A.2。

---

## 3. 目录结构

```
campus/
├── pom.xml                                       Maven 描述（parent 3.5.16 / java.version 17）
├── .gitignore
├── README.md                                     本文件
├── src/main/java/com/campus/
│   └── CampusApplication.java                    启动类（@SpringBootApplication + main）
├── src/main/resources/
│   └── application.yml                           server.port=8080 / spring.application.name=campus
└── tools/                                        ⚠️ 临时脚手架（有外网后应删除）
    ├── deps.txt                                  spring-boot-starter-web 的 35 个依赖 jar
    ├── build.ps1                                 javac 编译 + 复制资源到 target/classes
    ├── run.ps1                                   前台启动（等价 mvn spring-boot:run）
    ├── start.ps1                                 后台启动，日志写 target/<Name>.log
    └── stop.ps1                                  停止
```

---

## 4. 怎么跑（本机）

```powershell
# ① 构建
powershell -File tools\build.ps1

# ② 前台启动（日志直接打在控制台，Ctrl+C 停止）
powershell -File tools\run.ps1

# 或者后台启动
powershell -File tools\start.ps1 -Name dev
powershell -File tools\stop.ps1  -Name dev

# ③ 验证
curl.exe -i http://localhost:8080/
#   → HTTP/1.1 404 + Whitelabel Error Page，说明服务已经在跑，只是还没有任何接口
```

### 有外网时（推荐）

```bash
mvn spring-boot:run
mvn clean package && java -jar target/campus-0.0.1-SNAPSHOT.jar
```

---

## 5. 常见问题

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `Port 8080 was already in use` | 端口被占 | `tools\stop.ps1`，或 `netstat -ano \| findstr :8080` 找到进程后结束它 |
| `APPLICATION FAILED TO START` + `no ServletWebServerFactory bean` | `@SpringBootApplication` 被注释/删除 | 加回注解（见 Lv01 实验 E01） |
| `Failed to configure a DataSource` | classpath 上混进了 JDBC / 驱动依赖 | 检查 `tools/deps.txt` 是否被加料（见 Lv01 实验 E04） |
| `tools\*.ps1` 报语法错乱 | 脚本被存成了**无 BOM** 的 UTF-8，PowerShell 5.1 会按 ANSI 读 | 另存为 **UTF-8 with BOM** |
| `javac` 报 `无效的标记: :` | 用 `-cp` 传了超长 classpath 字符串 | 改用 `CLASSPATH` 环境变量（`tools/build.ps1` 已是如此） |

---

## 6. 下一步

**Lv02 · 写第一个 Controller** —— 让 `GET /hello` 返回 `Hello Spring Boot`。
讲义：[`../docs/levels/Lv02-第一个Controller.md`](../docs/levels/Lv02-第一个Controller.md)
