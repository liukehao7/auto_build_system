#!/bin/bash
set -x

iso=$1
len_iso=${#iso}
iso_path=iso

#命名small_iso
small_iso=`basename $iso | sed 's/.iso/-small.iso/'`

#Clean
clean_old_data(){
	[ -d $iso_path ] && rm -rf $iso_path
}

#判断是否为root环境运行
check_root_user(){
	if [ $USER != root ];then
		echo "请切换root环境运行!!"
		exit -1
	fi
}

#判断iso是否合规
check_specifications_iso(){
if [ ${iso:${len_iso}-4:${len_iso}} != .iso ];then
	echo "$iso Incorrect format"
	exit 1
fi
}

#解压iso
decompression_iso(){
	echo Y | 7z x $iso -o$iso_path
       	if [ $? -ne 0 ];then
		echo "解压iso失败，程序退出"
		exit 2
	fi
}

#解压文件系统
decompression_filesystem(){
	unsquashfs $iso_path/live/filesystem.squashfs 
       	if [ $? -ne 0 ];then
		echo "解压filesystem失败，程序退出"
		exit 3
	fi
}

#chroot封装	
Chroot='chroot squashfs-root'

#包移除
remove_package(){

	remove_package_list=" brasero cups* deepin-boot-maker deepin-compressor deepin-deb-installer deepin-deepinid-client deepin-devicemanager deepin-voice-note ffmpeg make man-db mariadb-common mdadm openssh-client ppp pppoe samba-common smbclient vpnc vpnc-scripts "
	
	for i in $remove_package_list;do
		$Chroot apt purge -y $i
		echo "purge $i success"
	done
	$Chroot rm -rf ~/bash_history 
	$Chroot history -c && exit
}

#文件删除
remove_file(){

	remove_file_list=" /usr/share/local /usr/share/fonts/truetype /usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc /usr/share/fonts/opentype/noto/NotoSerifCJK-Regular.ttc /usr/share/doc /usr/share/icons/Papirus /usr/share/icons/Adwaita /usr/share/icons/bloom-dark /usr/share/icons/bloom-classic-dark /usr/share/icons/DMZ-White /usr/share/icons/DMZ-Black /usrshare/uosbrowser /usr/share/deepin-manual /usr/share/thunderbird /usr/bin/bizBin /usr/share/dde-introduction/demo.mp4 /usr/share/man/man1 /usr/share/man/man3 /usr/share/man/man5 /usr/share/man/man8 /usr/share/wallpapers /usr/share/fcitx /usr/share/backgrounds /usr/bin/pandoc /usr/lib/jvm /usr/lib/thunderbird "
	for i in $remove_file_list;do
		$Chroot rm -rf $i
		echo "$i already remove"
	done
	$Chroot rm -rf ~/bash_history 
	$Chroot history -c && exit
}



#压缩filesystem
compression_filesystem(){

[ -d squashfs-root ] && mksquashfs squashfs-root filesystem.squashfs1 -comp xz || echo OK

if [ -f filesystem.squashfs1 ];then
	rm -rf $iso_path/live/filesystem.squashfs squashfs-root
	mv filesystem.squashfs1 $iso_path/live/filesystem.squashfs
fi

}


#oem文件删除
remove_oem_file(){
	if [ -f $iso_path/oem/deb/live-system* ];then
		rm -rvf $iso_path/oem/deb/live-system*
	fi
	if [ -f $iso_path/oem/deb/*gcc* ];then
		rm -rvf $iso_path/oem/deb/*gcc*
	fi
	if [ -f $iso_path/oem/deb/pantum* ];then
		rm -rvf $iso_path/oem/deb/pantum*
	fi
	if [ -f $iso_path/oem/deb/scanner* ];then
		rm -rvf $iso_path/oem/deb/scanner*
	fi
	if [ -f $iso_path/oem/hooks/in_chroot/99_fix_deepin-voice-recoreder.job ];then
		rm -rvf $iso_path/oem/hooks/in_chroot/99_fix_deepin-voice-recoreder.job
	fi
	if [ -f $iso_path/oem/hooks/in_chroot/99_remove_package.job ];then
		rm -rvf $iso_path/oem/hooks/in_chroot/99_remove_package.job
	fi	
}


#压缩iso
compression_iso(){
	cd $iso_path
	xorriso -as mkisofs -rational-rock -joliet -follow-links -eltorito-catalog boot.cat -boot-load-size 4 -boot-info-table -eltorito-alt-boot --efi-boot boot/grub/efi.img -no-emul-boot -V "uos 20" -file_name_limit 250 -o $small_iso  .
}


main(){
	check_root_user
	clean_old_data
	check_specifications_iso
	decompression_iso
	decompression_filesystem	
	remove_package
	remove_file
	compression_filesystem
	remove_oem_file
	compression_iso
}
main
