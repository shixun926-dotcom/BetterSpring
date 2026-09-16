package com.campus;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Lv01 · 让 Spring Boot 跑起来
 *
 * 这个类只有 8 行，但它就是整个项目的入口。
 * 执行链路：main() -> SpringApplication.run() -> Spring 容器启动 -> Tomcat 启动 -> 监听 8080
 */
@SpringBootApplication
public class CampusApplication {

    public static void main(String[] args) {
        SpringApplication.run(CampusApplication.class, args);
    }
}
