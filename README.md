# BetterSpring

> **用 25 关闯关路线，从 0 走到一个真正能跑的后端项目。**
>
> 这不是一份「Spring Boot 知识目录」，而是一条**每学一个知识点都能立刻看到它解决了什么问题**的实战路线。
> 每完成一关，项目里就多一样能跑起来的东西。

当前进度：**Lv01 ✅ / 共 25 关**

```bash
git clone https://github.com/shixun926-dotcom/BetterSpring.git
cd BetterSpring
```

---

## 这个仓库是什么

两件事放在一起：

| 目录 | 内容 |
| --- | --- |
| [`campus/`](campus/) | **可运行的 Spring Boot 工程** —— 校园综合管理系统（后端） |
| [`docs/`](docs/README.md) | **项目文档集** —— 需求、架构、数据库、接口、规范，以及 25 关的完整讲义 |
| [`Consult.txt`](Consult.txt) | 路线原始来源（对话记录），已整理进 `docs/` |

最终形态：

```
校园综合管理系统
├── 用户     注册 / 登录 / JWT / 权限
├── 学生     CRUD / 分页 / 查询 / 头像
├── 课程     CRUD / 选课
├── 成绩     查询 / 修改 / 统计
└── 管理员   用户管理 / 学生管理 / 权限管理
```

技术栈：Java 17 · Spring Boot 3.5.16 · Spring MVC · MyBatis · MySQL · Redis · JWT · Maven · Lombok · Postman · Git
（后续关卡还会引入 Spring Security、RabbitMQ、WebSocket、Docker、Vue3）

---

## 怎么跑

### 标准方式

```bash
cd campus
mvn spring-boot:run
```

访问 <http://localhost:8080> —— 出现 `Whitelabel Error Page (404)` **是正常的**：
服务已经在跑了，只是还没有任何接口（Lv02 才会有第一个）。

### 本机无外网时的备用方式

当前开发机**没有外网、只有 JDK 25**，`mvn` 插件依赖闭包不全，因此 `campus/tools/` 下有一套
用 `javac` + 精确 classpath 的临时脚手架：

```powershell
cd campus
powershell -File tools\build.ps1
powershell -File tools\run.ps1
```

> ⚠️ `tools/` **不是项目资产，是环境补丁**。有外网后应删除，回到 `mvn spring-boot:run`。
> 完整说明见 [`campus/README.md`](campus/README.md)。

---

## 路线图（9 阶段 · 25 关）

| 阶段 | 名称 | 关卡 | 状态 |
| --- | --- | --- | --- |
| 一 | 先让 Spring Boot 不再神秘 | Lv01 ~ Lv03 | Lv01 ✅ |
| 二 | 真正进入 Spring | Lv04 ~ Lv06 | — |
| 三 | 开始接数据库 | Lv07 ~ Lv09 | — |
| 四 | 开始接触「公司代码」 | Lv10 ~ Lv11 | — |
| 五 | Spring 最核心的东西 | Lv12 | — |
| 六 | Redis | Lv13 | — |
| 七 | 真正做登录 | Lv14 | — |
| 八 | 从「会写」变成「像公司」 | Lv15 ~ Lv20 | — |
| 九 | 把它变成一个真正的项目 | Lv21 ~ Lv25 | — |

| 关卡 | 主题 | 状态 |
| --- | --- | --- |
| Lv01 | 让 Spring Boot 跑起来 | ✅ |
| Lv02 | 写第一个 Controller | ⬜ |
| Lv03 | 真正理解 HTTP | ⬜ |
| Lv04 | 为什么需要 Service | ⬜ |
| Lv05 | IOC | ⬜ |
| Lv06 | DI / Bean | ⬜ |
| Lv07 | 引入 MyBatis | ⬜ |
| Lv08 | 真正访问 MySQL | ⬜ |
| Lv09 | 完成 CRUD ← **学生管理系统 V1.0** | ⬜ |
| Lv10 | 统一返回结果 | ⬜ |
| Lv11 | 异常处理 | ⬜ |
| Lv12 | 事务 | ⬜ |
| Lv13 | Redis | ⬜ |
| Lv14 | JWT | ⬜ |
| Lv15 | 参数校验 | ⬜ |
| Lv16 | DTO / VO | ⬜ |
| Lv17 | 拦截器 | ⬜ |
| Lv18 | AOP | ⬜ |
| Lv19 | 分页 | ⬜ |
| Lv20 | 文件上传 | ⬜ |
| Lv21 | Spring Security | ⬜ |
| Lv22 | RabbitMQ | ⬜ |
| Lv23 | WebSocket | ⬜ |
| Lv24 | Docker | ⬜ |
| Lv25 | Vue3 前后端联调 | ⬜ |

完整路线与依赖关系见 [`docs/08-关卡总览与路线图.md`](docs/08-关卡总览与路线图.md)。

---

## 每一关长什么样

**教学用「5 步教学法」**：先制造问题 → 让你自己发现问题 → 引入方案 → 做实验 → 最后才总结。

**交付用「10 步格式」**：

```
① 本关目标 → ② 为什么学 → ③ 环境准备 → ④ 手把手写代码 → ⑤ 你自己敲
→ ⑥ 故意制造错误 → ⑦ 解释原理 → ⑧ 小练习 → ⑨ 通关标准 → ⑩ 下一关
```

其中 **⑥「故意制造错误」是最重要的部分** —— 每一关都要真的把代码弄坏，看到真实报错，再修回来。
比如 Lv01 就做了四个实验：

| 实验 | 破坏动作 | 真实报错 |
| --- | --- | --- |
| `Lv01-E01` | 删掉 `@SpringBootApplication` | `no ServletWebServerFactory bean defined in the context` |
| `Lv01-E02` | 用同一端口启动第二个实例 | `Web server failed to start. Port 8080 was already in use.` |
| `Lv01-E03` | 命令行覆盖 yml 的端口 | 命令行赢（配置优先级） |
| `Lv01-E04` | 把整仓库 jar 丢进 classpath | `Failed to configure a DataSource`（自动配置按 classpath 决定行为） |

---

## 文档集

从 [`docs/README.md`](docs/README.md) 进入。它遵循一条铁律：

> **可以完善，但不可以随意删改。**

- 全文档采用**稳定编号**（`LvNN` / `FR-*` / `API-*` / `EC-*` / `T-*` / `CHG-*`），一经分配永不回收
- 新增内容写进每份文档的「附录 A 追加区」，不插进正文中间
- 纠正旧结论时，原文**一个字都不删**，只加「⚠️ 已被取代」标注 + 附录 C 勘误 + `CHG-*` 登记
- 全部变更可追溯至 [`docs/12-变更记录.md`](docs/12-变更记录.md)

| 文档 | 内容 |
| --- | --- |
| [README](docs/README.md) | 总索引 · 维护铁律 · 三种阅读路径 |
| [00](docs/00-文档使用与维护规范.md) | 文档集「宪法」：编号、增补、禁改、勘误流程 |
| [01](docs/01-项目总览.md) | 项目定位 · 九阶段 · 成功标准 |
| [02](docs/02-需求文档.md) | 35 条功能需求 + 8 条非功能需求 |
| [03](docs/03-技术栈与选型.md) | 版本基线 · 选型理由 · 环境清单 |
| [04](docs/04-系统架构与技术演进.md) | 分层架构 · 请求旅程 · 逐关架构演进 |
| [05](docs/05-数据库设计.md) | 表设计（只追加，字段改名走勘误） |
| [06](docs/06-接口规范.md) | REST 约定 · `Result<T>` · 状态码 · 接口清单 |
| [07](docs/07-代码规范与工程规范.md) | 包结构 · 分层边界 · 命名 · Git 规范 |
| [08](docs/08-关卡总览与路线图.md) | 25 关总表 · 依赖图 · 里程碑 |
| [09](docs/09-关卡教学与交付模板.md) | 关卡骨架 · 实验设计规范 |
| [10](docs/10-学习进度记录.md) | 学习日志（纯追加） |
| [11](docs/11-附录-术语表.md) | 术语速查 · 易混淆对照 |
| [12](docs/12-变更记录.md) | 变更日志（纯追加） |

---

## 当前状态

| 项 | 状态 |
| --- | --- |
| 文档集 | 14 份主文档 + 25 份关卡讲义，骨架完成并通过自检 |
| 工程 | Spring Boot 3.5.16 可启动，`0.0.0.0:8080 LISTENING` |
| 业务接口 | 无（Lv02 开始） |
| 数据库 / Redis / MQ | 未接入（Lv08 / Lv13 / Lv22 开始） |

已知遗留问题见 [`docs/10-学习进度记录.md`](docs/10-学习进度记录.md) 的遗留问题池。
