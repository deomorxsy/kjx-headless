package com.kjx.app;

import com.kjx.app.ebpf.BPFProgram;
import com.kjx.app.ebpf.NetworkUtil;
import com.kjx.app.ebpf.Firewall.FirewallAction;
import com.kjx.app.ebpf.Firewall.FirewallRule;
import com.kjx.app.ebpf.Firewall.LogEntry;

/* spring app */
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/* basic collections */
import java.util.ArrayList;
import java.util.List;

@SpringBootApplication(scanBasePackages = "com.kjx.app.ebpf.samples")


/**
 * Hello world!
 */
public class App {
    public static void main(String[] args) {
        System.out.println("Hello World!");
    }
}
