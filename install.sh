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

# Path to the password file on GitHub (replace with your actual GitHub raw file URL)

curl -H "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" \
     -H "Accept: application/vnd.github.v3.raw" \
     -o password.txt \

password_file_url="https://api.github.com/wahyu22010/Debian1/main/password.txt" 
#https://raw.githubusercontent.com/wahyu22010/Debian1/main/password.txt?token=GHSAT0AAAAAACUHII5MSTBBLYGWD7TG4ZVGZUSC32A

# Function to read password from file
get_password() {
    curl -sSf "$password_file_url"
}

# Main script
echo "Masukin Nama Anda"

# Infinite loop until correct password is entered
while :
do
    read -s user_password  # Read user input silently (-s)
    stored_password=$(get_password)  # Get password from file

    if [[ "$user_password" == "$stored_password" ]]; then
        echo -e "\nNama Diterima!"
        break  # Exit loop if password is correct
    else
        echo -e "\nNama Salah, Silahkan Masukan Kembali."
    fi
done

clear

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
echo "Pastikan Internet Berjalan Dengan Baik "
echo "Downloading Termux-X11" 
# Wait for a single character input 
echo ""
read -n 1 -s -r -p "Silahkan Tekan Enter Untuk Melanjutkan Proses BerikutNya..."
wget https://github.com/termux/termux-x11/releases/download/nightly/app-arm64-v8a-debug.apk
mv app-arm64-v8a-debug.apk $HOME/storage/downloads/
#termux-open $HOME/storage/downloads/app-arm64-v8a-debug.apk

source $PREFIX/etc/bash.bashrc
termux-reload-settings

#Downloads File wpsoffice
wget https://wpsoffice.wahyupratama-purba2004.workers.dev/0:/wpsoffice.deb
mv wpsoffice.deb $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/$username/

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
