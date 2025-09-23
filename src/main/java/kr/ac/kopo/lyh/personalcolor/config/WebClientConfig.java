package kr.ac.kopo.lyh.personalcolor.config;

import io.netty.channel.ChannelOption;
import io.netty.handler.timeout.ReadTimeoutHandler;
import io.netty.handler.timeout.WriteTimeoutHandler;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;

import java.time.Duration;
import java.util.concurrent.TimeUnit;

@Configuration
public class WebClientConfig {
    @Bean
    public WebClient aiWebClient() {
        return WebClient.builder()
                .baseUrl("http://192.168.26.163:5000")  // AI 서버 주소
                .clientConnector(new ReactorClientHttpConnector(
                        HttpClient.create()
                                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 30000)
                                .doOnConnected(conn ->
                                        conn.addHandlerLast(new ReadTimeoutHandler(600, TimeUnit.SECONDS))
                                                .addHandlerLast(new WriteTimeoutHandler(600, TimeUnit.SECONDS)))
                ))
                .build();
    }
}