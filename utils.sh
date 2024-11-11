#!/bin/bash

cat <<'EOF' > $PREFIX/bin/prun
#!/bin/bash
varname=$(basename $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/*)
pd login debian --user $varname --shared-tmp -- env DISPLAY=:1.0 $@

EOF
chmod +x $PREFIX/bin/prun

cat <<'EOF' > $PREFIX/bin/zrun
#!/bin/bash
varname=$(basename $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/*)
pd login debian --user $varname --shared-tmp -- env DISPLAY=:1.0 MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform $@

EOF
chmod +x $PREFIX/bin/zrun

cat <<'EOF' > $PREFIX/bin/zrunhud
#!/bin/bash
varname=$(basename $PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/*)
pd login debian --user $varname --shared-tmp -- env DISPLAY=:1.0 MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform GALLIUM_HUD=fps $@

EOF
chmod +x $PREFIX/bin/zrunhud

#cp2menu utility ... Allows copying of Debian proot desktop menu items into Termux xfce menu to allow for launching programs from Debian proot from within the xfce menu rather than launching from terminal. 

cat <<'EOF' > $PREFIX/bin/cp2menu
#!/bin/bash

# Fungsi untuk mengecek dan menginstal dependencies
check_dependencies() {
    local packages=("rofi")
    local missing_packages=()

    for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            missing_packages+=("$pkg")
        fi
    done

    if [ ${#missing_packages[@]} -ne 0 ]; then
        echo "Installing required packages: ${missing_packages[*]}"
        apt update && apt install -y "${missing_packages[@]}"
    fi
}

# Fungsi untuk menampilkan pesan
show_message() {
    local title="$1"
    local message="$2"
    local type="${3:-normal}" # normal atau error
    
    if command -v notify-send >/dev/null 2>&1; then
        if [ "$type" = "error" ]; then
            notify-send -u critical "$title" "$message"
        else
            notify-send "$title" "$message"
        fi
    else
        # Fallback ke rofi jika notify-send tidak tersedia
        echo "$message" | rofi -e "$title"
    fi
}

# Konfigurasi rofi
configure_rofi() {
    mkdir -p ~/.config/rofi
    cat > ~/.config/rofi/config.rasi << 'EOF'
configuration {
    modi: "drun,window,run";
    width: 50;
    lines: 15;
    font: "Sans 12";
    terminal: "termux-x11";
    location: 0;
    disable-history: false;
    hide-scrollbar: true;
}

* {
    background-color: #282c34;
    border-color: #2e343f;
    text-color: #8ca0aa;
    spacing: 0;
    width: 512px;
}

inputbar {
    border: 0 0 1px 0;
    children: [prompt,entry];
}

prompt {
    padding: 16px;
    border: 0 1px 0 0;
}

entry {
    padding: 16px;
}

listview {
    cycle: false;
    margin: 0 0 -1px 0;
    scrollbar: false;
}

element {
    border: 0 0 1px 0;
    padding: 16px;
}

element selected {
    background-color: #2e343f;
}
EOF
}

# Pastikan dependencies terinstal
check_dependencies

# Konfigurasi rofi jika belum ada
[ ! -f ~/.config/rofi/config.rasi ] && configure_rofi

cd

user_dir="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/home/"

# Get the username from the user directory
username=$(basename "$user_dir"/*)

# Show action selection menu using rofi
action=$(echo -e "📥 Copy .desktop file\n🗑 Remove .desktop file\n❌ Exit" | \
    rofi -dmenu -p "💼 Desktop File Manager" \
    -theme-str 'window {width: 400px;}' \
    -theme-str 'listview {lines: 3;}')

case "$action" in
    "📥 Copy .desktop file")
        # Get list of .desktop files with app names
        desktop_files=$(find "$PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/applications" -name "*.desktop")
        
        if [ -z "$desktop_files" ]; then
            show_message "Error" "No .desktop files found in source directory!" "error"
            exit 1
        fi

        # Create menu items with app names
        menu_items=""
        while IFS= read -r file; do
            filename=$(basename "$file")
            app_name=$(grep "^Name=" "$file" | head -1 | cut -d= -f2-)
            icon=$(grep "^Icon=" "$file" | head -1 | cut -d= -f2-)
            [ -z "$app_name" ] && app_name=$filename
            menu_items+="$app_name ($filename)\n"
        done <<< "$desktop_files"

        # Show selection menu
        selected=$(echo -e "$menu_items" | rofi -dmenu -p "📋 Select Application" \
            -theme-str 'window {width: 600px;}' \
            -theme-str 'listview {lines: 10;}')

        if [ -z "$selected" ]; then
            show_message "Cancelled" "No file selected"
            exit 0
        fi

        # Extract filename from selection
        filename=$(echo "$selected" | grep -o '([^)]*)')
        filename=${filename:1:-1}

        source_path="$PREFIX/var/lib/proot-distro/installed-rootfs/debian/usr/share/applications/$filename"
        target_path="$PREFIX/share/applications/$filename"

        # Copy and modify the .desktop file
        if cp "$source_path" "$target_path"; then
            sed -i "s|^Exec=|Exec=pd login debian --user $username --shared-tmp -- env DISPLAY=:1.0 |" "$target_path"
            show_message "✅ Success" "Application shortcut has been added successfully!"
        else
            show_message "❌ Error" "Failed to copy .desktop file!" "error"
        fi
        ;;

    "🗑 Remove .desktop file")
        # Get list of installed .desktop files
        desktop_files=$(find "$PREFIX/share/applications" -name "*.desktop")
        
        if [ -z "$desktop_files" ]; then
            show_message "Error" "No .desktop files found in target directory!" "error"
            exit 1
        fi

        # Create menu items with app names
        menu_items=""
        while IFS= read -r file; do
            filename=$(basename "$file")
            app_name=$(grep "^Name=" "$file" | head -1 | cut -d= -f2-)
            [ -z "$app_name" ] && app_name=$filename
            menu_items+="$app_name ($filename)\n"
        done <<< "$desktop_files"

        # Show selection menu
        selected=$(echo -e "$menu_items" | rofi -dmenu -p "🗑 Select Application to Remove" \
            -theme-str 'window {width: 600px;}' \
            -theme-str 'listview {lines: 10;}')

        if [ -z "$selected" ]; then
            show_message "Cancelled" "No file selected for removal"
            exit 0
        fi

        # Extract filename from selection
        filename=$(echo "$selected" | grep -o '([^)]*)')
        filename=${filename:1:-1}
        target_path="$PREFIX/share/applications/$filename"

        # Confirm deletion
        confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "🤔 Are you sure you want to remove '$filename'?" \
            -theme-str 'window {width: 400px;}' \
            -theme-str 'listview {lines: 2;}')

        if [ "$confirm" = "Yes" ]; then
            if rm "$target_path"; then
                show_message "✅ Success" "Application shortcut has been removed successfully!"
            else
                show_message "❌ Error" "Failed to remove .desktop file!" "error"
            fi
        else
            show_message "Cancelled" "Operation cancelled"
        fi
        ;;

    "❌ Exit"|"")
        show_message "👋 Goodbye" "Thank you for using Desktop File Manager"
        exit 0
        ;;
esac

EOF
chmod +x $PREFIX/bin/cp2menu

echo "[Desktop Entry]
Version=1.0
Type=Application
Name=cp2menu
Comment=
Exec=cp2menu
Icon=edit-move
Categories=System;
Path=
Terminal=false
StartupNotify=false
" > $PREFIX/share/applications/cp2menu.desktop 
chmod +x $PREFIX/share/applications/cp2menu.desktop 

#App Installer Utility .. For installing additional applications not available in Termux or Debian proot repositories. 
cat <<'EOF' > "$PREFIX/bin/app-installer"
#!/bin/bash

# Define the directory paths
INSTALLER_DIR="$HOME/.App-Installer"
REPO_URL="https://github.com/wahyu22010/App-Installer.git"
DESKTOP_DIR="$HOME/Desktop"
APP_DESKTOP_FILE="$DESKTOP_DIR/app-installer.desktop"

# Check if the directory already exists
if [ ! -d "$INSTALLER_DIR" ]; then
    # Directory doesn't exist, clone the repository
    git clone "$REPO_URL" "$INSTALLER_DIR"
    if [ $? -eq 0 ]; then
        echo "Repository cloned successfully."
    else
        echo "Failed to clone repository. Exiting."
        exit 1
    fi
else
    echo "Directory already exists. Skipping clone."
    "$INSTALLER_DIR/app-installer"
fi

# Check if the .desktop file exists
if [ ! -f "$APP_DESKTOP_FILE" ]; then
    # .desktop file doesn't exist, create it
    echo "[Desktop Entry]
    Version=1.0
    Type=Application
    Name=App Installer
    Comment=
    Exec=$PREFIX/bin/app-installer
    Icon=package-install
    Categories=System;
    Path=
    Terminal=false
    StartupNotify=false
" > "$APP_DESKTOP_FILE"
    chmod +x "$APP_DESKTOP_FILE"
fi

# Ensure the app-installer script is executable
chmod +x "$INSTALLER_DIR/app-installer"

EOF
chmod +x "$PREFIX/bin/app-installer"
bash $PREFIX/bin/app-installer

# Check if the .desktop file exists
if [ ! -f "$HOME/Desktop/app-installer.desktop" ]; then
# .desktop file doesn't exist, create it
echo "[Desktop Entry]
Version=1.0
Type=Application
Name=App Installer
Comment=
Exec=$PREFIX/bin/app-installer
Icon=package-install
Categories=System;
Path=
Terminal=false
StartupNotify=false
" > "$HOME/Desktop/app-installer.desktop"
chmod +x "$HOME/Desktop/app-installer.desktop"
fi

#Start script
cat <<'EOF' > start
#!/bin/bash

# Enable PulseAudio over Network
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 > /dev/null 2>&1

XDG_RUNTIME_DIR=${TMPDIR} termux-x11 :1.0 & > /dev/null 2>&1
sleep 1

am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=4.3COMPAT MESA_GLES_VERSION_OVERRIDE=3.2 virgl_test_server_android --angle-gl & > /dev/null 2>&1

#GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.0 program

#MESA_LOADER_DRIVER_OVERRIDE=zink TU_DEBUG=noconform program

env DISPLAY=:1.0 GALLIUM_DRIVER=virpipe dbus-launch --exit-with-session xfce4-session & > /dev/null 2>&1
# Set audio server
export PULSE_SERVER=127.0.0.1 > /dev/null 2>&1

sleep 5
process_id=$(ps -aux | grep '[x]fce4-screensaver' | awk '{print $2}')
kill "$process_id" > /dev/null 2>&1


EOF

chmod +x start
mv start $PREFIX/bin

#Shutdown Utility
cat <<'EOF' > $PREFIX/bin/kill_termux_x11
#!/bin/bash

# Check if Apt, dpkg, or Nala is running in Termux or Proot
if pgrep -f 'apt|apt-get|dpkg|nala'; then
  zenity --info --text="Software is currently installing in Termux or Proot. Please wait for these processes to finish before continuing."
  exit 1
fi

# Get the process IDs of Termux-X11 and XFCE sessions
termux_x11_pid=$(pgrep -f /system/bin/app_process.*com.termux.x11.Loader)
xfce_pid=$(pgrep -f "xfce4-session")

# Add debug output
echo "Termux-X11 PID: $termux_x11_pid"
echo "XFCE PID: $xfce_pid"

# Check if the process IDs exist
if [ -n "$termux_x11_pid" ] && [ -n "$xfce_pid" ]; then
  # Kill the processes
  kill -9 "$termux_x11_pid" "$xfce_pid"
  zenity --info --text="Termux-X11 and XFCE sessions closed."
else
  zenity --info --text="Termux-X11 or XFCE session not found."
fi

info_output=$(termux-info)
pid=$(echo "$info_output" | grep -o 'TERMUX_APP_PID=[0-9]\+' | awk -F= '{print $2}')
kill "$pid"

exit 0


EOF

chmod +x $PREFIX/bin/kill_termux_x11

#Create kill_termux_x11.desktop
echo "[Desktop Entry]
Version=1.0
Type=Application
Name=Kill Termux X11
Comment=
Exec=kill_termux_x11
Icon=system-shutdown
Categories=System;
Path=
StartupNotify=false
" > $HOME/Desktop/kill_termux_x11.desktop
chmod +x $HOME/Desktop/kill_termux_x11.desktop
mv $HOME/Desktop/kill_termux_x11.desktop $PREFIX/share/applications

