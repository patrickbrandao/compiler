#!/bin/sh

# Script de instalacao do BOOT e sistema de montagem de particoes
#
# Autor: Patrick Brandao <patrickbrandao@gmail.com>
#

. /etc/setup/vars.sh
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/setup"

	# Pontos de montagem e informacoes
	ROOT_DIR=$(head -1 /tmp/root-dir)
	BOOT_DIR=$(head -1 /tmp/boot-dir)
	STORE_DIR=$(head -1 /tmp/store-dir 2>/dev/null)
	SRCDIR=$(head -1 /tmp/srcdir)
	PKGLIST=$(cat /tmp/pkglist)
	IDEV=$(cat /tmp/idev)

#---------------------------------------------------------------------- FSTAB

	# arquivo fstab final
	NFSTAB="$ROOT_DIR/etc/fstab"
	echo -n > $NFSTAB

	# Sistema de montagem
	ptable=/tmp/partitions
	p1=/tmp/fstab-p1; echo -n > $p1
	p2=/tmp/fstab-p2; echo -n > $p2
	p3=/tmp/fstab-p3; echo -n > $p3
	rootdev=""
	for reg in $(cat $ptable); do
		# dados
		_id=$(echo $reg | cut -f1 -d:)
		_type=$(echo $reg | cut -f2 -d:)
		_dev=$(echo $reg | cut -f3 -d:)
		_mount=$(echo $reg | cut -f4 -d:)
		_dir=$(echo $reg | cut -f5 -d:)

		# SWAP
		if [ "$_mount" = "swap" ]; then
			echo "$_dev        swap             swap        defaults         0   0" >> $p1
		fi
		# ROOT /
		if [ "$_mount" = "/" ]; then
			echo "$_dev        /                $_type      defaults         1   1" >> $p2
			rootdev="$_dev"
		fi
		# BOOT /boot
		if [ "$_mount" = "/boot" ]; then
			echo "$_dev        /boot            $_type      defaults         1   1" >> $p3
		fi
		# STORAGE /storage
		if [ "$_mount" = "/storage" ]; then
			echo "$_dev        /storage         $_type      defaults         1   2" >> $p4
		fi
	done

	# Pontos comuns
	(
		# swap
		cat $p1

		# /
		cat $p2

		# boot
		cat $p3

		# storage
		cat $p3

		echo "devpts           /dev/pts         devpts      gid=5,mode=620   0   0"
		echo "proc             /proc            proc        defaults         0   0"
		echo "tmpfs            /dev/shm         tmpfs       defaults         0   0"
	) >> $NFSTAB


#---------------------------------------------------------------------- MBR/GPT BOOT - LILO

cat > "$ROOT_DIR/etc/lilo.conf" << EOF
append=" vt.default_utf8=0"
boot = $IDEV
compact
#-bitmap = /boot/slack.bmp
#-bmp-colors = 255,0,255,0,255,0
#-bmp-table = 60,6,1,16
#-bmp-timer = 65,27,0,255
#message = /boot/boot_message.txt
prompt
timeout = 30
lba32
change-rules
reset
# Normal VGA console
vga = normal
#vga = ask
#vga=791 : VESA framebuffer console @ 1024x768x64k
#vga=790 : VESA framebuffer console @ 1024x768x32k
#vga=773 : VESA framebuffer console @ 1024x768x256
#vga=788 : framebuffer console @ 800x600x64k
#vga=787 : VESA framebuffer console @ 800x600x32k
#vga=771 : VESA framebuffer console @ 800x600x256
#vga=785 : VESA framebuffer console @ 640x480x64k
#vga=784 : VESA framebuffer console @ 640x480x32k
#vga=769 : VESA framebuffer console @ 640x480x256
image = /boot/vmlinuz
  root = $rootdev
  label = Linux
  read-only
EOF

# Ativar pontos de montagem dentro do chroot
	(chroot "$ROOT_DIR" "/bin/sh" "/etc/initsys/run.sh" "00") 2>/tmp/chroot-vmount.log 1>/tmp/chroot-vmount.log || exit 34

# Ativar lilo
	(chroot "$ROOT_DIR" lilo) 2>/tmp/lilo.log 1>/tmp/lilo.log || exit 33
	sync




























