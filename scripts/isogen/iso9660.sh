#!/bin/sh

# 5. Package the final filesystem into an ISO9660 image using xorriso.
# xorriso -as mkisofs -o "$ISO_FINAL_PATH"/kjx-headless_v2.iso \
#
    #if ! [ -f "$ISO_FINAL_PATH"/kjx-headless_v3.iso ]; then
if ! [ -f "${ISO_FINAL_NAME}" ]; then
    xorriso -as mkisofs -o "${ISO_FINAL_NAME}" \
      -J -l \
      -V "KJX_HEADLESS" \
      -b syslinux/isolinux.bin \
        -c boot/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
      -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -isohybrid-mbr "${ISOHDPFX_PATH}" \
        -isohybrid-gpt-basdat \
        -r "{$ISO_DIR}" \
        -m 'rootfs' && \
        sleep 15
    else
        printf "\n|> Error: a file was found with the same name. Exiting now...\n"
    fi


else
    printf "\n\n|> Error: not on the root of the kjx-headless repository. hint: Change dir and try again! \n|> Exiting now...\n\n"
fi
