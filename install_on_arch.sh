#!/bin/bash

# prevent execution as root
if [ $(/usr/bin/id -u) -eq 0 ]; then
    echo "The script should not be run as root"
    exit
fi

comment () {
   blue=$(tput setaf 4)
   normal=$(tput sgr0)
   text="$1"
   printf "${blue}${text}${normal}\n"
}

comment "# Install packages"
sudo pacman -Syu --noconfirm podman nginx brotli nginx-mod-brotli 

#### optional tools & aliases ####
if [ "$1" == "--additional-tools"]; then
    comment "# Install additional tools"
    # install optional tools
    sudo pacman -Syu --noconfirm htop mc fish fastfetch inetutils
    # use fish as main shell
    chsh -s $(which fish)
    sudo chsh -s $(which fish)
    # add bash aliases
    grep -qF "alias ll=" ~/.bashrc || echo "alias ll='ls -lAh'" >> ~/.bashrc
    sudo bash -c "grep -qF \"alias ll=\" ~/.bashrc || echo \"alias ll='ls -lAh'\" >> ~/.bashrc"
    grep -qF "alias sysu=" ~/.bashrc || echo "alias sysu='systemctl --user'" >> ~/.bashrc
    grep -qF "alias sysulog=" ~/.bashrc || echo "alias sysulog='journalctl --user '" >> ~/.bashrc
    # add fish aliases
    fish -c "alias --save ll='ls -lAh'"
    sudo fish -c "alias --save ll='ls -lAh'"
    fish -c "alias --save sysu='systemctl --user'"
    fish -c "alias --save sysulog='journalctl --user'"
fi
#### optional tools & aliases ####

./install.sh