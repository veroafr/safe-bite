package com.safebite.backend.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

/**
 * Envio de emails. Si no hay SMTP configurado (variables SPRING_MAIL_HOST,
 * SPRING_MAIL_PORT, SPRING_MAIL_USERNAME, SPRING_MAIL_PASSWORD) el mensaje se
 * escribe en el log del servidor, para poder probar el flujo en desarrollo.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final ObjectProvider<JavaMailSender> mailSender;

    @Value("${spring.mail.host:}")
    private String host;

    @Value("${safebite.mail.from:no-reply@safebite.app}")
    private String remitente;

    /** @return true si se envio por SMTP; false si solo quedo en el log. */
    public boolean enviar(String para, String asunto, String cuerpo) {
        JavaMailSender sender = mailSender.getIfAvailable();
        if (sender == null || host == null || host.isBlank()) {
            log.warn("SMTP no configurado. Email para {} | {} | {}", para, asunto, cuerpo);
            return false;
        }
        try {
            SimpleMailMessage msg = new SimpleMailMessage();
            msg.setFrom(remitente);
            msg.setTo(para);
            msg.setSubject(asunto);
            msg.setText(cuerpo);
            sender.send(msg);
            return true;
        } catch (Exception e) {
            log.error("No se pudo enviar el email a {}: {}", para, e.getMessage());
            return false;
        }
    }
}
