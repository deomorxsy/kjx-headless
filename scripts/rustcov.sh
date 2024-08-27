#!/bin/sh

covpath="./artifacts/html_cov_rust"

cat <<"EOF" > "$covpath"
#!/bin/sh

if [ $# -lt 1 ]; then
    echo "Error: Name of fuzz target is required."
    echo "Usage: $0 fuzz_target [sources...]"
    exit 1
fi
FUZZ_TARGET="$1"
shift
SRC_FILTER="$@"
TARGET=$(rustc -vV | sed -n 's|host: ||p')
cargo +nightly cov -- show -Xdemangler=rustfilt \
  "target/$TARGET/coverage/$TARGET/release/$FUZZ_TARGET" \
  -instr-profile="fuzz/coverage/$FUZZ_TARGET/coverage.profdata"  \
  -show-line-counts-or-regions -show-instantiations  \
  -format=html -o fuzz_html/ $SRC_FILTER
EOF

chmod +x "$covpath"
