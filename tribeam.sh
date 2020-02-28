#!/bin/bash

RED="\033[1;31m\e[3m"
NOCOLOR="\e[0m\033[0m"
YELLOW="\033[01;33m\e[3m"
TOOLS=$PWD/tools
# Checking for root
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}THIS SCRIPT MUST BE EXECUTED AS ROOT${NOCOLOR}"
  exit 1
fi
set -e
declare -A osInfo;
osInfo[/etc/debian_version]="apt install -y"
osInfo[/etc/alpine-release]="apk --update add"
osInfo[/etc/centos-release]="yum install -y"
osInfo[/etc/fedora-release]="dnf install -y"
osInfo[/etc/arch-release]="pacman -S --noconfirm"

for f in ${!osInfo[@]}
do
  if [[ -f $f ]];then
    package_manager=${osInfo[$f]}
  fi
done
  echo -e "\e[3mInstalling Depencencies...\e[0m"
  package="unzip wget curl"

if [ "${package_manager}" = "pacman -S --noconfirm" ]; then
  ${package_manager} ${package}  

elif [ "${package_manager}" = "apt install -y" ]; then
  ${package_manager} ${package}  

elif [ "${package_manager}" = "yum install -y" ]; then
  ${package_manager} ${package} 

elif [ "${package_manager}" = "dnf install -y" ]; then
  ${package_manager} ${package} 
 
elif [ "${package_manager}" = "apk --update add" ]; then
  ${package_manager} ${package} 
else
  echo -e "${RED}YOUR DISTRO IS NOT SUPPORTED!!${NOCOLOR}"
  exit 1
fi

chmod 755 -R tools

banner() {
  msg="# $* #"
  edge=$(echo "$msg" | sed 's/./#/g')
  echo "$edge"
  echo "$msg"
  echo "$edge"
}
banner "WELCOME TO TRIBEAM!!"

echo -e "${YELLOW}Please select product!!${NOCOLOR}"
options+=("macOS_Catalina" "macOS_Mojave" "macOS_High_Sierra")
options+=("Quit")


select name in "${options[@]}"
do
  if [[ "$name" ]]; then
    echo -e "\e[3mYou selected $name\e[0m"
  else
    echo -e "\e[0mYou typed in: $REPLY$\e[0m"
    name=$REPLY
  fi

  case "$name" in
    macOS_Catalina) echo -e "\e[3mDownloading macOS Catalina BaseSystem.dmg ...\e[0m"
    "$TOOLS/FetchMacOS/fetch.sh" -v 10.15
    break
    ;;
    macOS_Mojave) echo -e "\e[3mDownloading macOS Mojave BaseSystem.dmg ...\e[0m"
    "$TOOLS/FetchMacOS/fetch.sh" -v 10.14
    break
    ;;
    macOS_High_Sierra) echo -e "\e[3mDownloading macOS High Sierra BaseSystem.dmg ...\e[0m"
    "$TOOLS/FetchMacOS/fetch.sh" -p 041-91758 -v 10.13
    break
    ;;
    Quit)
    exit 1
    ;;
    *)
    echo -e "${YELLOW}>>> Invalid Selection, Try again!${NOCOLOR}"

    ;;
  esac
done
"$TOOLS/dmg2img" "$TOOLS/FetchMacOS/BaseSystem/BaseSystem.dmg" "$PWD/base.iso"

func1 (){
  if
  curl "https://api.github.com/repos/acidanthera/OpenCorePkg/releases/latest" \
  | grep -i browser_download_url \
  | grep RELEASE.zip \
  | cut -d'"' -f4 \
  | wget -qi -
  then
    unzip *RELEASE.zip -d /mnt/
  else
    exit 1
  fi
  sleep 5s
  chmod +x /mnt/
  rm -rf *RELEASE.zip
  rm -rf "$PWD/base.iso"
  rm -rf tools/FetchMacOS/BaseSystem/
  umount $(echo /dev/$id)2
  mount -t vfat  $(echo /dev/$id)2 /mnt/ -o rw,umask=000
  sleep 3s
}

# Print disk devices
# Read command output line by line into array ${lines [@]}
# Bash 3.x: use the following instead:
#   IFS=$'\n' read -d '' -ra lines < <(lsblk --nodeps -no name,size | grep "sd")
readarray -t lines < <(lsblk --nodeps -no name,size | grep "sd")

# Prompt the user to select one of the lines.
echo -e "${RED}WARNING!!! SELECTING THE WRONG DISK MAY WIPE YOUR PC AND ALL DATA!!!${NOCOLOR}"
echo -e "${YELLOW}Please select the usb-drive!!${NOCOLOR}"
select choice in "${lines[@]}"; do
  [[ -n $choice ]] || { echo -e "${RED}>>> Invalid Selection !${NOCOLOR}" >&2; continue; }
  break # valid choice was made; exit prompt.
done

# Split the chosen line into ID and serial number.
read -r id sn unused <<<"$choice"

echo -e "\e[3mCopying base.iso to usb-drive!\e[0m"
if
dd bs=4M if="$PWD/base.iso" of=/dev/$id status=progress oflag=sync
then
  umount $(echo /dev/$id?*)  || :; sleep 3s
else
  exit 1
fi

#partitioning

sgdisk /dev/$id -n 2 -t 2:ef00

# Format the EFI partition for clover or opencore
# and mount it in the /mnt
if
mkfs.fat -F 32 -n EFI $(echo /dev/$id)2
then
  mount -t vfat  $(echo /dev/$id)2 /mnt/ -o rw,umask=000; sleep 3s
else
  exit 1
fi

# Install opencore
echo -e "\e[3mInstalling OpenCore!!\e[0m"
sleep 3s
func1
echo -e "\e[3mInstallation finished, open /mnt and edit oc for your machine!!\e[0m"
