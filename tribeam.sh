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

cleanup(){
  rm -rf *.hfs
  rm -rf tools/FetchMacOS/BaseSystem/
}

banner() {
  msg="# $* #"
  edge=$(echo "$msg" | sed 's/./#/g')
  echo "$edge"
  echo "$msg"
  echo "$edge"
}
banner "WELCOME TO TRIBEAM!!"

dependency(){
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
  echo -e "\e[3mInstalling dependencies...\e[0m"
  package="p7zip p7zip-plugins wget curl"
  package1="p7zip wget curl python-pip"
  package2="p7zip-full wget curl python3-pip"

  if [ "${package_manager}" = "pacman -S --noconfirm" ]; then
    ${package_manager} ${package1}

  elif [ "${package_manager}" = "apt install -y" ]; then
    ${package_manager} ${package2}

  elif [ "${package_manager}" = "yum install -y" ]; then
    ${package_manager} ${package1}

  elif [ "${package_manager}" = "dnf install -y" ]; then
    ${package_manager} ${package}

  else
    echo -e "${RED}YOUR DISTRO IS NOT SUPPORTED!!${NOCOLOR}"
    exit 1
  fi

  chmod 755 -R tools

  echo -e "${YELLOW}Please select product!!${NOCOLOR}"
  options+=("macOS_Catalina" "macOS_Mojave" "macOS_High_Sierra")
  options+=("Quit")


  select name in "${options[@]}"
  do
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
  7z e -tdmg $TOOLS/FetchMacOS/BaseSystem/BaseSystem.dmg *.hfs
  mv *.hfs base.hfs
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

partformat(){
  if
  umount $(echo /dev/$id?*) || :
  sleep 3s
  sgdisk --zap-all /dev/$id
  sgdisk /dev/$id --new=0:0:+300MiB -t 0:ef00
  partprobe $(echo /dev/$id?*)
  then
    sgdisk -e /dev/$id --new=0:0: -t 0:af00
    partprobe $(echo /dev/$id?*)
    sleep 3s
  else
    exit 1
  fi
}

dding(){
  echo -e "\e[3mCopying macOS img to usb-drive!\e[0m"
  if
  dd bs=8M if="$PWD/base.hfs" of=$(echo /dev/$id)2 status=progress oflag=sync
  then
    umount $(echo /dev/$id?*) || :
    sleep 3s
  else
    exit 1
  fi
}

installoc(){
  # Format the EFI partition for opencore
  # and mount it in the /mnt.
  if
  mkfs.fat -F32 -n EFI $(echo /dev/$id)1
  then
    mount -t vfat  $(echo /dev/$id)1 /mnt/ -o rw,umask=000; sleep 3s
  else
    exit 1
  fi

  # Install opencore.
  echo -e "Installing OpenCore!!"
  sleep 3s

  # OpenCore Downloader fuction.

  if
  curl "https://api.github.com/repos/acidanthera/OpenCorePkg/releases/latest" \
  | grep -i browser_download_url \
  | grep RELEASE.zip \
  | cut -d'"' -f4 \
  | wget -qi -
  then
    7z x *RELEASE.zip -o/mnt/
  else
    exit 1
  fi
  sleep 5s
  chmod +x /mnt/
  rm -rf *RELEASE.zip
  cleanup
  umount $(echo /dev/$id)1
  mount -t vfat  $(echo /dev/$id)1 /mnt/ -o rw,umask=000
  sleep 3s

  echo -e "Installation finished, open /mnt and edit oc for your machine!!"
}

while true; do
  read -p "$(echo -e "Drive ${RED}$id${NOCOLOR} will be erased, p7zip, wget, curl will be installed
do you wish to continue (y/n)? ")" yn
  case $yn in
    [Yy]* ) cleanup; dependency; partformat > /dev/null 2>&1 || :; dding; installoc; break;;
    [Nn]* ) exit;;
    * ) echo -e "${YELLOW}Please answer yes or no."${NOCOLOR};;
  esac
done
