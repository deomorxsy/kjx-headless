#!/bin/sh
#

mkdir -p /etc/runit/sv/firecracker

cat <<"EOF" > /etc/runit/sv/firecracker/fck-up.sh
#!/bin/sh

firecracker -p
EOF

ln -s /etc/runit/sv/firecracker/fck-up.sh /run/runit/service/


