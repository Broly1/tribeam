#!/bin/bash

RED="\033[1;31m"
NOCOLOR="\033[0m"
YELLOW="\033[01;33m"



# Checking for root
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}THIS SCRIPT MUST RUN AS ROOT${NOCOLOR}"
  exit 1
fi

# Identifying distro
source /etc/os-release

if [[ $ID = "ubuntu" ]]; then
  yes | apt install unzip;yes | apt install wget;yes | apt install python3-pip


elif [[ $ID = "linuxmint" ]]; then
  yes | apt install unzip;yes | apt install wget;yes | apt install python3-pip

elif [[ $ID = "debian" ]]; then
      yes | apt install unzip;yes | apt install wget;yes | apt install python3-pip

elif [[ $ID = "fedora" ]]; then
    yes | dnf install unzip;yes | dnf install wget;yes | dnf install python3-pip

elif [[ $ID = "arch" ]]; then
  yes | pacman -S unzip;yes | pacman -S wget;yes | pacman -S python3-pip

elif [[ $ID = "manjaro" ]]; then
  yes | pacman -S unzip;yes | pacman -S wget;yes | pacman -S python3-pip

else
  echo -e "${RED}YOUR DISTRO IS NOT SUPPORTED!!${NOCOLOR}"
  exit 1
fi

chmod 755 -R tools

# tribeam.sh fork of jumpstart.sh: Fetches BaseSystem and converts it to a viable format.
# by Foxlet <foxlet@furcode.co>

TOOLS=$PWD/tools

print_usage() {
    echo
    echo "Usage: $0"
    echo
    echo " -s, --high-sierra   Fetch High Sierra media."
    echo " -m, --mojave        Fetch Mojave media."
    echo " -c, --catalina      Fetch Catalina media."
    echo
}

error() {
    local error_message="$*"
    echo "${error_message}" 1>&2;
}

argument="$1"
case $argument in
    -h|--help)
        print_usage
        ;;
    -s|--high-sierra)
        "$TOOLS/FetchMacOS/fetch.sh" -v 10.13 || exit 1;
        ;;
    -m|--mojave)
        "$TOOLS/FetchMacOS/fetch.sh" -v 10.14 || exit 1;
        ;;
    -c|--catalina|*)
        "$TOOLS/FetchMacOS/fetch.sh" -v 10.15 || exit 1;
        ;;
esac

"$TOOLS/dmg2img" "$TOOLS/FetchMacOS/BaseSystem/BaseSystem.dmg" "$PWD/base.iso"

# Autor: Broly
# License: GNU General Public License v3.0
# https://www.gnu.org/licenses/gpl-3.0.txt
# This script is inteded to create a OpenCore usb installer on linux.


set -e
func1 (){
  if
  wget https://files.amd-osx.com/OpenCore-0.5.2-RELEASE.zip
  then
    unzip OpenCore-0.5.2-RELEASE.zip -d /mnt/
  else
    echo -e "${RED}Something went wrong!!!${NOCOLOR}"
  fi
  sleep 5s
  chmod +x /mnt/
  rm -rf OpenCore-0.5.2-RELEASE.zip
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
echo -e "${YELLOW}\e[3mPLEASE SELECT THE USB-DRIVE!\e[0m${NOCOLOR}"
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
  (
    echo "x"
    echo "e"
    echo "w"
    echo "y") | gdisk /dev/$id
  (
    echo "n"
    echo "2"
    echo ""
    echo ""
    echo "t"
    echo "2"
    echo "1"
    sleep 3s
    echo "w") | fdisk /dev/$id
    sleep 3s

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
