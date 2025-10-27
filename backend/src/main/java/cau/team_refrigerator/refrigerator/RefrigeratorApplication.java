package cau.team_refrigerator.refrigerator;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class RefrigeratorApplication {

	public static void main(String[] args) {

		SpringApplication.run(RefrigeratorApplication.class, args);
	}

}
