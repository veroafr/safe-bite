package com.safebite.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling // importación periódica de noticias (NoticiaRssService)
public class SafebiteBackendApplication {
    public static void main(String[] args) {
        SpringApplication.run(SafebiteBackendApplication.class, args);
    }
}
