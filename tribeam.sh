#!/bin/bash

set -e
# Global Variables
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
tmpDir="$DIR"
BaseDir="$DIR/Base"
RED="\033[1;31m\e[3m"
YELLOW="\033[01;33m\e[3m"
NOCOLOR="\e[0m\033[0m"

[ "$(whoami)" != "root" ] && exec sudo -- "$0" "$@" 

clear
echo "  ############################ "
echo " #    WELCOME TO TRIBEAM    # "
echo "############################ "
echo " "
ImportantTools(){
	sleep 3s

	declare -A osInfo;
	osInfo[/etc/debian_version]="apt install -y"
	osInfo[/etc/alpine-release]="apk --update add"
	osInfo[/etc/centos-release]="yum install -y"
	osInfo[/etc/fedora-release]="dnf install -y"
	osInfo[/etc/arch-release]="pacman -Sy --noconfirm"

	for f in ${!osInfo[@]}
	do
		if [[ -f $f ]];then
			package_manager=${osInfo[$f]}
		fi
	done
	package="wget curl p7zip-plugins"
	package1="wget curl p7zip"
	package2="wget curl p7zip-full"

	if [ "${package_manager}" = "pacman -Sy --noconfirm" ]; then
		${package_manager} --needed ${package1}

	elif [ "${package_manager}" = "apt install -y" ]; then
		${package_manager} ${package2}

	elif [ "${package_manager}" = "yum install -y" ]; then
		${package_manager} ${package1}

	elif [ "${package_manager}" = "dnf install -y" ]; then
		${package_manager} ${package}

	else
		echo -e "${RED}Your distro is not supported!${NOCOLOR}"
		exit 1
	fi
}

cleanup(){
	rm -rf Base
}

# Prgram functions
downloadAndParseCatalog(){

# Download catalog file from apple server
#-------------------------------
echo -e "Downloading macOS catalog from swscan.apple.com..."
if ! curl --fail -s -f -o "$tmpDir/catalog.gz" "$1"; then error "Failed to download catalog" && exit; fi
gunzip -k "$tmpDir/catalog.gz"
rm "$tmpDir/catalog.gz"


# Parse catalog file into arrays
#-------------------------------
versionsArray=($(getListOfVersions))

appleDiagnosticsArray=($(findLinkInCatalog AppleDiagnostics.dmg "$tmpDir/catalog"))
appleDiagnosticsChunklistArray=($(findLinkInCatalog AppleDiagnostics.chunklist "$tmpDir/catalog"))
baseSystemArray=($(findLinkInCatalog BaseSystem.dmg "$tmpDir/catalog"))
baseSystemChunklistArray=($(findLinkInCatalog BaseSystem.chunklist "$tmpDir/catalog"))
installInfoArray=($(findLinkInCatalog InstallInfo.plist "$tmpDir/catalog"))
installESDArray=($(findLinkInCatalog InstallESDDmg.pkg "$tmpDir/catalog"))

rm "$tmpDir/catalog"

}

findLinkInCatalog(){
	array=($(awk '/'$1'</{print $1}' "$2"))
	let index=0
	for element in "${array[@]}"; do
		array[$index]="${element:8:${#element}-17}"
		let index=index+1
	done
	echo ${array[@]}
}

getListOfVersions(){
	versionInfoArray=($(findLinkInCatalog InstallInfo.plist "$tmpDir/catalog"))
	let index=0
	for element in "${versionInfoArray[@]}"; do
		infoline=$(curl -s -f $element | tail -5)
		versionInfo[$index]="$(echo $infoline | awk -v FS="(string>|</string)" '{print $2}')"
		let index++
	done
	echo ${versionInfo[@]}
}




checkOSAvaibility() {
	if curl --output /dev/null --silent --head --fail "https://swscan.apple.com/content/catalogs/others/index-10.16$1seed-10.16-10.15-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog.gz"; then echo "$1"; else echo "10.15"; fi
}


downloadOS(){
	# Print User Interface

	LATEST_VERSION=$(checkOSAvaibility "10.16")

	clear
	echo "  ############################ "
	echo " #   SELECT MACOS VERSION   # "
	echo "############################ "
	echo " "
	select RELEASETYPE in "Developer Release" "Beta Release" "Public Release"; do
		case $RELEASETYPE in
			Developer* ) CATALOGTYPE="-${LATEST_VERSION}seed"; break;;
			Beta* ) CATALOGTYPE="-${LATEST_VERSION}beta"; break;;
			Public* ) break;;
		esac
	done
	downloadAndParseCatalog "https://swscan.apple.com/content/catalogs/others/index${CATALOGTYPE}-10.15-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog.gz"
	clear
	echo "  ############################ "
	echo " #   SELECT MACOS VERSION   # "
	echo "############################ "
	echo " "
	select MACVERSION in "${versionsArray[@]}"; do
		if [[ $REPLY -le ${#versionsArray[@]} && $REPLY -gt 0 ]]
		then

		# Dont break sequence (It's sequenced with $fileNames[@])
		links=(${baseSystemArray[$[$REPLY - 1]]})
		fileNames=("BaseSystem.dmg")

		# Ask user to download macOS or only print links
		while true; do read -p "would you like to proceed to download [y/n] ? " yn
			echo -e ""
			if [[ $yn == y ]]; then

			# make source directory
			if [ ! -d "$BaseDir" ]; then mkdir "$BaseDir"; fi

			# Download files into $BaseDir from $links[@]
			for i in {0..0}; do
				curl -f -o "$BaseDir/${fileNames[$i]}" "${links[$i]}"
			done && break;

		elif [[ $yn == n ]]; then
			for link in "${links[@]}"; do print $link; done && break; #&& exit;
			fi
		done

		break
	else error "Invalid choice."
		fi
	done
}



extract(){

	clear
	echo "  ############################ "
	echo " #    EXTRACTING THE DMG    # "
	echo "############################ "
	7z e -tdmg $BaseDir BaseSystem.dmg -o/$BaseDir *.hfs
	mv $BaseDir/*.hfs $BaseDir/"base.hfs"
}

selectusb(){

	clear
	echo   "  ################################################ "
	echo   " #  WARNING: THE SELECTED DRIVE WILL BE ERASED! # "
	echo   "################################################ "
	echo " "
	readarray -t lines < <(lsblk -p -no name,size,MODEL,VENDOR,TRAN | grep "usb")
	echo -e "Please select the usb-drive."
	select choice in "${lines[@]}"; do
		[[ -n $choice ]] || { echo -e "${RED}>>> Invalid Selection!${NOCOLOR}" >&2; continue; }
		break 
	done
	read -r id sn unused <<<"$choice"
	if [ -z "$choice" ]; then
		echo -e "Please insert the USB drive and try again."
		exit 1
	fi
}

partformat(){

	clear
	echo "  ################################ "
	echo " #  PARTITIONING AND FORMATING  # "
	echo "################################ "
	echo " "
	while true; do read -p "Disk $id will be erased do you wish to continue [y/n] ? " yn
		echo -e ""
		if [[ $yn == y ]]; then
			umount $(echo $id?*) || :
			sleep 2s
			sgdisk --zap-all $id && partprobe
			sgdisk $id --new=0:0:+300MiB -t 0:ef00 && partprobe
			sgdisk $id --new=0:0: -t 0:af00 && partprobe
			sleep 2s
			break;
		elif [[ $yn == n ]]; then
			echo -e "Goodbye!!"; exit 1
		fi
	done
}

dding(){

	clear
	echo "  ################################"
	echo " #  COPYING MACOS IMG TO DRIVE  # "
	echo "################################"
	echo " "
	dd bs=8M if="$BaseDir/base.hfs" of=$(echo $id)2 status=progress oflag=sync
	umount $(echo $id?*) || :
	sleep 3s
}

installoc(){

	clear
	echo "  #########################"
	echo " #  INSTALLING OPENCORE  # "
	echo "#########################"
	echo " "
	mkfs.fat -F32 -n EFI $(echo $id)1
	mount -t vfat  $(echo $id)1 /mnt/ -o rw,umask=000; sleep 3s
	sleep 3s

	cd ${BaseDir}; curl "https://api.github.com/repos/acidanthera/OpenCorePkg/releases/latest" \
		| grep -i browser_download_url \
		| grep RELEASE.zip \
		| cut -d'"' -f4 \
		| wget -qi -

	sleep 3s
	7z x *RELEASE.zip -bsp0 -bso0 X64 Docs Utilities -o/mnt/ && mv /mnt/X64/EFI /mnt/EFI && rmdir /mnt/X64
	sleep 3s
	chmod +x /mnt/
	umount $(echo $id)1
	mount -t vfat  $(echo $id)1 /mnt/ -o rw,umask=000
	cd ..
	sleep 3s
	echo -e "Installation finished, open /mnt/ and edit oc for your machine!!"
}


while true; do
	read -p "$(echo -e "This script will install wget p7zip and curl do you wish to continue [y/n]? ")" yn
	case $yn in
		[Yy]* ) cleanup; ImportantTools; downloadOS; extract; selectusb; partformat; dding; installoc; cleanup; break;;
		[Nn]* ) exit;;
		* ) echo -e "Please answer yes or no.";;
	esac
done
