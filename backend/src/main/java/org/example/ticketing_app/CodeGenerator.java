package org.example.ticketing_app;

import com.baomidou.mybatisplus.generator.FastAutoGenerator;
import com.baomidou.mybatisplus.generator.engine.FreemarkerTemplateEngine;
import org.springframework.beans.factory.annotation.Value;

public class CodeGenerator {
    public static void main(String[] args) {

        FastAutoGenerator.create(
                        "jdbc:mysql://localhost:3306/ticketing_app",
                        "root",
                        "12345"
                )
                .globalConfig(builder -> builder
                        .author("Yucong")
                        .outputDir("backend/src/main/java")
                        .disableOpenDir()
                )
                .packageConfig(builder -> builder
                        .parent("org.example.ticketing_app")
                )
                .strategyConfig(builder -> builder

                        .entityBuilder()
                        .enableLombok()
                        .enableFileOverride()

                        .mapperBuilder()

                        .serviceBuilder()
                        .disableService()

                        .controllerBuilder()
                )
                .templateEngine(new FreemarkerTemplateEngine())
                .execute();
    }
}