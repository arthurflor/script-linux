#!/bin/bash

grub_config() {
	if "$crypted" ; then
		sed -i 's!quiet!cryptdevice=/dev/lvm/lvroot:root root=/dev/mapper/root!' "$ARCH"/etc/default/grub
	else
		sed -i 's/quiet//' "$ARCH"/etc/default/grub
	fi

	if "$drm" ; then
		sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/ s/.$/ nvidia-drm.modeset=1"/;s/" /"/' "$ARCH"/etc/default/grub
	fi

	sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=""/GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 pcie_aspm=off"/g' "$ARCH"/etc/default/grub
    	sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' "$ARCH"/etc/default/grub

	if "$UEFI" ; then
		(arch-chroot "$ARCH" grub-install --efi-directory="$esp_mnt" --target=x86_64-efi --bootloader-id=boot
		cp "$ARCH"/"$esp_mnt"/EFI/boot/grubx64.efi "$ARCH"/"$esp_mnt"/EFI/boot/bootx64.efi) &> /dev/null &
		pid=$! pri=0.1 msg="\n$grub_load1 \n\n \Z1> \Z2grub-install --efi-directory="$esp_mnt"\Zn" load

		if ! "$crypted" ; then
			arch-chroot "$ARCH" mkinitcpio -p "$kernel" &>/dev/null &
			pid=$! pri=1 msg="\n$uefi_config_load \n\n \Z1> \Z2mkinitcpio -p $kernel\Zn" load
		fi
	else
		arch-chroot "$ARCH" grub-install /dev/"$DRIVE" &> /dev/null &
		pid=$! pri=0.1 msg="\n$grub_load1 \n\n \Z1> \Z2grub-install /dev/$DRIVE\Zn" load
	fi
	arch-chroot "$ARCH" grub-mkconfig -o /boot/grub/grub.cfg &> /dev/null &
	pid=$! pri=0.1 msg="\n$grub_load2 \n\n \Z1> \Z2grub-mkconfig -o /boot/grub/grub.cfg\Zn" load
}
