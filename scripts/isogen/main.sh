#!/bin/sh

# 1st STEP: set variables
if ! (MODE="-isogen_setvars" . ./scripts/isogen/set-vars.sh); then
    echo "|> Error: it was not possible to run the set variables script. Exiting now..."
    echo && echo
    return 1
fi
echo "|> Successfully ran the set variables script."

# 2nd STEP: scaffolding
if ! (MODE="-isogen_scaff" . ./scripts/isogen/scaffolding.sh); then
    echo "|> Error: it was not possible to run the scaffolding script. Exiting now..."
    echo && echo
    return 1
fi
echo "|> Successfully ran the scaffolding script."

# 3rd STEP: Retrieve dropbear-based ssh-enabled-rootfs artifact from previous actions workflow
if ! (MODE="-isogen_rootafail" . ./scripts/isogen/rootfs.sh); then
    echo "|> Error: it was not possible to run the rootfs script. Exiting now..."
    echo && echo
    return 1
fi
echo "|> Successfully ran the rootfs script."

# 4th STEP: Organize the squashfs filesystem logic
if ! (MODE="-isogen_squasha" . ./scripts/isogen/squasha.sh); then
    echo "|> Error: it was not possible to run the squashfs filesystem logic script. Exiting now..."
    echo && echo
    return 1
fi
echo "|> Successfully ran the squashfs filesystem logic script."

# 5th STEP: Retrieve qonq-qdb packaging (shadow + iptables goes here)
if ! (MODE="-isogen_packaja" . ./scripts/isogen/packaging.sh); then
    echo "|> Error: it was not possible to run the qonq-qdb packaging (shadow+iptables goes here). Exiting now..."
    echo && echo
    return 1
fi
echo "|> Successfully ran the qonq-qdb packaging (shadow+iptables goes here)."

# 6th STEP: Retrieve runit service tree
if ! (MODE="-isogen_itarun" . ./scripts/isogen/runit.sh); then
    echo "|> Error: it was not possible to run the runit service tree script. Exiting now..."
    echo && echo
    return 1
fi
echo "|> Successfully ran the runit service tree script."

# 7th STEP: set OCI-CRI container definitions
if ! (MODE="-isogen_setacontainers" . ./scripts/isogen/oci-cri.sh); then
    echo "|> Error: it was not possible to run the script to set the OCI-CRI container definitions. Exiting now..."
    echo && echo
    return 1
fi
echo "|> Successfully ran the script to set the OCI-CRI container definitions."

# 8th STEP: Retrieve bzImage artifact from previous actions workflow
if ! (MODE="-isogen_buildakernel" . ./scripts/isogen/bzImage.sh); then
    echo "|> Error: it was not possible to run the bzImage generation script (kernel build). Exiting now..."
    echo && echo
    return 1
fi
echo "|> Successfully ran the bzImage generation script (kernel build)."

# 9th STEP: Retrieve initramfs artifact
if ! (MODE="-isogen_inita" . ./scripts/isogen/initramfs.sh); then
    echo "|> Error: it was not possible to run the script to retrieve the initramfs artifact. Exiting now..."
    echo && echo
    return 1
fi
echo "|> Successfully ran the script to retrieve the initramfs artifact."

# 10th STEP: Retrieve beetor_bwc signal-based tracing orchestration from previous actions workflow
if ! (MODE="-isogen_sting" . ./scripts/isogen/beetor.sh); then
    echo "|> Error: it was not possible to run the script to retrieve beetor_bwc artifact (for signal-based tracing orchestration). Exiting now...."
    echo && echo
    return 1
fi
echo "|> Successfully ran the script to retrieve beetor_bwc artifact (for signal-based tracing orchestration)."

# 11th STEP: Bootloaders setup
if ! (MODE="-isogen_bootaeloada" . ./scripts/isogen/bootloaders.sh); then
    echo "|> Error: it was not possible to run the script to setup the bootloaders for the final iso. Exiting now..."
    echo && echo
    return 1
fi
echo "|> Successfully ran the script to setup the bootloaders for the final iso."

# 12th STEP: Build ISO9660
if ! (MODE="-isogen_isaisa" . ./scripts/isogen/iso9660.sh); then
    echo "|> Error: it was not possible to run the build the iso9660 shellscript. Exiting now..."
    echo && echo
    return 1
fi
echo "|> Successfully ran the build the iso9660 shellscript."
