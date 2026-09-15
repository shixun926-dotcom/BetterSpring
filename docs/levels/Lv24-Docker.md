# Lv24 · Docker

> **关卡编号**：`Lv24` ｜ **所属阶段**：第九阶段 · 把它变成一个真正的项目
> **前置关卡**：`Lv23` WebSocket（✅） ｜ **状态**：⬜ 未开始
> **对应需求**：`FR-E-003` ｜ **对应接口**：无变化 ｜ **对应数据表**：全部
> **本关产物**：`docker compose up` 一键起全栈（应用 + MySQL + Redis + RabbitMQ）

---

## 0. 本关速览

| 项目 | 内容 |
| --- | --- |
| 一句话目标 | 把项目与它的所有中间件打包成可以一键启动的一组容器 |
| 核心知识点 | 镜像、容器、Dockerfile、多阶段构建、Docker Compose、数据卷 |
| 预计耗时 | 🚧 待补充 |
| 难度（1~5） | 4 |
| 关键文件 | `Dockerfile`、`docker-compose.yml`、`.dockerignore` |
| 架构变化 | 出现**运行环境标准化**，应用与中间件容器化 |

---

## 1. 本关目标 `Lv24-S1`

1. 能说清**镜像**与**容器**的区别（不是背定义，是"一个模板 vs 一个运行实例"）；
2. 能写出 `Dockerfile`，用**多阶段构建**把 Spring Boot 项目打成镜像；
3. 能写出 `docker-compose.yml`，一次拉起应用 + MySQL + Redis + RabbitMQ，并配好网络与服务依赖；
4. 能用**数据卷**让 MySQL 的数据在容器重建后不丢；
5. 能说清"容器化"解决的具体问题（用"在我机器上能跑"这个场景说）；
6. 能说清环境变量与配置外置的关系（配置不能写死在镜像里）。

📎 参考（`Consult.txt`）：

> 后面甚至可以加入：
> Redis
> RabbitMQ
> WebSocket
> Spring Security
> Docker
> Nginx
> Vue3

📌 本关是**扩展关卡**（`FR-E-003` 标记为"扩展"）。但它是**投入产出比最高的一关**：
配好之后，[Lv25](Lv25-Vue3前后端联调.md) 的联调会轻松很多。

---

## 2. 为什么学 `Lv24-S2`

先制造问题。

你现在把项目交给同事，需要他做这些：

```
① 装 JDK 17（版本不对就编译失败）
② 配 JAVA_HOME
③ 装 Maven 3.9
④ 装 MySQL 8，建库 campus，设置字符集 utf8mb4
⑤ 装 Redis 7
⑥ 装 RabbitMQ，开管理插件
⑦ 建表 + 导初始数据
⑧ 改 application.yml 里的连接地址和密码
⑨ 端口 8080 / 3306 / 6379 / 5672 都不能被占用
```

**任何一步版本不同、路径不同、密码不同，就是"在我机器上能跑"。**

而且这套流程**每换一次环境就要重来一遍**：同事的电脑、测试服务器、生产服务器……

| # | 问题 | 后果 |
| --- | --- | --- |
| 1 | 环境靠文档和口头传递 | 漏一步就起不来 |
| 2 | 中间件版本不一致 | 行为差异、诡异 bug |
| 3 | 部署服务器上不该装开发工具 | 污染、难维护 |
| 4 | 无法快速重建 | 环境坏了要重新装一整天 |
| 5 | 多个项目端口冲突 | 互相影响 |

**Docker 解决的就是这些**：把"应用 + 依赖 + 运行环境"一起打包成**镜像**，
在任何装了 Docker 的机器上，一条命令得到**完全一样**的运行结果。

📌 关键理解：

> **镜像 = 一个只读的模板（含操作系统层、运行时、你的程序）**
> **容器 = 这个模板的一个运行实例**
> **Dockerfile = 造镜像的说明书**
> **docker-compose.yml = 一次描述"要跑哪几个容器、怎么连"**

---

## 3. 环境准备 `Lv24-S3`

| # | 项目 | 要求 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | Lv23 已通关 | 全部功能可用 | 接口全部跑通 | ⬜ |
| 2 | Docker 已安装 | 能跑容器 | `docker version` | ⬜ |
| 3 | Docker Compose | v2 内置 | `docker compose version` | ⬜ |
| 4 | 磁盘空间 | 至少 5GB 可用 | 镜像 + 数据卷占空间 | ⬜ |
| 5 | 镜像加速 | 配置国内镜像源（可选但强烈建议） | 拉取速度正常 | ⬜ |
| 6 | 项目可打包 | `mvn clean package` 成功 | `target/*.jar` 存在 | ⬜ |
| 7 | 配置已外置 | 密码等不写死在代码里 | 见 [Lv01](Lv01-SpringBoot启动.md) `NFR-008` | ⬜ |

⚠️ Windows 上需要 Docker Desktop 并确认 WSL2 后端已启用。**这一步卡住的人很多，留足时间。**

---

## 4. 手把手写代码 `Lv24-S4`

### 4.1 先理解镜像分层（不写代码，先看现象）

```bash
docker run hello-world
docker images                       # 看有哪些镜像
docker ps -a                        # 看有哪些容器（含已停止）
docker run -d -p 8081:80 nginx      # 起一个 nginx
docker ps                           # 看运行中的容器
docker logs <containerId>           # 看它的日志
docker exec -it <containerId> bash  # 进入容器内部
docker stop <containerId>
docker rm <containerId>
```

📌 **必须先亲手跑一遍上面这些命令**，否则后面写 `Dockerfile` 是纯抄。

### 4.2 `Dockerfile`（多阶段构建）

```dockerfile
# ---------- 阶段一：构建 ----------
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /build
COPY pom.xml .
# 🚧 待补充：先只拷 pom 并下载依赖（利用镜像层缓存，加速后续构建）
COPY src ./src
RUN mvn clean package -DskipTests

# ---------- 阶段二：运行 ----------
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=builder /build/target/*.jar app.jar
EXPOSE 8080
ENV TZ=Asia/Shanghai
ENTRYPOINT ["java", "-jar", "app.jar"]
```

📌 **多阶段构建的意义**：最终镜像里**不含 Maven 与源码**，体积从 ~700MB 降到 ~200MB。
📌 **先把 `pom.xml` 单独 COPY 再 `mvn`**：这样改代码时不会重新下载依赖（利用层缓存）。这个细节能把构建时间从几分钟降到几秒。

### 4.3 `.dockerignore`

```
target/
.idea/
*.iml
.git/
docs/
upload/
```

📌 不写 `.dockerignore`，`target/`（几百 MB）会被拷进构建上下文，构建变得很慢。

### 4.4 `docker-compose.yml`

```yaml
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: campus
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql
      - ./src/main/resources/db:/docker-entrypoint-initdb.d   # 首次启动自动执行建表脚本
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 5s
      retries: 10

  redis:
    image: redis:7
    ports:
      - "6379:6379"
    # 🚧 待补充：数据卷（是否需要持久化验证码？）

  rabbitmq:
    image: rabbitmq:3-management
    ports:
      - "5672:5672"
      - "15672:15672"

  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      # 🚧 待补充：用环境变量覆盖 application.yml 里的连接地址
      # SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/campus?...
      # SPRING_DATA_REDIS_HOST: redis
      # SPRING_RABBITMQ_HOST: rabbitmq
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_started

volumes:
  mysql-data:
```

📌 **本关最关键的三处配置**：

| # | 配置 | 为什么 |
| --- | --- | --- |
| 1 | `SPRING_DATASOURCE_URL` 里的主机名写 **`mysql`**（服务名），不是 `localhost` | 容器之间通过服务名互相访问；`localhost` 在容器里指向容器自己 |
| 2 | `depends_on` + `healthcheck` | 否则应用会在 MySQL 还没就绪时启动 → 连接失败 |
| 3 | `volumes` 里的 `mysql-data` | 不配数据卷，`docker compose down` 之后**数据全丢** |

⚠️ **第 1 条是本关第一大坑**：所有 `localhost:3306` / `localhost:6379` 都必须改成服务名。

### 4.5 配置外置（`NFR-008`）

```yaml
# application.yml 里写默认值（本地开发用）
spring:
  datasource:
    url: ${SPRING_DATASOURCE_URL:jdbc:mysql://localhost:3306/campus?...}
```

📌 用 `${环境变量:默认值}` 的写法，**同一份 jar 在本地和容器里都能跑**，不用改代码。

🔐 **敏感信息不进 Git**：
- `.env` 文件放密码，加入 `.gitignore`；
- 仓库里只提交 `.env.example`；
- 对照 [07 §7.3](../07-代码规范与工程规范.md#73-必须提交--禁止提交)。

### 4.6 运行与验证

```bash
# 一键起全栈
docker compose up -d --build

# 看状态（app 应该是 Up，mysql 应该是 healthy）
docker compose ps

# 看应用日志
docker compose logs -f app

# 验证接口
curl http://localhost:8080/students?page=1&pageSize=10

# 验证中间件
docker compose exec redis redis-cli ping          # → PONG
# 浏览器打开 http://localhost:15672              # → RabbitMQ 管理台

# 销毁（数据卷保留）
docker compose down

# 销毁并删数据
docker compose down -v
```

📌 **验收动作**：`docker compose down` 再 `up`，**数据还在**（因为用了数据卷）。

🚧 待补充：实际启动记录与截图。

---

## 5. 你自己敲 `Lv24-S5`

- [ ] 不看 §4.1，独立跑一遍 `run` / `ps` / `logs` / `exec` / `stop` / `rm`
- [ ] 不看 §4.2，写出 `Dockerfile` 并成功构建镜像
- [ ] 不看 §4.4，写出 `docker-compose.yml`，一键起全栈
- [ ] 做一次 `down` → `up`，验证数据卷生效
- [ ] 回答：为什么容器里不能用 `localhost` 访问 MySQL？

---

## 6. 故意制造错误 `Lv24-S6`

### `Lv24-E01` · 容器里用 `localhost` 连数据库

| 项 | 内容 |
| --- | --- |
| 破坏动作 | `SPRING_DATASOURCE_URL` 保持 `jdbc:mysql://localhost:3306/campus` |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充（`Connection refused` —— 因为 localhost 是容器自己） |
| 恢复动作 | 改成 `mysql:3306` |
| 状态 | ⬜ |

📌 **本关第一大坑，必须亲手踩一次。**

### `Lv24-E02` · MySQL 还没就绪应用就启动

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 去掉 `healthcheck` 与 `condition: service_healthy` |
| 预期现象 | 🚧 待补充（应用启动时报连接失败） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 加回 healthcheck |
| 状态 | ⬜ |

📌 有意思的观察：有时应用**看起来启动了**，但第一个请求才报错。原因是连接池懒加载。
**这类"启动成功但一用就错"的问题最难查。**

### `Lv24-E03` · 数据卷没配

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 去掉 `volumes: mysql-data` |
| 预期现象 | 🚧 待补充 |
| 实际现象 | 🚧 待补充（`down` 之后数据**全丢**） |
| 恢复动作 | 加回数据卷 |
| 状态 | ⬜ |

### `Lv24-E04` · 端口冲突

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 本机已经装了 MySQL 占着 3306，compose 又映射 3306 |
| 预期现象 | 🚧 待补充（`Port is already allocated`） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 改映射为 `13306:3306` |
| 状态 | ⬜ |

### `Lv24-E05` · 镜像里带了 `target/`

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 不写 `.dockerignore`，且 `COPY . .` |
| 预期现象 | 🚧 待补充（构建上下文巨大，构建极慢） |
| 实际现象 | 🚧 待补充（`Sending build context to Docker daemon  512MB`） |
| 恢复动作 | 加 `.dockerignore` |
| 状态 | ⬜ |

### `Lv24-E06` · 密码写进 `docker-compose.yml` 并提交

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 直接把真实密码写进 compose 文件并 commit |
| 预期现象 | 🚧 待补充（**密码进入 Git 历史，无法真正删除**） |
| 恢复动作 | 用 `.env` + `.gitignore`，仓库只留 `.env.example` |
| 状态 | ⬜ |

### `Lv24-E07` · 时区不对

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 不设 `TZ`，容器用 UTC |
| 预期现象 | 🚧 待补充（时间字段差 8 小时） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 设 `TZ=Asia/Shanghai` |
| 状态 | ⬜ |

### `Lv24-E08` · 建表脚本没被自动执行

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 把 SQL 放在别的目录，或数据卷已存在时重新 `up` |
| 预期现象 | 🚧 待补充（提示：`docker-entrypoint-initdb.d` **只在数据目录为空时执行一次**） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | `down -v` 清掉数据卷再 `up`，或手动执行迁移脚本 |
| 状态 | ⬜ |

### `Lv24-E09` · 上传的图片没了

| 项 | 内容 |
| --- | --- |
| 破坏动作 | [Lv20](Lv20-文件上传.md) 的本地存储目录没配数据卷，容器重建 |
| 预期现象 | 🚧 待补充（数据库有 URL，但图片 404） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 给上传目录配数据卷 |
| 状态 | ⬜ |

📌 这个实验很好地把 [Lv20](Lv20-文件上传.md) 和本关串起来了：**"数据库只存 URL"的代价，就是文件存储的可靠性要你自己保证。**

### `Lv24-E10` · 构建缓存失效

| 项 | 内容 |
| --- | --- |
| 破坏动作 | 先 `COPY . .` 再 `mvn package` |
| 预期现象 | 🚧 待补充（改一行代码就重新下载全部依赖） |
| 实际现象 | 🚧 待补充 |
| 恢复动作 | 先 COPY `pom.xml`，下载依赖，再 COPY `src` |
| 状态 | ⬜ |

---

## 7. 解释原理 `Lv24-S7`

> 必须依次回答 [09 §4 的五个问题](../09-关卡教学与交付模板.md#4-每关必答的五个问题)。

1. **没有它会发生什么？** 🚧 待补充（用 §2 的九步手工流程）
2. **它怎么解决的？** 🚧 待补充
3. **实验验证了什么？** 见 `Lv24-E01` ~ `Lv24-E10`
4. **一句话结论** 🚧 待补充
5. **架构哪一层变了？** 运行环境标准化（同步 [04-架构演进](../04-系统架构与技术演进.md#4-架构演进时间线) 的 Lv24 行）

### 必须能答的问题

| 问题 | 答案 |
| --- | --- |
| 镜像与容器的区别？ | 🚧 待补充 |
| 多阶段构建解决了什么问题？ | 🚧 待补充（镜像体积） |
| 容器里为什么不能用 `localhost` 访问别的容器？ | 🚧 待补充 |
| 数据卷解决什么问题？ | 🚧 待补充 |
| 为什么配置要外置而不是打进镜像？ | 🚧 待补充（同一镜像多环境） |
| `depends_on` 与 `healthcheck` 的关系？ | 🚧 待补充（前者只管启动顺序，后者才管就绪） |

⚠️ 本节不得出现未在 §4~§6 出现过的新名词（`Nginx` 留到 [Lv25](Lv25-Vue3前后端联调.md) 之后）。

---

## 8. 小练习 `Lv24-S8`

### `Lv24-Q01` 缩小镜像

尝试把最终镜像压到 150MB 以内，记录前后体积。

### `Lv24-Q02` JVM 参数

给 `ENTRYPOINT` 加上合适的 JVM 参数（如 `-Xms256m -Xmx512m`），说明为什么容器里要显式限制堆内存。

### `Lv24-Q03` 健康检查端点

用 Spring Boot Actuator 暴露 `/actuator/health`，让 `app` 服务也有 healthcheck。

### `Lv24-Q04` Redis 持久化

判断验证码数据是否需要持久化，说明理由，并据此决定是否给 Redis 配卷。

### `Lv24-Q05` 写进文档

把"如何一键启动项目"补进 [07](../07-代码规范与工程规范.md)，并登记 `CHG-*`。

📌 答案写到本关「附录 A · 追加区」，**不要覆盖题目**。

---

## 9. 通关标准 `Lv24-S9`

> 全部勾选才算 ✅ 通关。勾选后到 [10-学习进度记录](../10-学习进度记录.md) 登记。

- [ ] `Lv24-A01` 能不看资料说清镜像与容器的区别，并独立跑过 `run`/`ps`/`logs`/`exec`
- [ ] `Lv24-A02` `Dockerfile` 使用多阶段构建，镜像能成功构建
- [ ] `Lv24-A03` **`docker compose up -d --build` 一条命令起全栈**（本关核心证据）
- [ ] `Lv24-A04` 应用容器能连上 MySQL / Redis / RabbitMQ（用的是**服务名**而非 `localhost`）
- [ ] `Lv24-A05` 完成了 `down` → `up` 的数据保留验证（数据卷生效）
- [ ] `Lv24-A06` `Lv24-E01`（localhost）与 `Lv24-E02`（启动顺序）已完成
- [ ] `Lv24-A07` 敏感信息通过 `.env` 外置，未提交到 Git（`.env.example` 已提交）
- [ ] `Lv24-A08` `.dockerignore` 已配置
- [ ] `Lv24-A09` `Lv24-E01` ~ `Lv24-E10` 中至少完成六个
- [ ] `Lv24-A10` `Lv24-Q01` ~ `Lv24-Q05` 中至少完成两个
- [ ] `Lv24-A11` 能说清"在我机器上能跑"这个问题是怎么被解决的
- [ ] `Lv24-A12` 代码是自己敲的，不是复制的
- [ ] `Lv24-A13` 本关新增内容已按 [00-维护规范](../00-文档使用与维护规范.md) 登记

📌 `Lv24-A03`、`Lv24-A05` 是本关的核心。

---

## 10. 下一关 `Lv24-S10`

后端到此为止，已经是一个**能在任何机器上一键启动的完整服务**。

但它现在还缺最后一块：**没有界面。**

到目前为止，你的"前端"一直是 Postman。真实用户不会用 Postman。

参考文档的最后一步是：

> Lv25 Vue3前后端联调

下一关你会遇到一些全新的问题：

- 前端跑在 `5173` 端口，后端在 `8080`，**浏览器会因为"跨域"直接拦住你的请求**；
- 前端的 Token 该存在哪里？
- 后端返回的 `{code, msg, data}` 到底该怎么处理？
- 为什么 Postman 能通，浏览器就不行？

下一关：**Vue3 前后端联调**。

➡️ [`Lv25` · Vue3 前后端联调](Lv25-Vue3前后端联调.md)

---

## 附录 A · 追加区

> 追加格式见 [00-维护规范 §3.3](../00-文档使用与维护规范.md)。已写入的条目不得删除。

### A.1 容器清单（待学习者填写）

| 服务 | 镜像 | 端口映射 | 数据卷 | 状态 |
| --- | --- | --- | --- | --- |
| mysql | 🚧 | 🚧 | 🚧 | 🚧 |
| redis | 🚧 | 🚧 | 🚧 | 🚧 |
| rabbitmq | 🚧 | 🚧 | 🚧 | 🚧 |
| app | 🚧 | 🚧 | 🚧 | 🚧 |

### A.2 镜像体积记录（待学习者填写）

| 版本 | 体积 | 说明 |
| --- | --- | --- |
| 单阶段构建 | 🚧 | 🚧 |
| 多阶段构建 | 🚧 | 🚧 |

*（后续追加自此向下）*

## 附录 B · 踩坑记录 `Lv24-P0n`

| ID | 日期 | 现象 | 原因 | 解决 | 关联实验 |
| --- | --- | --- | --- | --- | --- |
| — | — | — | — | — | — |

## 附录 C · 勘误

*（暂无。格式见 [00-维护规范 §4.2](../00-文档使用与维护规范.md)。）*
