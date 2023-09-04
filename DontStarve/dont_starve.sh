#!/bin/bash


steamapps_dst="/home/steam/steamapps/DST"
service_archives="/home/steam/.klei/DoNotStarveTogether/"
service_mods="/home/steam/steamapps/DST/mods/dedicated_server_mods_setup.lua"

buildBaseInstall() {
    dpkg --add-architecture i386
    apt-get update
    apt-get install -y expect
    apt-get install -y lib32gcc1
    apt-get install -y lib32stdc++6
    apt-get install -y libcurl4-gnutls-dev:i386
}

buildSteamTool() {
    local steamcmd_linux="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
expect << EOF
	set timeout -1
	spawn su - steam
	expect -re "steam.*$" {send "mkdir ~/steamcmd\r"}
	expect -re "steam.*$" {send "cd ~/steamcmd\r"}
    expect -re "steam.*$" {send "wget ${steamcmd_linux}\r"}
    expect -re "steam.*$" {send "tar -xvzf steamcmd_linux.tar.gz\r"}

    expect -re "steam.*$" {send "./steamcmd.sh\r"}
    expect -re "Steam>" {send "force_install_dir ${steamapps_dst}\r"}
    expect -re "Steam>" {send "login anonymous\r"}
    expect -re "Steam>" {send "app_update 343050 validate\r"}
    expect -re "Steam>" {send "exit\r"}

    expect -re "steam.*$" {send "exit\r"}
	expect eof
EOF
}

buildGameFile() {
    echo "cp -rf $1 ${service_archives}"
    cp -rf $1 ${service_archives}
    archive="${1##*/}"
    cd ${service_archives}
    chown -R steam:steam ${archive}
}

buildGameMod() {
    mod="${service_mods##*/}"
    cd "${service_mods%/*}"
    echo "install mode\n"

    # 编辑文件 `/home/steam/steamapps/DST/mods/dedicated_server_mods_setup.lua`

    # -- ServerModSetup("623749604")
}

build() {
    # 构建环境基础
    buildBaseInstall

    # steam用户
    useradd -m steam -s /bin/bash
    # chmod a+rw `tty`

    # steam组件安装
    buildSteamTool

    # 游戏文件处理
    buildGameFile $1

    # mod安装
    buildGameMod
}

# stop() {

# }

# start() {
# expect << EOF
# 	set timeout -1
# 	spawn su - steam
# 	expect -re "steam.*$" {send "cd ${}\r"}
# 	expect -re "steam.*$" {send "cd ~/steamcmd\r"}
#     expect -re "steam.*$" {send "wget ${steamcmd_linux}\r"}
#     expect -re "steam.*$" {send "tar -xvzf steamcmd_linux.tar.gz\r"}

#     expect -re "steam.*$" {send "./steamcmd.sh\r"}
#     expect -re "Steam>" {send "force_install_dir ${steamapps_dst}\r"}
#     expect -re "Steam>" {send "login anonymous\r"}
#     expect -re "Steam>" {send "app_update 343050 validate\r"}
#     expect -re "Steam>" {send "exit\r"}

#     expect -re "steam.*$" {send "exit\r"}
# 	expect eof
# EOF
# }

# restart() {
#     stop
#     start
# }

# update() {
#     sudo su - steam

#     cd /home/steam/steamapps/DST/bin64
    
#     setsid ./dontstarve_dedicated_server_nullrenderer_x64 --cluster Cluster_1
    
#     # 显示如下日志则成功
#     # [00:00:23]: Server registered via geo DNS in Sing
#     # [00:00:23]: Sim paused
    
#     setsid ./dontstarve_dedicated_server_nullrenderer_x64 --cluster Cluster_1 --shard Caves
# }

# replace() {

# }

# show() {
#     # "Archive: Word: Pswd:"
#     # ""
# }

# token() {
#     # Cluster_1/cluster_token.txt
#     # cluster.ini文件中的cluster_key字段需要与官网上的key相同
# }

main() {
    if [ ${1} == "build" ]; then
        build $2
    fi
}

main $@