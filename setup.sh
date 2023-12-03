#!/bin/bash

set -e


sudo pacman -S \
        git \
        firefox \
        rsync \
        wget \
        vim \
        vi \
        alacritty \
        rsync \
        pwgen \
        htop \
        opera \
        chromium \
        vivaldi \
        vivaldi-ffmpeg-codecs \
        discord \
        polkit-gnome \
        libreoffice-fresh \
        nm-connection-editor \
        networkmanager \
        networkmanager-openvpn \
        ntfs-3g \
        vlc \
        gnome-system-monitor \
        udisks2 \
        remmina \
        freerdp \
        zip \
        unzip \
        mariadb \
        mariadb-clients \
        postfix \
        npm \
        ruby \
        zsh \
        ttf-font-awesome \
        awesome-terminal-fonts \
        powerline \
        powerline-fonts \
        wqy-bitmapfont \
        wqy-microhei \
        wqy-microhei-lite \
        wqy-zenhei \
        ttf-font-awesome \
        ttf-roboto \
        ttf-roboto-mono \
        noto-fonts-cjk \
        adobe-source-han-serif-cn-fonts \
        picom \
        feh \
        rofi \
        lxappearance \
        thunar \
        thunar-volman \
        xfce4-settings \
        neofetch \
        polybar \
        spotify-launcher \
        bitwarden \
        virtualbox \
        virtualbox-guest-utils \
        base-devel \
        dkms \
        arc-gtk-theme \
        --needed --noconfirm

function configuration_yay() {
        if [ ! -d ./yay-bin ]; then
                if [ ! -f /usr/bin/git ]; then
                        sudo pacman -S --needed git base-devel
                fi
                rm -Rf ./yay-bin/
                git clone https://aur.archlinux.org/yay-bin.git
                cd ./yay-bin/
                makepkg -si --noconfirm
		cd ../
		rm -Rf ./yay-bin/
        fi
}

function configure_keyboard_french_canada() {
        keyboard_file=/etc/X11/xorg.conf.d/00-keyboard.conf
        if ! grep "ca(fr)" $keyboard_file &>/dev/null; then
                sudo rsync -avPh ./xorg.conf.d/00-keyboard.conf $keyboard_file
        fi
}

function enable_network_manager() {
        if [ `systemctl is-enabled NetworkManager` = "disabled" ]; then
                sudo systemctl enable --now NetworkManager
        fi
}

function configure_mariadb() {
        if [ `systemctl is-enabled mariadb` = "disabled" ]; then
                sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
                sudo systemctl enable --now mariadb
                sudo mysql -uroot -proot -e "create user root@'%' identified by 'root';"
                sudo mysql -uroot -proot -e "grant all privileges on *.* to root@'%';"
                sudo mysql -uroot -proot -e "grant all privileges on *.* to root@'%';"
        fi
}

function configure_ohMyZsh() {
        if [ ! -d ~/.oh-my-zsh ]; then
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" <<EOF
        exit
EOF
        chsh -s $(which zsh)
        sudo pacman -S --noconfirm keychain
        mkdir -p -m 700 ~/.ssh
        git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"
        sed -i "s/ZSH_THEME=\"robbyrussell\"/#ZSH_THEME=\"robbyrussell\"/" ~/.zshrc
        cat >> ~/.zshrc <<EOF
fpath+=$HOME/.zsh/pure
autoload -U promptinit; promptinit
prompt pure
zmodload zsh/nearcolor
zstyle :prompt:pure:path color '#FFFFFF'
zstyle ':prompt:pure:prompt:*' color cyan
zstyle :prompt:pure:git:stash show yes
eval \$(keychain --eval --agents ssh --quick --quiet)
export TERM=xterm-256color
EOF
        fi
}

function configure_postfix() {
        if [ `systemctl is-enabled postfix` = "disabled" ]; then
                postfix_file=/etc/postfix/main.cf
                sudo chmod o+w $postfix_file
                sudo sed -i 's/#relayhost = \[an\.ip\.add\.ress\]/relayhost = 127\.0\.0\.1:1025/' $postfix_file
                sudo chmod o-w $postfix_file
                sudo systemctl enable --now postfix
        fi
}

function maildev_docker() {
        if [ ! -f /usr/bin/docker ]; then
                sudo pacman -S docker --noconfirm
                if [ `systemctl is-enabled docker.service` = "disabled" ] ; then
                        sudo systemctl enable docker.service
                        sudo systemctl start docker.service
                fi
                if ! sudo docker ps | grep mail; then
                        sudo docker run -d --restart unless-stopped -p 1080:1080 -p 1025:1025 dominikserafin/maildev:latest
                fi
        fi
}

function configure_vmware_workstation() {
        yay -Syyu vmware-workstation --needed --noconfirm
        sudo modprobe -a vmw_vmci vmmon
}

function updateLastKernel() {
        sudo pacman -S $(pacman -Qsq "^linux" | grep "^linux[0-9]*[-rt]*$" | awk '{print $1"-headers"}' ORS=' ') --noconfirm
        sudo modprobe -a vmw_vmci vmmon
        sudo systemctl enable --now vmware-networks.service
        sudo systemctl enable --now vmware-usbarbitrator.service
}

function move_default_picture() {
	rsync -avPh ./Pictures ~/
}

function update_config() {
	rsync -avPh ./config/* ~/.config/
}

function main() {
        configuration_yay
        configure_keyboard_french_canada
        enable_network_manager
        configure_mariadb
        configure_postfix
        configure_ohMyZsh
        maildev_docker
        configure_vmware_workstation
        move_default_picture
	update_config
        #updateLastKernel
}

main

echo ""
echo ""
echo "Redémarrer l'ordinateur pour terminer la configuration !"
exit 0
