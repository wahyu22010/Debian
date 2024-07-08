#!/bin/bash

# Unofficial Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'

finish() {
  local ret=$?
  if [ ${ret} -ne 0 ] && [ ${ret} -ne 130 ]; then
    echo
    echo "ERROR: Failed to setup DEBIAN on Termux."
    echo "Please refer to the error message(s) above"
  fi
}

trap finish EXIT

clear

echo ""
echo "Ini Adalah Script Install Debian Di Termux"
echo "Hati-Hati Dalam Penggunaan Script Ini"
echo " Developer  : Wahyu Pratama Purba "
echo " My Number  : 082282719563 "
echo " My YouTube : Wahyu_Prb "
echo ""
read -r -p "Please enter username for debian installation: " username </dev/tty

termux-change-repo
pkg update -y -o Dpkg::Options::="--force-confold"
pkg upgrade -y -o Dpkg::Options::="--force-confold"
sed -i '12s/^#//' $HOME/.termux/termux.properties

# Display a message 
clear -x
echo ""
echo "Setting up Termux Storage Access." 
# Wait for a single character input 
echo ""
read -n 1 -s -r -p "Press any key to continue..."
termux-setup-storage

# Set the correct password here
correct_password="1111"

# Function to prompt for password
prompt_for_password() {
    echo "Enter the password:"
    read -s entered_password  # Read password input silently
}

# Main logic
while true; do
    prompt_for_password

    if [[ "$entered_password" == "$correct_password" ]]; then
        echo "Correct password entered. Access granted!"
        break  # Exit the loop if correct password is entered
    else
        echo "Incorrect password. Please try again."
    fi
done

pkgs=( 'wget' 'ncurses-utils' 'dbus' 'proot-distro' 'x11-repo' 'tur-repo' 'android-tools' 'pulseaudio')
pkg uninstall dbus -y
pkg update
pkg install "${pkgs[@]}" -y -o Dpkg::Options::="--force-confold"

#Create default directories
mkdir -p Desktop
mkdir -p Downloads

#Download required install scripts
wget https://github.com/wahyu22010/Debian/raw/main/xfce.sh
wget https://github.com/wahyu22010/Debian/raw/main/proot.sh
wget https://github.com/wahyu22010/Debian/raw/main/utils.sh
chmod +x *.sh

./xfce.sh "$username"
./proot.sh "$username"
./utils.sh



# Display a message 
clear -x
echo ""
echo "Silahkan Hubungi Saya Untuk Melanjutkan Proses BerikutNya"
echo "Installing Termux-X11 APK" 
# Wait for a single character input 
echo ""
read -n 1 -s -r -p "Press any key to continue..."
wget https://github.com/termux/termux-x11/releases/download/nightly/app-arm64-v8a-debug.apk
mv app-arm64-v8a-debug.apk $HOME/storage/downloads/
#termux-open $HOME/storage/downloads/app-arm64-v8a-debug.apk

source $PREFIX/etc/bash.bashrc
termux-reload-settings

#Downloads File wpsoffice
wget https://wpsoffice.wahyupratama-purba2004.workers.dev/0:/A.deb
mv A.deb $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/

clear -x
echo ""
echo "Instalasi Telah Selesai!"
echo "Jangan Pernah Mencoba Untuk Instalasi Mandiri Tanpa Pengawasan Saya"
echo "WAHYU PRATAMA PURBA"
echo ""

rm xfce.sh
rm proot.sh
rm utils.sh
rm install.sh
