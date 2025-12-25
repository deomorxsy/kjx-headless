### yava-jvm

These are examples on calling eBPF from jvm-hosted languages: clojure, kotlin and java.


#### java examples

```
; tree -C
.
├── pom.xml
└── src
    ├── main
    │   └── java
    │       └── com
    │           └── kjx
    │               └── app
    │                   ├── App.java
    │                   └── Firewall.java
    └── test
        └── java
            └── com
                └── kjx
                    └── app
                        ├── AppTest.java
                        └── Firewall.java
```

#### Kotlin examples

```
├── gradle [1]
│   ├── libs.versions.toml [2]
│   └── wrapper
│       ├── gradle-wrapper.jar
│       └── gradle-wrapper.properties
├── gradlew [3]
├── gradlew.bat [3]
├── settings.gradle [4]
└── app
    ├── build.gradle [5]
    └── src
        ├── main
        │   └── kotlin [6]
        │       └── demo
        │           └── App.kt
        └── test
            └── kotlin [7]
                └── demo
                    └── AppTest.kt
```
