#!/bin/bash 
####

# PVE語言設定
pvelocale(){
	sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen && TIME g "PVE語言包設定完成!"
}
if [ `export|grep 'LC_ALL'|wc -l` = 0 ];then
	pvelocale
	if [ `grep "LC_ALL" /etc/profile|wc -l` = 0 ];then
		echo "export LC_ALL='en_US.UTF-8'" >> /etc/profile
		echo "export LANG='en_US.UTF-8'" >> /etc/profile
	fi
fi
if [ `grep "alias ll" /etc/profile|wc -l` = 0 ];then
	echo "alias ll='ls -alh'" >> /etc/profile
	echo "alias sn='snapraid'" >> /etc/profile
fi
source /etc/profile
# pause
pause(){
    read -n 1 -p " 按任意鍵繼續... " input
    if [[ -n ${input} ]]; then
        echo -e "\b\n"
    fi
}

# 字型顏色設定
TIME() {
[[ -z "$1" ]] && {
	echo -ne " "
} || {
	 case $1 in
	r) export Color="\e[31;1m";;
	g) export Color="\e[32;1m";;
	b) export Color="\e[34;1m";;
	y) export Color="\e[33;1m";;
	z) export Color="\e[35;1m";;
	l) export Color="\e[36;1m";;
	  esac
	[[ $# -lt 2 ]] && echo -e "\e[36m\e[0m ${1}" || {
		echo -e "\e[36m\e[0m ${Color}${2}\e[0m"
	 }
	  }
}


#--------------PVE更換軟體源----------------
# apt國內源
aptsources() {
	sver=`cat /etc/debian_version |awk -F"." '{print $1}'`
	case "$sver" in
 	12 )
  		sver="bookworm"
 	;;
	11 )
		sver="bullseye"
	;;
	10 )
		sver="buster"
	;;
	9 )
		sver="stretch"
	;;
	8 )
		sver="jessie"
	;;
	7 )
		sver="wheezy"
	;;
	6 )
		sver="squeeze"
	;;
	* )
		sver=""
	;;
	esac
	if [ ! $sver ];then
		TIME r "您的版本不支援！"
		exit 1
	fi
	cp -rf /etc/apt/sources.list /etc/apt/backup/sources.list.bak
	echo " 請選擇您需要的apt國內源"
	echo " 1. 清華大學鏡像站"
	echo " 2. 中科大鏡像站"
	echo " 3. 上海交大鏡像站"
	echo " 4. 阿里雲鏡像站"
	echo " 5. 騰訊雲鏡像站"
	echo " 6. 網易鏡像站"
	echo " 7. 華為鏡像站"
	input="請輸入選擇[默認1]"
	while :; do
	read -t 30 -p " ${input}： " aptsource || echo
	aptsource=${aptsource:-1}
	case $aptsource in
	1)
	cat > /etc/apt/sources.list <<-EOF
		deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${sver} main contrib non-free
		deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ ${sver} main contrib non-free
		deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${sver}-updates main contrib non-free
		deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ ${sver}-updates main contrib non-free
		deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${sver}-backports main contrib non-free
		deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ ${sver}-backports main contrib non-free
		deb https://mirrors.tuna.tsinghua.edu.cn/debian-security ${sver}-security main contrib non-free
		deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security ${sver}-security main contrib non-free
	EOF
	break
	;;
	2)
	cat > /etc/apt/sources.list <<-EOF
		deb https://mirrors.ustc.edu.cn/debian/ ${sver} main contrib non-free
		deb-src https://mirrors.ustc.edu.cn/debian/ ${sver} main contrib non-free
		deb https://mirrors.ustc.edu.cn/debian/ ${sver}-updates main contrib non-free
		deb-src https://mirrors.ustc.edu.cn/debian/ ${sver}-updates main contrib non-free
		deb https://mirrors.ustc.edu.cn/debian/ ${sver}-backports main contrib non-free
		deb-src https://mirrors.ustc.edu.cn/debian/ ${sver}-backports main contrib non-free
		deb https://mirrors.ustc.edu.cn/debian-security/ ${sver}-security main contrib non-free
		deb-src https://mirrors.ustc.edu.cn/debian-security/ ${sver}-security main contrib non-free
	EOF
	break
	;;  
	3)
	cat > /etc/apt/sources.list <<-EOF
		deb https://mirror.sjtu.edu.cn/debian/ ${sver} main non-free contrib
		deb-src https://mirror.sjtu.edu.cn/debian/ ${sver} main non-free contrib
		deb https://mirror.sjtu.edu.cn/debian/ ${sver}-security main
		deb-src https://mirror.sjtu.edu.cn/debian/ ${sver}-security main
		deb https://mirror.sjtu.edu.cn/debian/ ${sver}-updates main non-free contrib
		deb-src https://mirror.sjtu.edu.cn/debian/ ${sver}-updates main non-free contrib
		deb https://mirror.sjtu.edu.cn/debian/ ${sver}-backports main non-free contrib
		deb-src https://mirror.sjtu.edu.cn/debian/ ${sver}-backports main non-free contrib
	EOF
	break
	;;
	4)
	cat > /etc/apt/sources.list <<-EOF
		deb http://mirrors.aliyun.com/debian/ ${sver} main non-free contrib
		deb-src http://mirrors.aliyun.com/debian/ ${sver} main non-free contrib
		deb http://mirrors.aliyun.com/debian-security/ ${sver}-security main
		deb-src http://mirrors.aliyun.com/debian-security/ ${sver}-security main
		deb http://mirrors.aliyun.com/debian/ ${sver}-updates main non-free contrib
		deb-src http://mirrors.aliyun.com/debian/ ${sver}-updates main non-free contrib
		deb http://mirrors.aliyun.com/debian/ ${sver}-backports main non-free contrib
		deb-src http://mirrors.aliyun.com/debian/ ${sver}-backports main non-free contrib
	EOF
	break
	;;
	5)
	cat > /etc/apt/sources.list <<-EOF
		deb https://mirrors.tencent.com/debian/ ${sver} main non-free contrib
		deb-src https://mirrors.tencent.com/debian/ ${sver} main non-free contrib
		deb https://mirrors.tencent.com/debian-security/ ${sver}-security main
		deb-src https://mirrors.tencent.com/debian-security/ ${sver}-security main
		deb https://mirrors.tencent.com/debian/ ${sver}-updates main non-free contrib
		deb-src https://mirrors.tencent.com/debian/ ${sver}-updates main non-free contrib
		deb https://mirrors.tencent.com/debian/ ${sver}-backports main non-free contrib
		deb-src https://mirrors.tencent.com/debian/ ${sver}-backports main non-free contrib
	EOF
	break
	;;
	6)
	cat > /etc/apt/sources.list <<-EOF
		deb https://mirrors.163.com/debian/ ${sver} main non-free contrib
		deb-src https://mirrors.163.com/debian/ ${sver} main non-free contrib
		deb https://mirrors.163.com/debian-security/ ${sver}-security main
		deb-src https://mirrors.163.com/debian-security/ ${sver}-security main
		deb https://mirrors.163.com/debian/ ${sver}-updates main non-free contrib
		deb-src https://mirrors.163.com/debian/ ${sver}-updates main non-free contrib
		deb https://mirrors.163.com/debian/ ${sver}-backports main non-free contrib
		deb-src https://mirrors.163.com/debian/ ${sver}-backports main non-free contrib
	EOF
	break
	;;
	7)
	cat > /etc/apt/sources.list <<-EOF
		deb https://mirrors.huaweicloud.com/debian/ ${sver} main non-free contrib
		deb-src https://mirrors.huaweicloud.com/debian/ ${sver} main non-free contrib
		deb https://mirrors.huaweicloud.com/debian-security/ ${sver}-security main
		deb-src https://mirrors.huaweicloud.com/debian-security/ ${sver}-security main
		deb https://mirrors.huaweicloud.com/debian/ ${sver}-updates main non-free contrib
		deb-src https://mirrors.huaweicloud.com/debian/ ${sver}-updates main non-free contrib
		deb https://mirrors.huaweicloud.com/debian/ ${sver}-backports main non-free contrib
		deb-src https://mirrors.huaweicloud.com/debian/ ${sver}-backports main non-free contrib
	EOF
	break
	;;
	*)
	TIME r "請輸入正確編碼！"
	;;
	esac
	done
	TIME g "apt源，更換完成!"
}
# CT範本國內源
ctsources() {
	cp -rf /usr/share/perl5/PVE/APLInfo.pm /usr/share/perl5/PVE/APLInfo.pm.bak
	echo " 請選擇您需要的CT範本國內源"
	echo " 1. 清華大學鏡像站"
	echo " 2. 中科大鏡像站"
	input="請輸入選擇[默認1]"
	while :; do
	read -t 30 -p " ${input}： " ctsource || echo
	ctsource=${ctsource:-1}
	case $ctsource in
	1)
	sed -i 's|http://download.proxmox.com|https://mirrors.tuna.tsinghua.edu.cn/proxmox|g' /usr/share/perl5/PVE/APLInfo.pm
	sed -i 's|http://mirrors.ustc.edu.cn/proxmox|https://mirrors.tuna.tsinghua.edu.cn/proxmox|g' /usr/share/perl5/PVE/APLInfo.pm
	break
	;;
	2)
	sed -i 's|http://download.proxmox.com|http://mirrors.ustc.edu.cn/proxmox|g' /usr/share/perl5/PVE/APLInfo.pm
	sed -i 's|https://mirrors.tuna.tsinghua.edu.cn/proxmox|http://mirrors.ustc.edu.cn/proxmox|g' /usr/share/perl5/PVE/APLInfo.pm
	break
	;;
	*)
	TIME r "請輸入正確編碼！"
	;;
	esac
	done
	TIME g "CT範本源，更換完成!"
}
# 更換使用幫助源
pvehelp(){
	cp -rf /etc/apt/sources.list.d/pve-no-subscription.list /etc/apt/backup/pve-no-subscription.list.bak
	cat > /etc/apt/sources.list.d/pve-no-subscription.list <<-EOF
deb https://mirrors.tuna.tsinghua.edu.cn/proxmox/debian ${sver} pve-no-subscription
EOF
	TIME g "使用幫助源，更換完成!"
}
# 關閉企業源
pveenterprise(){
	if [[ -f /etc/apt/sources.list.d/pve-enterprise.list ]];then
		cp -rf /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/backup/pve-enterprise.list.bak
		rm -rf /etc/apt/sources.list.d/pve-enterprise.list
		TIME g "CT範本源，更換完成!"
	else
		TIME g "pve-enterprise.list不存在，忽略!"
	fi
}
# 移除無效訂閱
novalidsub(){
	# 移除 Proxmox VE 無有效訂閱提示 (6.4-5、6、8、9 、13；7.0-9、10、11已測試通過)
	cp -rf /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.bak
	sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
	# sed -i 's#if (res === null || res === undefined || !res || res#if (false) {#g' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
	# sed -i '/data.status.toLowerCase/d' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
	TIME g "已移除訂閱提示!"
}
pvegpg(){
	cp -rf /etc/apt/trusted.gpg.d/proxmox-release-${sver}.gpg /etc/apt/backup/proxmox-release-${sver}.gpg.bak
	rm -rf /etc/apt/trusted.gpg.d/proxmox-release-${sver}.gpg
	wget -q --timeout=5 --tries=1 --show-progres http://mirrors.ustc.edu.cn/proxmox/debian/proxmox-release-${sver}.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-${sver}.gpg
	if [[ $? -ne 0 ]];then
		TIME r "嘗試重新下載..."
		wget -q --timeout=5 --tries=1 --show-progres http://mirrors.ustc.edu.cn/proxmox/debian/proxmox-release-${sver}.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-${sver}.gpg
			if [[ $? -ne 0 ]];then
				TIME r "下載秘鑰失敗，請檢查網路再嘗試!"
				sleep 2
				exit 1
		else
			TIME g "密匙下載完成!"
			fi
	else
		TIME g "密匙下載完成!"	
	fi
}
pve_optimization(){
	echo
	clear
	TIME y "提示：PVE原組態檔案放入/etc/apt/backup資料夾"
	[[ ! -d /etc/apt/backup ]] && mkdir -p /etc/apt/backup
	echo
	TIME y "※※※※※ 更換apt源... ※※※※※"
	aptsources
	echo
	TIME y "※※※※※ 更換CT範本源... ※※※※※"
	ctsources
	echo
	TIME y "※※※※※ 更換使用幫助源... ※※※※※"
	pvehelp
	echo
	TIME y "※※※※※ 關閉企業源... ※※※※※"
	pveenterprise
	echo
	TIME y "※※※※※ 移除 Proxmox VE 無有效訂閱提示... ※※※※※"
	novalidsub
	echo
	TIME y "※※※※※ 下載PVE7.0源的密匙... ※※※※※"
	pvegpg
	echo
	TIME y "※※※※※ 重新載入服務組態檔案、重啟web控制台... ※※※※※"
	systemctl daemon-reload && systemctl restart pveproxy.service && TIME g "服務重啟完成!"
	sleep 3
	echo
	TIME y "※※※※※ 更新源、安裝常用軟體和升級... ※※※※※"
	# apt-get update && apt-get install -y net-tools curl git
	# apt-get dist-upgrade -y
	TIME y "如需對PVE進行升級，請使用apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y"
	echo
	TIME g "修改完畢！"
}
#--------------PVE更換軟體源----------------


#--------------開啟硬體直通----------------
# 開啟硬體直通
enable_pass(){
	echo
	TIME y "開啟硬體直通..."
	if [ `dmesg | grep -e DMAR -e IOMMU|wc -l` = 0 ];then
		TIME r "您的硬體不支援直通！"
		pause
		menu
	fi
	if [ `cat /proc/cpuinfo|grep Intel|wc -l` = 0 ];then
		iommu="amd_iommu=on"
	else
		iommu="intel_iommu=on"
	fi
	if [ `grep $iommu /etc/default/grub|wc -l` = 0 ];then
		sed -i 's|quiet|quiet '$iommu'|' /etc/default/grub
		update-grub
		if [ `grep "vfio" /etc/modules|wc -l` = 0 ];then
			cat <<-EOF >> /etc/modules
				vfio
				vfio_iommu_type1
				vfio_pci
				vfio_virqfd
				kvmgt
			EOF
		fi
		
	if [ ! -f "/etc/modprobe.d/blacklist.conf" ];then
       echo "blacklist snd_hda_intel" >> /etc/modprobe.d/blacklist.conf 
       echo "blacklist snd_hda_codec_hdmi" >> /etc/modprobe.d/blacklist.conf 
       echo "blacklist i915" >> /etc/modprobe.d/blacklist.conf 
       fi


    if [ ! -f "/etc/modprobe.d/vfio.conf" ];then
      echo "options vfio-pci ids=8086:3185" >> /etc/modprobe.d/vfio.conf
       fi	
		TIME g "開啟設定後需要重啟系統，請稍後重啟。"
	else
		TIME r "您已經組態過!"
	   fi

}
# 關閉硬體直通
disable_pass(){
	echo
	TIME y "關閉硬體直通..."
	if [ `dmesg | grep -e DMAR -e IOMMU|wc -l` = 0 ];then
		TIME r "您的硬體不支援直通！"
		pause
		menu
	fi
	if [ `cat /proc/cpuinfo|grep Intel|wc -l` = 0 ];then
		iommu="amd_iommu=on"
	else
		iommu="intel_iommu=on"
	fi
	if [ `grep $iommu /etc/default/grub|wc -l` = 0 ];then
		TIME r "您還沒有組態過該項"
	else
		{
			sed -i 's/ '$iommu'//g' /etc/default/grub
			sed -i '/vfio/d' /etc/modules
			rm -rf /etc/modprobe.d/blacklist.conf
			rm -rf /etc/modprobe.d/vfio.conf
			sleep 1
		}|TIME g "關閉設定後需要重啟系統，請稍後重啟。"
		sleep 1
		update-grub
	fi
}
# 硬體直通菜單
hw_passth(){
	while :; do
		clear
		cat <<-EOF
`TIME y "	      組態硬體直通"`
┌──────────────────────────────────────────┐
    1. 開啟硬體直通
    2. 關閉硬體直通
├──────────────────────────────────────────┤
    0. 返回
└──────────────────────────────────────────┘
EOF
		echo -ne " 請選擇: [ ]\b\b"
		read -t 60 hwmenuid
		hwmenuid=${hwmenuid:-0}
		case "${hwmenuid}" in
		1)
			enable_pass
			pause
			hw_passth
			break
		;;
		2)
			disable_pass
			pause
			hw_passth
			break
		;;
		0)
			menu
			break
		;;
		*)
		;;
		esac
	done
}
#--------------開啟硬體直通----------------


#--------------設定CPU電源模式----------------

# 設定CPU電源模式
cpupower(){
	governors=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors`
	while :; do
		clear
		cat <<-EOF
`TIME y "	      設定CPU電源模式"`
┌──────────────────────────────────────────┐

    1. 設定CPU模式 conservative  保守模式
    2. 設定CPU模式 ondemand       按需模式		[默認]
    3. 設定CPU模式 powersave      節能模式
    4. 設定CPU模式 performance   性能模式
    5. 設定CPU模式 schedutil      負載模式

    6. 恢復系統默認電源設定

├──────────────────────────────────────────┤
    0. 返回
└──────────────────────────────────────────┘
EOF
		echo
		echo "部分CPU僅支援 performance 和 powersave 模式，只能選擇這兩項"
		echo
		echo "你的CPU支援 ${governors} 等模式"
		echo
		echo
		echo
		echo -ne " 請選擇: [ ]\b\b"
		read -t 60 cpupowerid
		cpupowerid=${cpupowerid:-2}
		case "${cpupowerid}" in
		1)
			GOVERNOR="conservative"
		;;
		2)
			GOVERNOR="ondemand"
		;;	
		3)
			GOVERNOR="powersave"
		;;
		4)
			GOVERNOR="performance"
		;;
		5)
			GOVERNOR="schedutil"
		;;
		6)
			cpupower_del
			break
		;;
		0)
			menu
			break
		;;
		*)
			echo "你的輸入無效 ,請重新輸入 !!!"
			pause
			cpupower
		;;
		esac
		if [[ ${GOVERNOR} != "" ]]; then
			if [[ -n `echo "${governors}" | grep -o "${GOVERNOR}"` ]]; then
				echo "您選擇的CPU模式：${GOVERNOR}"
				echo
				cpupower_add
			else
				echo "您的CPU不支援該模式！"
				cpupower
			fi
		fi
	done
}

# 修改CPU模式
cpupower_add(){
	echo "${GOVERNOR}" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
	echo "查看當前CPU模式"
	cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

	echo "加入開機任務"
	NEW_CRONTAB_COMMAND="sleep 10 && echo "${GOVERNOR}" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null #CPU Power Mode"
	EXISTING_CRONTAB=$(crontab -l 2>/dev/null)
     if [[ -n "$EXISTING_CRONTAB" ]]; then
       TEMP_CRONTAB_FILE=$(mktemp)
       echo "$EXISTING_CRONTAB" | grep -v "@reboot sleep 10 && echo*" > "$TEMP_CRONTAB_FILE"
       crontab "$TEMP_CRONTAB_FILE"
       rm "$TEMP_CRONTAB_FILE"
     fi
	# 修改完成
    (crontab -l 2>/dev/null; echo "@reboot $NEW_CRONTAB_COMMAND") | crontab -
    echo -e "\n檢查工作排程設定 (使用 'crontab -l' 命令來檢查)"

    pause
}

# 恢復系統默認電源設定
cpupower_del(){
	# 恢復性模式
	echo "performance" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
	# 刪除工作排程
    EXISTING_CRONTAB=$(crontab -l 2>/dev/null)
    if [[ -n "$EXISTING_CRONTAB" ]]; then
      TEMP_CRONTAB_FILE=$(mktemp)
      echo "$EXISTING_CRONTAB" | grep -v "@reboot sleep 10 && echo*" > "$TEMP_CRONTAB_FILE"
      crontab "$TEMP_CRONTAB_FILE"
      rm "$TEMP_CRONTAB_FILE"
    fi

    echo "已恢復系統默認電源設定！"
}
#--------------設定CPU電源模式----------------


#--------------CPU、主機板、硬碟溫度顯示----------------

# 安裝工具
cpu_add(){

nodes="/usr/share/perl5/PVE/API2/Nodes.pm"
pvemanagerlib="/usr/share/pve-manager/js/pvemanagerlib.js"
proxmoxlib="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"

pvever=$(pveversion | awk -F"/" '{print $2}')
echo pve版本$pvever

# 判斷是否已經執行過修改
[ ! -e $nodes.$pvever.bak ] || { echo 已經執行過修改，請勿重複執行; exit 1;}

# 輸入需要安裝的軟體包
packages=(lm-sensors nvme-cli sysstat linux-cpupower)

# 查詢軟體包，判斷是否安裝
for package in "${packages[@]}"; do
    if ! dpkg -s "$package" &> /dev/null; then
        echo "$package 未安裝，開始安裝軟體包"
        apt-get install "${packages[@]}" -y
        modprobe msr
        install=ok
        break
    fi
done

# 設定執行權限
if dpkg -s "linux-cpupower" &> /dev/null; then
    chmod +s /usr/sbin/linux-cpupower || echo "Failed to set permissions for /usr/sbin/linux-cpupower"
fi

chmod +s /usr/sbin/nvme
chmod +s /usr/sbin/hddtemp
chmod +s /usr/sbin/smartctl
chmod +s /usr/sbin/turbostat || echo "Failed to set permissions for /usr/sbin/turbostat"
modprobe msr && echo msr > /etc/modules-load.d/turbostat-msr.conf


# 軟體包安裝完成
if [ "$install" == "ok" ]; then
    echo 軟體包安裝完成，檢測硬體資訊
sensors-detect --auto > /tmp/sensors
drivers=`sed -n '/Chip drivers/,/\#----cut here/p' /tmp/sensors|sed '/Chip /d'|sed '/cut/d'`
if [ `echo $drivers|wc -w` = 0 ];then
    echo 沒有找到任何驅動，似乎你的系統不支援或驅動安裝失敗。
    pause
    menu
else
    for i in $drivers
    do
        modprobe $i
        if [ `grep $i /etc/modules|wc -l` = 0 ];then
            echo $i >> /etc/modules
        fi
    done
    sensors
    sleep 3
    echo 驅動資訊組態成功。
fi
/etc/init.d/kmod start
rm /tmp/sensors
# 驅動資訊組態完成
fi

echo 備份原始檔
# 刪除舊版本備份檔案
rm -f  $nodes.*.bak
rm -f  $pvemanagerlib.*.bak
rm -f  $proxmoxlib.*.bak
# 備份當前版本檔案
[ ! -e $nodes.$pvever.bak ] && cp $nodes $nodes.$pvever.bak
[ ! -e $pvemanagerlib.$pvever.bak ] && cp $pvemanagerlib $pvemanagerlib.$pvever.bak
[ ! -e $proxmoxlib.$pvever.bak ] && cp $proxmoxlib $proxmoxlib.$pvever.bak

# 生成系統變數
tmpf=tmpfile.temp
touch $tmpf
cat > $tmpf << 'EOF' 
	$res->{thermalstate} = `sensors`;
	$res->{cpusensors} = `cat /proc/cpuinfo | grep MHz && lscpu | grep MHz`;
	
	my $nvme0_temperatures = `smartctl -a /dev/nvme0|grep -E "Model Number|(?=Total|Namespace)[^:]+Capacity|Temperature:|Available Spare:|Percentage|Data Unit|Power Cycles|Power On Hours|Unsafe Shutdowns|Integrity Errors"`;
	my $nvme0_io = `iostat -d -x -k 1 1 | grep -E "^nvme0"`;
	$res->{nvme0_status} = $nvme0_temperatures . $nvme0_io;
	
	$res->{hdd_temperatures} = `smartctl -a /dev/sd?|grep -E "Device Model|Capacity|Power_On_Hours|Temperature"`;

	my $powermode = `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor && turbostat -S -q -s PkgWatt -i 0.1 -n 1 -c package | grep -v PkgWatt`;
	$res->{cpupower} = $powermode;

EOF

###################  修改node.pm   ##########################
echo 修改node.pm：
echo 找到關鍵字 PVE::pvecfg::version_text 的行號並跳到下一行
# 顯示匹配的行
ln=$(expr $(sed -n -e '/PVE::pvecfg::version_text/=' $nodes) + 1)
echo "匹配的行號：" $ln

echo 修改結果：
sed -i "${ln}r $tmpf" $nodes
# 顯示修改結果
sed -n '/PVE::pvecfg::version_text/,+18p' $nodes
rm $tmpf



###################  修改pvemanagerlib.js   ##########################
tmpf=tmpfile.temp
touch $tmpf
cat > $tmpf << 'EOF'

	{
          itemId: 'CPUW',
          colspan: 2,
          printBar: false,
          title: gettext('CPU功耗'),
          textField: 'cpupower',
          renderer:function(value){
			  const w0 = value.split('\n')[0].split(' ')[0];
			  const w1 = value.split('\n')[1].split(' ')[0];
			  return `CPU電源模式: ${w0} | CPU功耗: ${w1} W `
            }
	},

	{
          itemId: 'MHz',
          colspan: 2,
          printBar: false,
          title: gettext('CPU頻率'),
          textField: 'cpusensors',
          renderer:function(value){
			  const f0 = value.match(/cpu MHz.*?([\d]+)/)[1];
			  const f1 = value.match(/CPU min MHz.*?([\d]+)/)[1];
			  const f2 = value.match(/CPU max MHz.*?([\d]+)/)[1];
			  return `CPU即時: ${f0} MHz | 最小: ${f1} MHz | 最大: ${f2} MHz `
            }
	},
	
	{
          itemId: 'thermal',
          colspan: 2,
          printBar: false,
          title: gettext('CPU溫度'),
          textField: 'thermalstate',
          renderer:function(value){
              // const p0 = value.match(/Package id 0.*?\+([\d\.]+)Â/)[1];  // CPU包溫度
              const c0 = value.match(/Core 0.*?\+([\d\.]+)?/)[1];  // CPU核心1溫度
              const c1 = value.match(/Core 1.*?\+([\d\.]+)?/)[1];  // CPU核心2溫度
              const c2 = value.match(/Core 2.*?\+([\d\.]+)?/)[1];  // CPU核心3溫度
              const c3 = value.match(/Core 3.*?\+([\d\.]+)?/)[1];  // CPU核心4溫度
              const b0 = value.match(/temp1.*?\+([\d\.]+)?/)[1];  // 主機板溫度
              return ` 核心1: ${c0} ℃ | 核心2: ${c1} ℃ | 核心3: ${c2} ℃ | 核心4: ${c3} ℃ || 主機板: ${b0} ℃ `
            }
    },



	{
          itemId: 'HEXIN',
          colspan: 2,
          printBar: false,
          title: gettext('核心頻率'),
          textField: 'cpusensors',
          renderer:function(value){
			  const e0 = value.split('\n')[0].split(' ')[2];
			  const e1 = value.split('\n')[1].split(' ')[2];
			  const e2 = value.split('\n')[2].split(' ')[2];
			  const e3 = value.split('\n')[3].split(' ')[2];
			  return `核心1: ${e0} MHz | 核心2: ${e1} MHz | 核心3: ${e2} MHz | 核心4: ${e3} MHz `
            }
	},


	
	/* 檢測不到相關參數的可以註釋掉---需要的註釋本行即可
	// 風扇轉速
	{
          itemId: 'RPM',
          colspan: 2,
          printBar: false,
          title: gettext('CPU風扇'),
          textField: 'thermalstate',
          renderer:function(value){
			  const fan1 = value.match(/fan1:.*?\ ([\d.]+) R/)[1];
			  const fan2 = value.match(/fan2:.*?\ ([\d.]+) R/)[1];
			  if (fan1 === "0") {
			    fan11 = "停轉";
			  } else {
			    fan11 = fan1 + " RPM";
			  }
			  if (fan2 === "0") {
			    fan22 = "停轉";
			  } else {
			    fan22 = fan2 + " RPM";
			  }
			  return `CPU風扇: ${fan11} | 系統風扇: ${fan22}`
            }
	},
	檢測不到相關參數的可以註釋掉---需要的註釋本行即可  */

	// /* 檢測不到相關參數的可以註釋掉---需要的註釋本行即可
	// NVME硬碟溫度
	{
	    itemId: 'nvme0-status',
	    colspan: 2,
	    printBar: false,
	    title: gettext('NVME 硬碟'),
	    textField: 'nvme0_status',
	    renderer:function(value){
	        if (value.length > 0) {
	            value = value.replace(/Â/g, '');
	            let data = [];
	            let nvmes = value.matchAll(/(^(?:Model|Total|Temperature:|Available Spare:|Percentage|Data|Power|Unsafe|Integrity Errors|nvme)[\s\S]*)+/gm);
	            for (const nvme of nvmes) {
	                let nvmeNumber = 0;
	                data[nvmeNumber] = {
	                    Models: [],
	                    Integrity_Errors: [],
	                    Capacitys: [],
	                    Temperatures: [],
	                    Available_Spares: [],
	                    Useds: [],
	                    Reads: [],
	                    Writtens: [],
	                    Cycles: [],
	                    Hours: [],
	                    Shutdowns: [],
	                    States: [],
	                    r_kBs: [],
	                    r_awaits: [],
	                    w_kBs: [],
	                    w_awaits: [],
	                    utils: []
	                };

	                let Models = nvme[1].matchAll(/^Model Number: *([ \S]*)$/gm);
	                for (const Model of Models) {
	                    data[nvmeNumber]['Models'].push(Model[1]);
	                }

	                let Integrity_Errors = nvme[1].matchAll(/^Media and Data Integrity Errors: *([ \S]*)$/gm);
	                for (const Integrity_Error of Integrity_Errors) {
	                    data[nvmeNumber]['Integrity_Errors'].push(Integrity_Error[1]);
	                }

	                let Capacitys = nvme[1].matchAll(/^(?=Total|Namespace)[^:]+Capacity:[^\[]*\[([ \S]*)\]$/gm);
	                for (const Capacity of Capacitys) {
	                    data[nvmeNumber]['Capacitys'].push(Capacity[1]);
	                }

	                let Temperatures = nvme[1].matchAll(/^Temperature: *([\d]*)[ \S]*$/gm);
	                for (const Temperature of Temperatures) {
	                    data[nvmeNumber]['Temperatures'].push(Temperature[1]);
	                }

	                let Available_Spares = nvme[1].matchAll(/^Available Spare: *([\d]*%)[ \S]*$/gm);
	                for (const Available_Spare of Available_Spares) {
	                    data[nvmeNumber]['Available_Spares'].push(Available_Spare[1]);
	                }

	                let Useds = nvme[1].matchAll(/^Percentage Used: *([ \S]*)%$/gm);
	                for (const Used of Useds) {
	                    data[nvmeNumber]['Useds'].push(Used[1]);
	                }

	                let Reads = nvme[1].matchAll(/^Data Units Read:[^\[]*\[([ \S]*)\]$/gm);
	                for (const Read of Reads) {
	                    data[nvmeNumber]['Reads'].push(Read[1]);
	                }

	                let Writtens = nvme[1].matchAll(/^Data Units Written:[^\[]*\[([ \S]*)\]$/gm);
	                for (const Written of Writtens) {
	                    data[nvmeNumber]['Writtens'].push(Written[1]);
	                }

	                let Cycles = nvme[1].matchAll(/^Power Cycles: *([ \S]*)$/gm);
	                for (const Cycle of Cycles) {
	                    data[nvmeNumber]['Cycles'].push(Cycle[1]);
	                }

	                let Hours = nvme[1].matchAll(/^Power On Hours: *([ \S]*)$/gm);
	                for (const Hour of Hours) {
	                    data[nvmeNumber]['Hours'].push(Hour[1]);
	                }

	                let Shutdowns = nvme[1].matchAll(/^Unsafe Shutdowns: *([ \S]*)$/gm);
	                for (const Shutdown of Shutdowns) {
	                    data[nvmeNumber]['Shutdowns'].push(Shutdown[1]);
	                }

	                let States = nvme[1].matchAll(/^nvme\S+(( *\d+\.\d{2}){22})/gm);
	                for (const State of States) {
	                    data[nvmeNumber]['States'].push(State[1]);
	                    const IO_array = [...State[1].matchAll(/\d+\.\d{2}/g)];
	                    if (IO_array.length > 0) {
	                        data[nvmeNumber]['r_kBs'].push(IO_array[1]);
	                        data[nvmeNumber]['r_awaits'].push(IO_array[4]);
	                        data[nvmeNumber]['w_kBs'].push(IO_array[7]);
	                        data[nvmeNumber]['w_awaits'].push(IO_array[10]);
	                        data[nvmeNumber]['utils'].push(IO_array[21]);
	                    }
	                }

	                let output = '';
	                for (const [i, nvme] of data.entries()) {
	                    if (nvme.Models.length > 0) {
	                        for (const nvmeModel of nvme.Models) {
	                            output += `${nvmeModel}`;
	                        }
	                    }

	                    if (nvme.Integrity_Errors.length > 0) {
	                        for (const nvmeIntegrity_Error of nvme.Integrity_Errors) {
	                            if (nvmeIntegrity_Error != 0) {
	                                output += ` (`;
	                                output += `0E: ${nvmeIntegrity_Error}-故障！`;
	                                if (nvme.Available_Spares.length > 0) {
	                                    output += ', ';
	                                    for (const Available_Spare of nvme.Available_Spares) {
	                                        output += `備用空間: ${Available_Spare}`;
	                                    }
	                                }
	                                output += `)`;
	                            }
	                        }
	                    }

	                    if (nvme.Capacitys.length > 0) {
	                        output += ' | ';
	                        for (const nvmeCapacity of nvme.Capacitys) {
	                            output += `容量: ${nvmeCapacity.replace(/ |,/gm, '')}`;
	                        }
	                    }

	                    if (nvme.Useds.length > 0) {
	                        output += ' | ';
	                        for (const nvmeUsed of nvme.Useds) {
	                            output += `壽命: ${100-Number(nvmeUsed)}% `;
	                            if (nvme.Reads.length > 0) {
	                                output += '(';
	                                for (const nvmeRead of nvme.Reads) {
	                                    output += `已讀${nvmeRead.replace(/ |,/gm, '')}`;
	                                    output += ')';
	                                }
	                            }

	                            if (nvme.Writtens.length > 0) {
	                                output = output.slice(0, -1);
	                                output += ', ';
	                                for (const nvmeWritten of nvme.Writtens) {
	                                    output += `已寫${nvmeWritten.replace(/ |,/gm, '')}`;
	                                }
	                                output += ')';
	                            }
	                        }
	                    }

	                    if (nvme.Temperatures.length > 0) {
	                        output += ' | ';
	                        for (const nvmeTemperature of nvme.Temperatures) {
	                            output += `溫度: ${nvmeTemperature}°C`;
	                        }
	                    }

	                    if (nvme.States.length > 0) {
	                        if (nvme.Models.length > 0) {
	                            output += '\n';
	                        }

	                        output += 'I/O: ';
	                        if (nvme.r_kBs.length > 0 || nvme.r_awaits.length > 0) {
	                            output += '讀-';
	                            if (nvme.r_kBs.length > 0) {
	                                for (const nvme_r_kB of nvme.r_kBs) {
	                                    var nvme_r_mB = `${nvme_r_kB}` / 1024;
	                                    nvme_r_mB = nvme_r_mB.toFixed(2);
	                                    output += `速度${nvme_r_mB}MB/s`;
	                                }
	                            }
	                            if (nvme.r_awaits.length > 0) {
	                                for (const nvme_r_await of nvme.r_awaits) {
	                                    output += `, 延遲${nvme_r_await}ms / `;
	                                }
	                            }
	                        }

	                        if (nvme.w_kBs.length > 0 || nvme.w_awaits.length > 0) {
	                            output += '寫-';
	                            if (nvme.w_kBs.length > 0) {
	                                for (const nvme_w_kB of nvme.w_kBs) {
	                                    var nvme_w_mB = `${nvme_w_kB}` / 1024;
	                                    nvme_w_mB = nvme_w_mB.toFixed(2);
	                                    output += `速度${nvme_w_mB}MB/s`;
	                                }
	                            }
	                            if (nvme.w_awaits.length > 0) {
	                                for (const nvme_w_await of nvme.w_awaits) {
	                                    output += `, 延遲${nvme_w_await}ms | `;
	                                }
	                            }
	                        }

	                        if (nvme.utils.length > 0) {
	                            for (const nvme_util of nvme.utils) {
	                                output += `負載${nvme_util}%`;
	                            }
	                        }
	                    }

                        if (nvme.Cycles.length > 0) {
                            output += '\n';
                            for (const nvmeCycle of nvme.Cycles) {
                                output += `通電: ${nvmeCycle.replace(/ |,/gm, '')}次`;
                            }

                            if (nvme.Shutdowns.length > 0) {
                                output += ', ';
                                for (const nvmeShutdown of nvme.Shutdowns) {
                                    output += `不安全斷電${nvmeShutdown.replace(/ |,/gm, '')}次`;
                                    break
                                }
                            }

                            if (nvme.Hours.length > 0) {
                                output += ', ';
                                for (const nvmeHour of nvme.Hours) {
                                    output += `累計${nvmeHour.replace(/ |,/gm, '')}小時`;
                                }
                            }
                        }
	                    //output = output.slice(0, -3);
	                }
	                return output.replace(/\n/g, '<br>');
	            }
	        } else {
	            return `提示: 未安裝 NVME 或已直通 NVME 控製器！`;
	        }
	    }
	},
	// 檢測不到相關參數的可以註釋掉---需要的註釋本行即可  */

          // SATA硬碟溫度
          {
          itemId: 'hdd-temperatures',
          colspan: 2,
          printBar: false,
          title: gettext('SATA硬碟'),
          textField: 'hdd_temperatures',
          renderer:function(value){
          if (value.length > 0) {
          let devices = value.matchAll(/(\s*Model.*:\s*[\s\S]*?\n){1,2}^User.*\[([\s\S]*?)\]\n^\s*9[\s\S]*?\-\s*([\d]+)[\s\S]*?(\n(^19[0,4][\s\S]*?$){1,2}|\s{0}$)/gm);
          for (const device of devices) {
          if(device[1].indexOf("Family") !== -1){
          devicemodel = device[1].replace(/.*Model Family:\s*([\s\S]*?)\n^Device Model:\s*([\s\S]*?)\n/m, '$1 - $2');
          } else {
          devicemodel = device[1].replace(/.*Model:\s*([\s\S]*?)\n/m, '$1');
          }
          device[2] = device[2].replace(/ |,/gm, '');
          if(value.indexOf("Min/Max") !== -1){
          let devicetemps = device[5].matchAll(/19[0,4][\s\S]*?\-\s*(\d+)(\s\(Min\/Max\s(\d+)\/(\d+)\)$|\s{0}$)/gm);
          for (const devicetemp of devicetemps) {
          value = `${devicemodel} | 容量: ${device[2]} | 已通電: ${device[3]}小時 | 溫度: ${devicetemp[1]}°C\n`;
          }
          } else if (value.indexOf("Temperature") !== -1){
          let devicetemps = device[5].matchAll(/19[0,4][\s\S]*?\-\s*(\d+)/gm);
          for (const devicetemp of devicetemps) {
          value = `${devicemodel} | 容量: ${device[2]} | 已通電: ${device[3]}小時 | 溫度: ${devicetemp[1]}°C\n`;
          }
          } else {
          value = `${devicemodel} | 容量: ${device[2]} | 已通電: ${device[3]}小時 | 提示: 未檢測到溫度感測器\n`;
          }
          }
          return value.replace(/\n/g, '<br>');
          } else { 
          return `提示: 未安裝硬碟或已直通硬碟控製器`;
          }
          }
          },
EOF

echo 找到關鍵字pveversion的行號
# 顯示匹配的行
ln=$(sed -n '/pveversion/,+10{/},/{=;q}}' $pvemanagerlib)
echo "匹配的行號pveversion：" $ln

echo 修改結果：
sed -i "${ln}r $tmpf" $pvemanagerlib
# 顯示修改結果
# sed -n '/pveversion/,+30p' $pvemanagerlib
rm $tmpf


echo 修改頁面高度
# 修改並顯示修改結果,位置10288行,原始值400
# sed -i -r '/\[logView\]/,+5{/heigh/{s#[0-9]+#700#;}}' $pvemanagerlib
# sed -n '/\[logView\]/,+5{/heigh/{p}}' $pvemanagerlib
# 修改並顯示修改結果,位置36495行,原始值300
sed -i -r '/widget\.pveNodeStatus/,+5{/height/{s#[0-9]+#480#}}' $pvemanagerlib
sed -n '/widget\.pveNodeStatus/,+5{/height/{p}}' $pvemanagerlib
## 兩處 height 的值需按情況修改，每多一行資料增加 20

# 調整顯示佈局
ln=$(expr $(sed -n -e '/widget.pveDcGuests/=' $pvemanagerlib) + 10)
sed -i "${ln}a\		textAlign: 'right'," $pvemanagerlib
ln=$(expr $(sed -n -e '/widget.pveNodeStatus/=' $pvemanagerlib) + 10)
sed -i "${ln}a\		textAlign: 'right'," $pvemanagerlib

###################  修改proxmoxlib.js   ##########################


echo 修改去除訂閱彈窗
sed -r -i '/\/nodes\/localhost\/subscription/,+10{/^\s+if \(res === null /{N;s#.+#\t\t  if(false){#}}' $proxmoxlib
# 顯示修改結果
sed -n '/\/nodes\/localhost\/subscription/,+10p' $proxmoxlib

systemctl restart pveproxy

echo "請刷新瀏覽器快取shift+f5"


}

# 刪除工具
cpu_del(){

nodes="/usr/share/perl5/PVE/API2/Nodes.pm"
pvemanagerlib="/usr/share/pve-manager/js/pvemanagerlib.js"
proxmoxlib="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"

pvever=$(pveversion | awk -F"/" '{print $2}')
echo pve版本$pvever
if [ -f "$nodes.$pvever.bak" ];then
rm -f $nodes $pvemanagerlib $proxmoxlib
mv $nodes.$pvever.bak $nodes
mv $pvemanagerlib.$pvever.bak $pvemanagerlib
mv $proxmoxlib.$pvever.bak $proxmoxlib

echo "已刪除溫度顯示，請重新刷新瀏覽器快取."
else
echo "你沒有加入過溫度顯示，退出指令碼."
fi


}

#--------------CPU、主機板、硬碟溫度顯示----------------



# 主菜單
menu(){
	cat <<-EOF

`TIME y "	      PVE最佳化指令碼     "`
┌──────────────────────────────────────────┐
    1. 一鍵最佳化PVE(換源、去訂閱等)
    2. 組態PCI硬體直通
    3. 設定CPU電源模式
    4. 加入CPU、主機板、硬碟溫度顯示
    5. 刪除CPU、主機板、硬碟溫度顯示
├──────────────────────────────────────────┤
    0. 退出
└──────────────────────────────────────────┘

EOF
	echo -ne " 請選擇: [ ]\b\b"
	read -t 60 menuid
	menuid=${menuid:-0}
	case ${menuid} in
	1)
		pve_optimization
		echo
		pause
		menu
	;;
	2)
		hw_passth
		echo
		pause
		menu
	;;
	3)
		cpupower
		echo
		pause
		menu
	;;
	4)
		cpu_add
		echo
		pause
		menu
	;;
	5)
		cpu_del
		echo
		pause
		menu
	;;
	0)
		clear
		exit 0
	;;
	*)
		echo "你的輸入無效 ,請重新輸入 !!!"
		pause
		menu
	;;
	esac
}
menu
