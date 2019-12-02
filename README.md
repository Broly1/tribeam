# Welcome  
This script will create a hackintosh USB-installer with the latest github release of OpenCore bootloader,  
it uses the Basesystem.dmg of the macOS app which is a net-installer and download the  
necessary packages during installation there for you need internet connection to use it.    
## Getting Started
You'll need Ubuntu, Arch, Fedora, LinuxMint, Debian, or Manjaro, any other distros aren't supported for now.

## Step 1
Plug in your USB-drive 4GB or more. 

## Step 2
Run `tribeam.sh` to download installation media for macOS (internet required). The default installation uses Catalina, but you can choose which version to get by adding either `--high-sierra`, `--mojave`, or `--catalina`. For example:

`./tribeam.sh --mojave`

## Step 3
Select the USB-drive whenever the script asks, it will show a menu with all drives For example:
```
1) sda 500GB
2) sdb 16GB
#)?
```

in this example 2 is the usb drive so typpe 2 and press enter.
be carefull not to select your ssd as it would wipe it clean.

## Step 4
Wait for the instalation to finish, open /mnt and edit your config.plist with ProperTree,
https://github.com/corpnewt/ProperTree
done.

Tribeam is Fork of macOS-Simple-KVM
Made by [@FoxletFox](https://twitter.com/foxletfox), and the help of many others. You can donate to him [on Coinbase](https://commerce.coinbase.com/checkout/96dc5777-0abf-437d-a9b5-a78ae2c4c227) or [Paypal!](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=QFXXKKAB2B9MA&item_name=macOS-Simple-KVM).

 Modfied by me to create OpenCore USB-installers on Linux.



