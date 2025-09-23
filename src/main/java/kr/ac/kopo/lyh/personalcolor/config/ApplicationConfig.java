package kr.ac.kopo.lyh.personalcolor.config;

import jakarta.servlet.MultipartConfigElement;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.io.PoolingHttpClientConnectionManager;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.servlet.MultipartConfigFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.HttpComponentsClientHttpRequestFactory;
import org.springframework.util.unit.DataSize;
import org.springframework.web.client.RestTemplate;

import java.net.http.HttpClient;


@Configuration
public class ApplicationConfig {
    @Value("${rest.template.connect.timeout:50000}")
    private int connectTimeout;

    @Value("${rest.template.read.timeout:300000}")
    private int readTimeout;
    @Bean
    public MultipartConfigElement multipartConfigElement() {
        MultipartConfigFactory factory = new MultipartConfigFactory();
        factory.setMaxFileSize(DataSize.ofMegabytes(10)); // 10MB
        factory.setMaxRequestSize(DataSize.ofMegabytes(10)); // 10MB
        return factory.createMultipartConfig();
    }
    @Bean
    public RestTemplate restTemplate() {
        var cm = new PoolingHttpClientConnectionManager();
        cm.setMaxTotal(50);
        cm.setDefaultMaxPerRoute(20);

        var client = HttpClients.custom().setConnectionManager(cm).build();
        var f = new HttpComponentsClientHttpRequestFactory(client);
        f.setConnectTimeout(connectTimeout);
        f.setReadTimeout(readTimeout);
        return new RestTemplate(f);
    }
//    @Bean
//    public RestTemplate restTemplate() {
//        PoolingHttpClientConnectionManager connectionManager = new PoolingHttpClientConnectionManager();
//        connectionManager.setMaxTotal(50); // 전체 커넥션 수 제한
//        connectionManager.setDefaultMaxPerRoute(20); // 라우트별 커넥션 수 제한
//
//        CloseableHttpClient client = HttpClients.custom()
//                .setConnectionManager(connectionManager)
//                .build();
//
//        HttpComponentsClientHttpRequestFactory factory =
//                new HttpComponentsClientHttpRequestFactory(client);
//        factory.setConnectTimeout(connectTimeout);
//        factory.setReadTimeout(readTimeout);
//        return new RestTemplate(factory);
//    }


}