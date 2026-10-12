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
# 台灣鏡像站（2026-10 測試可用）。
# Proxmox 套件與 CT 範本目前只有台灣數位串流（TWDS）提供台灣鏡像。
PVE_TW_PROXMOX_MIRROR="https://mirror.twds.com.tw/proxmox"
PVE_OFFICIAL_PROXMOX="http://download.proxmox.com"
DEBIAN_OFFICIAL_SECURITY="http://security.debian.org/debian-security"
PVE_ARCHIVE_KEYRING="/usr/share/keyrings/proxmox-archive-keyring.gpg"
DEBIAN_ARCHIVE_KEYRING="/usr/share/keyrings/debian-archive-keyring.gpg"

# 依 Debian 主版本號取得代號
debian_codename() {
	case "$(cut -d. -f1 /etc/debian_version)" in
	13 ) echo "trixie" ;;
	12 ) echo "bookworm" ;;
	11 ) echo "bullseye" ;;
	10 ) echo "buster" ;;
	9 ) echo "stretch" ;;
	8 ) echo "jessie" ;;
	7 ) echo "wheezy" ;;
	6 ) echo "squeeze" ;;
	* ) echo "" ;;
	esac
}

# Debian 13（PVE 9）起改用 deb822 格式的 .sources 檔
is_deb822_release() {
	case "$1" in
	bookworm|bullseye|buster|stretch|jessie|wheezy|squeeze) return 1 ;;
	*) return 0 ;;
	esac
}

debian_components() {
	case "$1" in
	trixie|bookworm) echo "main contrib non-free non-free-firmware" ;;
	*) echo "main contrib non-free" ;;
	esac
}

debian_security_suite() {
	case "$1" in
	buster|stretch|jessie|wheezy|squeeze) echo "$1/updates" ;;
	*) echo "$1-security" ;;
	esac
}

# 輸出 Debian 來源內容：$1=代號 $2=主鏡像 $3=安全性更新鏡像
debian_sources_content() {
	local sver="$1" mirror="$2" security="$3" comp suite secsuite
	comp=$(debian_components "$sver")
	secsuite=$(debian_security_suite "$sver")
	if is_deb822_release "$sver"; then
		printf 'Types: deb\nURIs: %s/\nSuites: %s %s-updates %s-backports\nComponents: %s\nSigned-By: %s\n\n' \
			"$mirror" "$sver" "$sver" "$sver" "$comp" "$DEBIAN_ARCHIVE_KEYRING"
		printf 'Types: deb\nURIs: %s/\nSuites: %s\nComponents: %s\nSigned-By: %s\n' \
			"$security" "$secsuite" "$comp" "$DEBIAN_ARCHIVE_KEYRING"
	else
		for suite in "$sver" "$sver-updates" "$sver-backports"; do
			printf 'deb %s/ %s %s\ndeb-src %s/ %s %s\n' "$mirror" "$suite" "$comp" "$mirror" "$suite" "$comp"
		done
		printf 'deb %s/ %s %s\ndeb-src %s/ %s %s\n' "$security" "$secsuite" "$comp" "$security" "$secsuite" "$comp"
	fi
}

# 輸出 Proxmox 免訂閱源內容：$1=代號 $2=Proxmox 鏡像根目錄
pve_sources_content() {
	if is_deb822_release "$1"; then
		printf 'Types: deb\nURIs: %s/debian/pve\nSuites: %s\nComponents: pve-no-subscription\nSigned-By: %s\n' \
			"$2" "$1" "$PVE_ARCHIVE_KEYRING"
	else
		printf 'deb %s/debian/pve %s pve-no-subscription\n' "$2" "$1"
	fi
}

# apt台灣源
aptsources() {
	local mirror security
	sver=$(debian_codename)
	if [ ! $sver ];then
		TIME r "您的版本不支援！"
		exit 1
	fi
	echo " 請選擇您需要的apt台灣鏡像站"
	echo " 1. 台灣數位串流 TWDS（含安全性更新）"
	echo " 2. 國家高速網路中心 NCHC"
	echo " 3. 陽明交大資工系"
	echo " 4. Debian 官方台灣鏡像站"
	echo " 註：2～4 未提供安全性更新，安全性更新改用 Debian 官方源。"
	input="請輸入選擇[默認1]"
	while :; do
	read -t 30 -p " ${input}： " aptsource || echo
	aptsource=${aptsource:-1}
	case $aptsource in
	1)
		mirror="https://mirror.twds.com.tw/debian"
		security="https://mirror.twds.com.tw/debian-security"
		break
	;;
	2)
		mirror="http://free.nchc.org.tw/debian"
		security="$DEBIAN_OFFICIAL_SECURITY"
		break
	;;
	3)
		mirror="https://debian.cs.nycu.edu.tw/debian"
		security="$DEBIAN_OFFICIAL_SECURITY"
		break
	;;
	4)
		mirror="http://ftp.tw.debian.org/debian"
		security="$DEBIAN_OFFICIAL_SECURITY"
		break
	;;
	*)
	TIME r "請輸入正確編碼！"
	;;
	esac
	done
	[[ -f /etc/apt/sources.list ]] && cp -f /etc/apt/sources.list /etc/apt/backup/sources.list.bak
	if is_deb822_release "$sver"; then
		[[ -f /etc/apt/sources.list.d/debian.sources ]] && cp -f /etc/apt/sources.list.d/debian.sources /etc/apt/backup/debian.sources.bak
		debian_sources_content "$sver" "$mirror" "$security" > /etc/apt/sources.list.d/debian.sources
		# 舊格式檔案清空，避免與 debian.sources 重複
		: > /etc/apt/sources.list
	else
		debian_sources_content "$sver" "$mirror" "$security" > /etc/apt/sources.list
	fi
	TIME g "apt源，更換完成!"
}
# CT範本台灣源
ctsources() {
	local aplinfo=/usr/share/perl5/PVE/APLInfo.pm target
	cp -rf $aplinfo $aplinfo.bak
	echo " 請選擇您需要的CT範本源"
	echo " 1. 台灣數位串流 TWDS"
	echo " 2. Proxmox 官方源（還原）"
	input="請輸入選擇[默認1]"
	while :; do
	read -t 30 -p " ${input}： " ctsource || echo
	ctsource=${ctsource:-1}
	case $ctsource in
	1)
		target="$PVE_TW_PROXMOX_MIRROR"
		break
	;;
	2)
		target="$PVE_OFFICIAL_PROXMOX"
		break
	;;
	*)
	TIME r "請輸入正確編碼！"
	;;
	esac
	done
	# 同時取代官方源與舊版指令碼設定過的鏡像站
	sed -i -E "s#(https?://download\.proxmox\.com|https?://mirrors\.tuna\.tsinghua\.edu\.cn/proxmox|https?://mirrors\.ustc\.edu\.cn/proxmox|https?://mirror\.twds\.com\.tw/proxmox)/images#${target}/images#g" $aplinfo
	TIME g "CT範本源，更換完成!"
}
# 更換Proxmox免訂閱源
pvehelp(){
	local d=/etc/apt/sources.list.d f
	if is_deb822_release "$sver"; then
		# 移走舊的免訂閱源設定，避免重複
		for f in pve-no-subscription.list proxmox.sources; do
			[[ -f $d/$f ]] && mv -f $d/$f /etc/apt/backup/$f.bak
		done
		pve_sources_content "$sver" "$PVE_TW_PROXMOX_MIRROR" > $d/proxmox.sources
	else
		[[ -f $d/pve-no-subscription.list ]] && cp -rf $d/pve-no-subscription.list /etc/apt/backup/pve-no-subscription.list.bak
		pve_sources_content "$sver" "$PVE_TW_PROXMOX_MIRROR" > $d/pve-no-subscription.list
	fi
	TIME g "Proxmox免訂閱源，更換完成!"
}
# 關閉企業源（PVE 與 Ceph）
pveenterprise(){
	local d=/etc/apt/sources.list.d f found=0
	for f in $d/*.list $d/*.sources; do
		[[ -f $f ]] || continue
		grep -q "enterprise\.proxmox\.com" "$f" || continue
		cp -f "$f" "/etc/apt/backup/$(basename "$f").bak"
		if [[ $f == *.list ]]; then
			sed -i -E 's|^([[:space:]]*deb.*enterprise\.proxmox\.com)|# \1|' "$f"
		elif grep -q "^Enabled:" "$f"; then
			sed -i 's/^Enabled:.*/Enabled: no/' "$f"
		else
			# 插在企業源 URIs 之後，確保屬於同一段設定
			sed -i -E '/^URIs:.*enterprise\.proxmox\.com/a Enabled: no' "$f"
		fi
		TIME g "已關閉企業源：$(basename "$f")"
		found=1
	done
	[[ $found -eq 1 ]] || TIME g "未找到企業源，忽略!"
}
# 移除無效訂閱
novalidsub(){
	# 移除 Proxmox VE 無有效訂閱提示 (6.4-5、6、8、9 、13；7.0-9、10、11、9.2已測試通過)
	cp -rf /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.bak
	sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
	# sed -i 's#if (res === null || res === undefined || !res || res#if (false) {#g' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
	# sed -i '/data.status.toLowerCase/d' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
	TIME g "已移除訂閱提示!"
}
pvegpg(){
	# PVE 9 起金鑰由 proxmox-archive-keyring 套件提供，不需另外下載
	if is_deb822_release "$sver"; then
		if [[ -f $PVE_ARCHIVE_KEYRING ]]; then
			TIME g "已使用系統內建的 Proxmox 金鑰!"
			return 0
		fi
		TIME r "找不到 $PVE_ARCHIVE_KEYRING，請先安裝 proxmox-archive-keyring 套件!"
		exit 1
	fi
	# 台灣鏡像站未提供金鑰檔，改從 Proxmox 官方下載
	[[ -f /etc/apt/trusted.gpg.d/proxmox-release-${sver}.gpg ]] && cp -rf /etc/apt/trusted.gpg.d/proxmox-release-${sver}.gpg /etc/apt/backup/proxmox-release-${sver}.gpg.bak
	local url="$PVE_OFFICIAL_PROXMOX/debian/proxmox-release-${sver}.gpg" tmp=/etc/apt/trusted.gpg.d/proxmox-release-${sver}.gpg.tmp
	if wget -q --timeout=5 --tries=2 "$url" -O "$tmp" && [[ -s $tmp ]]; then
		mv -f "$tmp" /etc/apt/trusted.gpg.d/proxmox-release-${sver}.gpg
		TIME g "金鑰下載完成!"
	else
		rm -f "$tmp"
		TIME r "下載金鑰失敗，請檢查網路再嘗試!"
		sleep 2
		exit 1
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
	TIME y "※※※※※ 更換Proxmox免訂閱源... ※※※※※"
	pvehelp
	echo
	TIME y "※※※※※ 關閉企業源... ※※※※※"
	pveenterprise
	echo
	TIME y "※※※※※ 移除 Proxmox VE 無有效訂閱提示... ※※※※※"
	novalidsub
	echo
	TIME y "※※※※※ 設定Proxmox套件金鑰... ※※※※※"
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
# 適用 PVE 8 與 PVE 9。採集工作在 root systemd service 執行，API 僅讀取 JSON 快取。

pve_hw_require(){
    if [ "${EUID}" -ne 0 ]; then
        echo "請以 root 執行。" >&2
        return 1
    fi
    command -v pveversion >/dev/null || return 1
    case "$(pveversion | cut -d/ -f2)" in
        8.*|9.*) ;;
        *) echo "此資訊顯示修正版目前支援 PVE 8 與 PVE 9；其他版本請先驗證相容性。" >&2; return 1 ;;
    esac
}

# 從目前已安裝版本的官方套件取得原始檔，避免覆寫舊備份或重複插入程式碼。
pve_hw_pristine(){
    local stage="$1" version="$2" candidate deb=""
    for candidate in /var/cache/apt/archives/pve-manager_*_all.deb; do
        [ -f "$candidate" ] || continue
        if [ "$(dpkg-deb -f "$candidate" Package)" = pve-manager ] &&
           [ "$(dpkg-deb -f "$candidate" Version)" = "$version" ]; then
            deb="$candidate"
            break
        fi
    done
    if [ -z "$deb" ]; then
        (cd "$stage" && apt-get download "pve-manager=$version")
        for candidate in "$stage"/pve-manager_*.deb; do
            [ -f "$candidate" ] || continue
            if [ "$(dpkg-deb -f "$candidate" Package)" = pve-manager ] &&
               [ "$(dpkg-deb -f "$candidate" Version)" = "$version" ]; then
                deb="$candidate"
                break
            fi
        done
    fi
    [ -n "$deb" ] || { echo "無法取得目前版本的 pve-manager 原始套件。" >&2; return 1; }
    dpkg-deb -x "$deb" "$stage/package"
}

# 只接管本功能與舊版選項 4 的修改；遇到其他客製內容先停止。
pve_hw_check_existing(){
    python3 - "$1" <<'PVE_HW_CHECK_PY'
from pathlib import Path
import sys
base = Path(sys.argv[1]) / 'package'
files = [('/usr/share/perl5/PVE/API2/Nodes.pm', ('BEGIN local hardware summary', '$res->{thermalstate}')),
         ('/usr/share/pve-manager/js/pvemanagerlib.js', ('BEGIN local hardware summary', "itemId: 'CPUW'"))]
for filename, markers in files:
    current = Path(filename).read_text()
    original = (base / filename.lstrip('/')).read_text()
    if current != original and not any(marker in current for marker in markers):
        raise SystemExit('檔案含有未識別的客製修改，為避免覆寫已停止：' + filename)
PVE_HW_CHECK_PY
}

pve_hw_atomic_install(){
    local source="$1" destination="$2" mode="$3"
    install -m "$mode" "$source" "${destination}.pve-hardware-new"
    mv -f -- "${destination}.pve-hardware-new" "$destination"
}

# 延後優雅重新載入，確保網頁 Shell 斷線時安裝已完整提交。
pve_hw_reload_later(){
    systemd-run --quiet --unit="pve-hardware-ui-reload-${BASHPID}-${RANDOM}" \
        --on-active=3s --collect /bin/systemctl reload pvedaemon pveproxy
}

cpu_add(){ (
    set -euo pipefail
    pve_hw_require
    if ! command -v python3 >/dev/null || ! command -v smartctl >/dev/null; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y python3 smartmontools
    fi
    local stage version backup deployment_started=0
    stage=$(mktemp -d /var/tmp/pve-hardware.XXXXXX)
    version=$(dpkg-query -W -f='${Version}' pve-manager)
    backup="/var/lib/pve-hardware-summary/backups/$version"
    pve_hw_add_cleanup(){
        local result=$?
        trap - EXIT HUP INT TERM
        set +e
        if [ "$result" -ne 0 ] && [ "$deployment_started" -eq 1 ]; then
            pve_hw_atomic_install "$stage/Nodes.pm.before" /usr/share/perl5/PVE/API2/Nodes.pm 644
            pve_hw_atomic_install "$stage/pvemanagerlib.js.before" /usr/share/pve-manager/js/pvemanagerlib.js 644
            pve_hw_reload_later
            echo "安裝未完成，已回復本次修改前的 API 與介面檔案。" >&2
        fi
        rm -rf -- "$stage"
        exit "$result"
    }
    trap pve_hw_add_cleanup EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM
    pve_hw_pristine "$stage" "$version"
    pve_hw_check_existing "$stage"
    cp -a /usr/share/perl5/PVE/API2/Nodes.pm "$stage/Nodes.pm.before"
    cp -a /usr/share/pve-manager/js/pvemanagerlib.js "$stage/pvemanagerlib.js.before"
    cat > "$stage/pve-hardware-status.py" <<'PVE_HW_COLLECTOR_PY'
#!/usr/bin/python3
"""Cache read-only hardware telemetry for the local Proxmox summary page."""
import json
import math
import os
from pathlib import Path
import re
import subprocess
import time

CACHE = Path('/run/pve-hardware-status.json')


def read(path):
    try:
        return Path(path).read_text().strip()
    except OSError:
        return None


def number(path, divisor=1):
    try:
        value = float(read(path)) / divisor
        return value if math.isfinite(value) else None
    except (TypeError, ValueError):
        return None


def main():
    now = time.time()
    data = {'updated_at': int(now), 'cpu_temperatures': [], 'board_temperatures': [],
            'fans': [], 'frequencies_mhz': [], 'disks': []}
    for hwmon in sorted(Path('/sys/class/hwmon').glob('hwmon*')):
        name = read(hwmon / 'name') or hwmon.name
        for value_file in sorted(hwmon.glob('temp*_input')):
            temperature = number(value_file, 1000)
            if temperature is None:
                continue
            label = read(value_file.with_name(value_file.name.replace('_input', '_label'))) or name
            item = {'label': label, 'celsius': round(temperature, 1)}
            if name in ('coretemp', 'k10temp', 'zenpower'):
                data['cpu_temperatures'].append(item)
            elif not name.startswith(('iwlwifi', 'nvme', 'acpitz')):
                data['board_temperatures'].append(item)
        for value_file in sorted(hwmon.glob('fan*_input')):
            rpm = number(value_file)
            if rpm is not None:
                label = read(value_file.with_name(value_file.name.replace('_input', '_label'))) or value_file.stem
                data['fans'].append({'label': label, 'rpm': int(rpm)})

    cpus = sorted(Path('/sys/devices/system/cpu').glob('cpu[0-9]*'),
                  key=lambda path: int(path.name[3:]))
    for cpu in cpus:
        frequency = number(cpu / 'cpufreq/scaling_cur_freq', 1000)
        if frequency is not None:
            data['frequencies_mhz'].append({'cpu': int(cpu.name[3:]), 'mhz': round(frequency)})
    data['governor'] = read('/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor')
    data['min_mhz'] = number('/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq', 1000)
    data['max_mhz'] = number('/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq', 1000)

    # Package power only; it is not the whole computer's wall-socket consumption.
    rapl = Path('/sys/class/powercap/intel-rapl:0')
    first = number(rapl / 'energy_uj')
    limit = number(rapl / 'max_energy_range_uj')
    data['package_watts'] = None
    if first is not None and limit and (read(rapl / 'name') or '').startswith('package-'):
        start = time.monotonic()
        time.sleep(0.2)
        second = number(rapl / 'energy_uj')
        duration = time.monotonic() - start
        if second is not None:
            data['package_watts'] = round(((second - first) % limit) / 1000000 / duration, 2)

    # Avoid repeated SMART reads on each web request; refresh disk data once a minute.
    try:
        previous = json.loads(CACHE.read_text())
    except (OSError, ValueError):
        previous = {}
    if 0 <= now - previous.get('disks_updated_at', 0) < 60:
        data['disks'] = previous.get('disks', [])
        data['disks_updated_at'] = previous['disks_updated_at']
    else:
        data['disks_updated_at'] = int(now)
        for block in sorted(Path('/sys/block').iterdir()):
            if not re.fullmatch(r'sd[a-z]+|nvme[0-9]+n[0-9]+', block.name):
                continue
            if read(block / 'removable') != '0':
                continue
            try:
                result = subprocess.run(['/usr/sbin/smartctl', '-j', '-n', 'standby', '-A', '-i', '/dev/' + block.name],
                                        capture_output=True, text=True, timeout=3)
                disk = json.loads(result.stdout)
            except (OSError, subprocess.TimeoutExpired, ValueError):
                continue
            item = {'device': block.name, 'model': disk.get('model_name') or disk.get('model_number') or block.name,
                    'bytes': disk.get('user_capacity', {}).get('bytes'),
                    'hours': disk.get('power_on_time', {}).get('hours'),
                    'celsius': disk.get('temperature', {}).get('current')}
            data['disks'].append(item)

    temporary = CACHE.with_suffix('.json.tmp')
    temporary.write_text(json.dumps(data, ensure_ascii=False, allow_nan=False) + '\n')
    temporary.chmod(0o644)
    os.replace(temporary, CACHE)


if __name__ == '__main__':
    main()
PVE_HW_COLLECTOR_PY
    cat > "$stage/pve-hardware-status.service" <<'PVE_HW_SERVICE'
[Unit]
Description=Cache hardware readings for Proxmox node summary
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 /usr/local/libexec/pve-hardware-status.py
TimeoutStartSec=15
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/run
PrivateTmp=yes
PVE_HW_SERVICE
    cat > "$stage/pve-hardware-status.timer" <<'PVE_HW_TIMER'
[Unit]
Description=Refresh Proxmox hardware readings every ten seconds

[Timer]
OnBootSec=10s
OnUnitActiveSec=10s
AccuracySec=1s
Unit=pve-hardware-status.service

[Install]
WantedBy=timers.target
PVE_HW_TIMER
    cat > "$stage/hardware-summary-rows.js" <<'PVE_HW_ROWS_JS'
        // BEGIN local hardware summary: cached data, optional sensors.
        {
            itemId: 'hardware-cpu-temperature',
            colspan: 2,
            printBar: false,
            title: gettext('CPU 溫度'),
            textField: 'hardware_info',
            value: {},
            renderer: function(data) {
                const entries = Array.isArray(data?.cpu_temperatures) ? data.cpu_temperatures : [];
                return entries.filter(item => Number.isFinite(item?.celsius)).map(item =>
                    Ext.String.htmlEncode(String(item.label)) + ': ' + item.celsius.toFixed(1) + ' °C'
                ).join(' | ') || '未提供';
            },
        },
        {
            itemId: 'hardware-cpu-frequency',
            colspan: 2,
            printBar: false,
            title: gettext('CPU 頻率'),
            textField: 'hardware_info',
            value: {},
            renderer: function(data) {
                const entries = Array.isArray(data?.frequencies_mhz) ? data.frequencies_mhz : [];
                const values = entries.filter(item => Number.isFinite(item?.mhz)).map(item =>
                    'CPU ' + item.cpu + ': ' + Math.round(item.mhz) + ' MHz'
                );
                if (Number.isFinite(data?.min_mhz) && Number.isFinite(data?.max_mhz)) {
                    values.push('範圍: ' + Math.round(data.min_mhz) + '–' + Math.round(data.max_mhz) + ' MHz');
                }
                return values.join(' | ') || '未提供';
            },
        },
        {
            itemId: 'hardware-cpu-power',
            colspan: 2,
            printBar: false,
            title: gettext('CPU 封裝功耗'),
            textField: 'hardware_info',
            value: {},
            renderer: function(data) {
                const watts = Number.isFinite(data?.package_watts) ? data.package_watts.toFixed(2) + ' W' : '未提供';
                const mode = data?.governor ? Ext.String.htmlEncode(String(data.governor)) : '未提供';
                return watts + ' | 電源模式: ' + mode;
            },
        },
        {
            itemId: 'hardware-board-fans',
            colspan: 2,
            printBar: false,
            title: gettext('主機板／風扇'),
            textField: 'hardware_info',
            value: {},
            renderer: function(data) {
                const temperatures = Array.isArray(data?.board_temperatures) ? data.board_temperatures : [];
                const fans = Array.isArray(data?.fans) ? data.fans : [];
                const board = temperatures.filter(item => Number.isFinite(item?.celsius)).map(item =>
                    Ext.String.htmlEncode(String(item.label)) + ': ' + item.celsius.toFixed(1) + ' °C'
                ).join(' | ') || '未提供';
                const rpm = fans.filter(item => Number.isFinite(item?.rpm)).map(item =>
                    Ext.String.htmlEncode(String(item.label)) + ': ' + Math.round(item.rpm) + ' RPM'
                ).join(' | ') || '未提供';
                return '主機板: ' + board + ' | 風扇: ' + rpm;
            },
        },
        {
            itemId: 'hardware-disks',
            colspan: 2,
            printBar: false,
            title: gettext('SSD／硬碟'),
            textField: 'hardware_info',
            value: {},
            renderer: function(data) {
                const disks = Array.isArray(data?.disks) ? data.disks : [];
                return disks.map(disk => {
                    if (!disk || typeof disk !== 'object') { return ''; }
                    const parts = [Ext.String.htmlEncode(String(disk.device || '磁碟')),
                        Ext.String.htmlEncode(String(disk.model || ''))];
                    if (Number.isFinite(disk.bytes)) { parts.push((disk.bytes / 1000000000).toFixed(1) + ' GB'); }
                    parts.push('溫度: ' + (Number.isFinite(disk.celsius) ? disk.celsius + ' °C' : '未提供'));
                    if (Number.isFinite(disk.hours)) { parts.push('通電: ' + disk.hours + ' 小時'); }
                    return parts.join(' | ');
                }).filter(Boolean).join('<br>') || '未提供';
            },
        },
        // END local hardware summary.
PVE_HW_ROWS_JS
    python3 - "$stage" <<'PVE_HW_PATCH_PY'
from pathlib import Path
import re
import sys

stage = Path(sys.argv[1])
base = stage / 'package'
source = (base / 'usr/share/perl5/PVE/API2/Nodes.pm').read_text()
anchor = '        $res->{pveversion} = PVE::pvecfg::package() . "/" . PVE::pvecfg::version_text();\n'
assert source.count(anchor) == 1, '找不到唯一的節點狀態插入位置'
patch = '''
        # BEGIN local hardware summary: read a bounded cache, never run hardware tools here.
        $res->{hardware_info} = {};
        eval {
            my $hardware = decode_json(file_get_contents('/run/pve-hardware-status.json', 65536));
            if (ref($hardware) eq 'HASH' && ($hardware->{updated_at} // 0) >= time() - 60) {
                $res->{hardware_info} = $hardware;
            }
        };
        # END local hardware summary.
'''
source = source.replace(anchor, anchor + patch)
schema_anchor = '            pveversion => {\n'
assert source.count(schema_anchor) == 1, '找不到唯一的節點狀態 schema'
source = source.replace(schema_anchor, '''            hardware_info => {
                type => 'object',
                optional => 1,
                additionalProperties => 1,
                description => 'Cached optional hardware readings for the local node summary.',
            },
''' + schema_anchor)
(stage / 'Nodes.pm.patched').write_text(source)

source = (base / 'usr/share/pve-manager/js/pvemanagerlib.js').read_text()
start = source.index("Ext.define('PVE.node.StatusView', {")
end = source.index("Ext.define('PVE.node.SubscriptionKeyEdit', {", start)
section = source[start:end]
height = re.search(r'(?m)^    height: (\d+),$', section)
assert height, '找不到概覽高度設定'
section = section[:height.start()] + '    height: ' + str(int(height[1]) + 160) + ',' + section[height.end():]
anchor = "            textField: 'pveversion',\n            value: '',\n        },\n"
assert section.count(anchor) == 1, '找不到唯一的概覽插入位置'
section = section.replace(anchor, anchor + (stage / 'hardware-summary-rows.js').read_text())
(stage / 'pvemanagerlib.js.patched').write_text(source[:start] + section + source[end:])
PVE_HW_PATCH_PY
    python3 -m py_compile "$stage/pve-hardware-status.py"
    perl -c "$stage/Nodes.pm.patched"
    install -d -m 700 "$backup"
    for name in Nodes.pm pvemanagerlib.js; do
        case "$name" in
            Nodes.pm) source="$stage/package/usr/share/perl5/PVE/API2/Nodes.pm" ;;
            pvemanagerlib.js) source="$stage/package/usr/share/pve-manager/js/pvemanagerlib.js" ;;
        esac
        if [ -e "$backup/$name.original" ]; then
            cmp -s "$source" "$backup/$name.original" || { echo "原始備份校驗失敗。" >&2; exit 1; }
        else
            cp -a "$source" "$backup/$name.original"
        fi
    done
    install -d -m 755 /usr/local/libexec
    pve_hw_atomic_install "$stage/pve-hardware-status.py" /usr/local/libexec/pve-hardware-status.py 755
    install -m 644 "$stage/pve-hardware-status.service" /etc/systemd/system/pve-hardware-status.service
    install -m 644 "$stage/pve-hardware-status.timer" /etc/systemd/system/pve-hardware-status.timer
    # 清理舊選項 4 增加的 setuid/setgid；採集服務本來就以 root 執行。
    for source in /usr/sbin/turbostat /usr/sbin/nvme /usr/sbin/smartctl /usr/sbin/hddtemp /usr/sbin/linux-cpupower; do
        [ ! -f "$source" ] || chmod a-s "$source"
    done
    systemctl daemon-reload
    systemd-analyze verify /etc/systemd/system/pve-hardware-status.service /etc/systemd/system/pve-hardware-status.timer
    systemctl start pve-hardware-status.service
    python3 - <<'PVE_HW_CACHE_PY'
import json, time
from pathlib import Path
data=json.loads(Path('/run/pve-hardware-status.json').read_text())
assert isinstance(data, dict) and data.get('updated_at', 0) >= time.time()-60
PVE_HW_CACHE_PY
    # 若使用者同步修改介面檔案，停止部署，避免覆蓋。
    cmp -s /usr/share/perl5/PVE/API2/Nodes.pm "$stage/Nodes.pm.before"
    cmp -s /usr/share/pve-manager/js/pvemanagerlib.js "$stage/pvemanagerlib.js.before"
    deployment_started=1
    pve_hw_atomic_install "$stage/Nodes.pm.patched" /usr/share/perl5/PVE/API2/Nodes.pm 644
    pve_hw_atomic_install "$stage/pvemanagerlib.js.patched" /usr/share/pve-manager/js/pvemanagerlib.js 644
    pvesh get "/nodes/$(hostname -s)/status" --output-format json > "$stage/status.json"
    python3 - "$stage/status.json" <<'PVE_HW_API_PY'
import json, sys
from pathlib import Path
data=json.loads(Path(sys.argv[1]).read_text())
assert isinstance(data.get('hardware_info'), dict), '硬體資訊 API 驗證失敗'
PVE_HW_API_PY
    systemctl enable --now pve-hardware-status.timer
    pve_hw_reload_later
    deployment_started=0
    echo "CPU 溫度、核心頻率、CPU 封裝功耗及磁碟資訊已安裝。"
    echo "缺少的主機板／風扇感測器會顯示『未提供』，不會中斷概覽。"
    echo "約 3 秒後重新載入管理服務；若命令列短暫斷線，安裝已完成。"
    echo "請用 Ctrl+Shift+R（Mac：Command+Shift+R）重新載入管理頁面。"
    echo "目前版本原始檔備份：$backup"
); }

cpu_del(){ (
    set -euo pipefail
    pve_hw_require
    local stage version deployment_started=0
    stage=$(mktemp -d /var/tmp/pve-hardware-remove.XXXXXX)
    version=$(dpkg-query -W -f='${Version}' pve-manager)
    pve_hw_del_cleanup(){
        local result=$?
        trap - EXIT HUP INT TERM
        set +e
        if [ "$result" -ne 0 ] && [ "$deployment_started" -eq 1 ]; then
            pve_hw_atomic_install "$stage/Nodes.pm.before" /usr/share/perl5/PVE/API2/Nodes.pm 644
            pve_hw_atomic_install "$stage/pvemanagerlib.js.before" /usr/share/pve-manager/js/pvemanagerlib.js 644
            pve_hw_reload_later
            echo "還原未完成，已回復本次操作前的介面檔案。" >&2
        fi
        rm -rf -- "$stage"
        exit "$result"
    }
    trap pve_hw_del_cleanup EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM
    # 即使升級後舊備份不相容，也只還原目前已安裝版本的官方檔案。
    pve_hw_pristine "$stage" "$version"
    pve_hw_check_existing "$stage"
    cp -a /usr/share/perl5/PVE/API2/Nodes.pm "$stage/Nodes.pm.before"
    cp -a /usr/share/pve-manager/js/pvemanagerlib.js "$stage/pvemanagerlib.js.before"
    perl -c "$stage/package/usr/share/perl5/PVE/API2/Nodes.pm"
    deployment_started=1
    pve_hw_atomic_install "$stage/package/usr/share/perl5/PVE/API2/Nodes.pm" /usr/share/perl5/PVE/API2/Nodes.pm 644
    pve_hw_atomic_install "$stage/package/usr/share/pve-manager/js/pvemanagerlib.js" /usr/share/pve-manager/js/pvemanagerlib.js 644
    if [ -f /etc/systemd/system/pve-hardware-status.timer ]; then
        systemctl disable --now pve-hardware-status.timer
    fi
    if [ -f /etc/systemd/system/pve-hardware-status.service ]; then
        systemctl stop pve-hardware-status.service
    fi
    rm -f /etc/systemd/system/pve-hardware-status.timer /etc/systemd/system/pve-hardware-status.service \
        /usr/local/libexec/pve-hardware-status.py /run/pve-hardware-status.json
    systemctl daemon-reload
    pve_hw_reload_later
    deployment_started=0
    echo "已還原目前 PVE 版本的原始介面，並停用、移除硬體採集服務。"
    echo "請用 Ctrl+Shift+R（Mac：Command+Shift+R）重新載入管理頁面。"
); }

#--------------CPU、主機板、硬碟溫度顯示----------------


# 主菜單
menu(){
	cat <<-EOF

`TIME y "	      PVE最佳化指令碼     "`
┌──────────────────────────────────────────┐
    1. 一鍵最佳化PVE(換台灣源、去訂閱等)
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
