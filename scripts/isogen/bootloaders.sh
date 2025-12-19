#!/bin/sh

# ======================
# Eltorito
#
# no-emulation setup with xorriso and the ISOLINUX's isohybrid
#
# ${ISO_GRUB_PRELOAD_MODULES} was previously used on grub-mkimage for an alternate
# way of getting the eltorito artifact. Now located at ./assets/grub/Dockerfile
# ISO_GRUB_PRELOAD_MODULES="part_gpt part_msdos ext2 normal linux iso9660 udf all_video video_fb search configfile echo cat"

# Fetch eltorito artifact and place it under the ./burn/boot/grub/i386-pc/eltorito.img path

#ELTORITO_PATH="./eltorito.img"
mkdir -p "$ISO_DIR/boot/grub/i386-pc"
if ! [ -f "${ELTORITO_PATH}" ]; then

    cp "${ELTORITO_PATH}" "${ISO_DIR}"/boot/grub/i386-pc/
else
    printf "\n|> Error: eltorito file was not found. Exiting now...\n"

fi
