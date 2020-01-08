#!/bin/bash
lemp_version="2.0.4"
phpmyadmin_version="4.8.0.1"
extplorer_version="2.1.10"
low_ram='262144' # 256MB
OS_NAME=`cat /etc/*-release | grep -E -o '^NAME="(.*)"' | awk -F "\"" '{print $2}' | awk -F " " '{print $1}' | awk '{print tolower($0)}'`

#if [ "$OS_NAME" == "centos" ];
#then
#    #sudo yum -y install gawk bc wget lsof
#else
#    #sudo apt-get install -y gawk bc lsof
#fi

cpu_name=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
cpu_cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
cpu_freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
server_ram_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
server_ram_mb=`echo "scale=0;$server_ram_total/1024" | bc`
server_hdd=$( df -h | awk 'NR==2 {print $2}' )
server_swap_total=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
server_swap_mb=`echo "scale=0;$server_swap_total/1024" | bc`
server_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')

echo "VPS Infomation"
echo -e "CPU\t\t: `echo $cpu_name | sed 's/ *$//g'` (x$cpu_cores) Freq $cpu_freq MHz"
if [ $server_ram_mb -gt 1024 ];
then
    server_ram_gb=`echo "scale=0;$server_ram_mb/1024" | bc`
    echo -e "RAM Total\t: \033[0;32m${server_ram_gb}GB\033[0m"
else
    if [ $server_ram_total -lt $low_ram ];
    then
        echo -e "RAM Total\t: \033[0;31m${server_ram_mb}MB (x)\033[0m"
    else
        echo -e "RAM Total\t: \033[0;32m${server_ram_mb}MB\033[0m"
    fi
fi
if [ $server_swap_mb -gt 1024 ];
then
    server_swap_gb=`echo "scale=0;$server_swap_mb/1024" | bc`
    echo -e "Swap Total\t: ${server_swap_gb}GB"
else
    echo -e "Swap Total\t: ${server_swap_mb}MB"
fi
echo -e "Storage Total\t: ${server_hdd}B"
echo -e "IP Address\t: $server_ip"

if [ $server_ram_total -lt $low_ram ];
then
    echo -q "\033[0;31mRAM ${server_ram_mb}MB is low minimum required `echo "scale=0;$low_ram/1024" | bc`MB - Exit install\033[0m"
    exit
fi
php_version=""
php_versions=("5.6" "7.0" "7.1" "7.2" "7.3" "7.4")
all_versions=$(printf ", \033[1;32m%s\033[0m" "${php_versions[@]}")
prompt=""
while [[ ! $prompt =~ ^[0-9].[0-9]$ ]]; do
    echo -e "PHP Versions: [ ${all_versions:2} ]"
    read -p "Select PHP Version: " prompt
    for v in "${php_versions[@]}"
    do
        if [ "$v" == "$prompt" ];
        then
            php_version="$v"
        fi
    done
    if [[ "$php_version" == "" ]]; then
        prompt=""
    fi
done

echo -e "\033[0;32mPHP Version:\033[0m \033[1;32m$php_version\033[0m"

server_name=""
prompt=""
while [[ ! $prompt =~ ^([a-zA-Z0-9](([a-zA-Z0-9-]){0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; do
    read -p "Type an valid domain: " prompt
    prompt="${prompt#http://}"
    prompt="${prompt#https://}"
    prompt="${prompt#ftp://}"
    prompt="${prompt#scp://}"
    prompt="${prompt#sftp://}"
    prompt="${prompt/www./''}"
    prompt="${prompt%%/*}"
    if [ "${#prompt}" -lt 4 ] || [ "${#prompt}" -gt 253 ]; then
        prompt=""
    fi
    prompt=$(echo $prompt | grep -P "^([a-zA-Z0-9](([a-zA-Z0-9-]){0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$")
    if [[ $prompt != "" ]];
    then
        server_name="$prompt"
    fi
done

echo -e "\033[0;32mDomain:\033[0m \033[1;32m$server_name\033[0m"

admin_port=""
while [[ ! $admin_port =~ ^[0-9]+$ ]]; do
    read -p "Admin port [2000 - 9999]: " admin_port
    if [ $admin_port == "2222" ] || [ $admin_port -lt 2000 ] || [ $admin_port -gt 9999 ] || [ $(lsof -i -P | grep ":$admin_port " | wc -l) != "0" ]; then
        admin_port=""
    fi
done

echo -e "\033[0;32mAdministrator port:\033[0m \033[1;32m$admin_port\033[0m"
