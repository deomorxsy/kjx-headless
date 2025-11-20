#!/bin/sh

create_sandbox_json() {
(
cat <<EOF
"metadata": {
  "name": "nginx-sandbox",
  "namespace": "default",
  "attempt": 1,
  "uid": "hdishd83djaidwnduwk28bcsb"
},
"linux": {
},
"log_directory": "/tmp"
}
EOF
) | tee ./artifacts/sandbox.json

}
