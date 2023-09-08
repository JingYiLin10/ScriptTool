#!/bin/bash

STEAMAPPS_DST="/home/steam/steamapps/DST"
SERVICE_ARCHIVES="/home/steam/.klei/DoNotStarveTogether/"
SERVICE_MODS="/home/steam/steamapps/DST/mods/dedicated_server_mods_setup.lua"
ARCHIVE_MODS="/Master/modoverrides.lua"
SERVICE_PROCESS="dontstarve_dedicated_server_nullrenderer_x64"

function build_base_install() {
    dpkg --add-architecture i386
    apt-get update
    apt-get install -y expect
    apt-get install -y lib32gcc1
    apt-get install -y lib32stdc++6
    apt-get install -y libcurl4-gnutls-dev:i386
}

function build_steam_tool() {
    local steamcmd_linux="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"

expect << EOF
	set timeout -1
	spawn su - steam
	expect -re "steam.*$" {send "mkdir ~/steamcmd\r"}
	expect -re "steam.*$" {send "cd ~/steamcmd\r"}
    expect -re "steam.*$" {send "wget ${steamcmd_linux}\r"}
    expect -re "steam.*$" {send "tar -xvzf steamcmd_linux.tar.gz\r"}

    expect -re "steam.*$" {send "./steamcmd.sh\r"}
    expect -re "Steam>" {send "force_install_dir ${STEAMAPPS_DST}\r"}
    expect -re "Steam>" {send "login anonymous\r"}
    expect -re "Steam>" {send "app_update 343050 validate\r"}
    expect -re "Steam>" {send "exit\r"}

    expect -re "steam.*$" {send "exit\r"}
	expect eof
EOF
}

function build() {
    # 构建环境基础
    build_base_install

    # steam用户
    useradd -m steam -s /bin/bash
    # chmod a+rw `tty`

    # steam组件安装
    build_steam_tool

    # 构建存档目录
    mkdir -p ${SERVICE_ARCHIVES}
    script_print "build successful"
}

# token() {
#     # Cluster_1/cluster_token.txt
#     # cluster.ini文件中的cluster_key字段需要与官网上的key相同
# }

function update() {
expect << EOF
	set timeout -1
	spawn su - steam
    expect -re "steam.*$" {send "cd ~/steamcmd\r"}
    expect -re "steam.*$" {send "./steamcmd.sh\r"}
    expect -re "Steam>" {send "force_install_dir ${STEAMAPPS_DST}\r"}
    expect -re "Steam>" {send "login anonymous\r"}
    expect -re "Steam>" {send "app_update 343050 validate\r"}
    expect -re "Steam>" {send "exit\r"}

    expect -re "steam.*$" {send "exit\r"}
	expect eof
EOF
    script_print "update successful"
}

function show() {
    cd ${SERVICE_ARCHIVES}
    local index=0
    ls -l | while read line
    do
        let index++
        local archive=${line##* }
        if [ ${index} -eq 1 -o ! -d ${archive} -o ! -f ${archive}/cluster.ini ]; then
            continue
        fi
        echo "${archive}:"
        awk '/cluster_name|cluster_password/{print}' ./${archive}/cluster.ini
        echo
    done
}

function start() {
expect << EOF
	set timeout -1
	spawn su - steam
	expect -re "steam.*$" {send "cd ~/steamapps/DST/bin64\r"}

    expect -re "steam.*$" {send "setsid ./${SERVICE_PROCESS} --cluster ${1}\r"}
    expect -re "Sim paused" {send "setsid ./${SERVICE_PROCESS} --cluster ${1} --shard Caves\r"}
    expect -re "Sim paused" {send "exit\r"}
	expect eof
EOF
    script_print "start successful"
}

function stop() {
    pidof ${SERVICE_PROCESS}
    if [ $? -eq 0 ]; then
        kill -9 `pidof ${SERVICE_PROCESS}`
    fi
    script_print "stop successful"
}

function restart() {
    stop
    start
    script_print "restart successful"
}

function add_archive() {
    if [ ! -d ${SERVICE_ARCHIVES} ]; then
        script_print "add ${1} failed"
        exit
    fi

    cp -rf ${1} ${SERVICE_ARCHIVES}/${2}

    # local archive="${1##*/}"
    cd ${SERVICE_ARCHIVES}
    chown -R steam:steam ${2}
}

function remove_archive() {
    if [ ! -d ${SERVICE_ARCHIVES} ]; then
        script_print "remove ${1} failed"
        exit
    fi

    cd ${SERVICE_ARCHIVES}
    rm -rf ${1}
}

function update_game_mod() {
    cd ${SERVICE_ARCHIVES}

    awk -v smods=${SERVICE_MODS} '/\[\"workshop-[0-9]*\"\]/{gsub(/[^0-9]+/,"",$1); system("echo ServerModSetup\(\\\"" $1 "\\\"\) >> " smods)}' ${1}${ARCHIVE_MODS}
    sed -i "s/\r//g" ${SERVICE_MODS}
}

function add() {
    local archive_pre="Cluster_"
    local archive_suf=`date +%m_%d`

    # 游戏文件处理
    add_archive "${1}" "${archive_pre}${archive_suf}"

    # 更新mod
    update_game_mod "${archive_pre}${archive_suf}"
    script_print "add ${1} successful"
}

function remove() {
    # 游戏文件处理
    remove_archive ${1}
    script_print "remove ${1} successful"
}

function script_print() {
    echo "* dont_starve ${1}."
}

function main() {
    case ${1} in
    "build")
        build
        ;;
    "token")
        token
        ;;
    "update")
        update
        ;;
    "show")
        show
        ;;
    "start")
        start ${2}
        ;;
    "stop")
        stop
        ;;
    "restart")
        restart
        ;;
    "add")
        add ${2}
        ;;
    "remove")
        remove ${2}
        ;;
    esac
}

main $@