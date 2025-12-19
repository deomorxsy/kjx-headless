#!/bin/sh

# 1st STEP: set variables
MODE="-setvars" . ./scripts/isogen/set-vars.sh

# 2nd STEP: scaffolding
MODE="-scaff" . ./scripts/isogen/scaffolding.sh

# 3rd STEP: Retrieve dropbear-based ssh-enabled-rootfs artifact from previous actions workflow
MODE="-rootafail" . ./scripts/isogen/rootfs.sh

# 4th STEP: Retrieve runit service tree
MODE="-itarun" . ./scripts/isogen/runit.sh

# 5th STEP: set OCI-CRI container definitions
MODE="-setacontainers" . ./scripts/isogen/oci-cri.sh

# 6th STEP: Retrieve qonq-qdb packaging (shadow + iptables goes here)
MODE="-packaja" . ./scripts/isogen/packaging.sh

# 7th STEP: Organize the squashfs logic
MODE="-squasha" . ./scripts/isogen/squasha.sh

# 8th STEP: Retrieve bzImage artifact from previous actions workflow
MODE="-buildakernel" . ./scripts/isogen/bzImage.sh

# 9th STEP: Retrieve initramfs artifact from previous actions workflow
MODE="-inita" . ./scripts/isogen/initramfs.sh

# 10th STEP: Retrieve beetor_bwc signal-based tracing orchestration from previous actions workflow
MODE="-sting" . ./scripts/isogen/beetor.sh

# 11th STEP: Bootloaders setup
MODE="-bootaeloada" . ./scripts/isogen/bootloaders.sh

# 12th STEP: Build ISO9660
MODE="-isaisa" . ./scripts/isogen/iso9660.sh
