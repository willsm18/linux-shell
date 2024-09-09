#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/fractald.sh"

# 检查 Git 是否已安装
function install_git() {
    
	if ! command -v git &> /dev/null
	then
		# 如果 Git 未安装，则进行安装
		echo "未检测到 Git，正在安装..."
		sudo apt install git -y
	else
		# 如果 Git 已安装，则不做任何操作
		echo "Git 已安装。"
	fi
}

# 检查 Docker 是否已安装
function install_docker() {
	if ! command -v docker &> /dev/null
	then
		# 如果 Docker 未安装，则进行安装
		echo "未检测到 Docker，正在安装..."
		sudo apt-get install ca-certificates curl gnupg lsb-release

		# 添加 Docker 官方 GPG 密钥
		sudo mkdir -p /etc/apt/keyrings
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

		# 设置 Docker 仓库
		echo \
		  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
		  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

		# 授权 Docker 文件
		sudo chmod a+r /etc/apt/keyrings/docker.gpg
		sudo apt-get update

		# 安装 Docker 最新版本
		sudo apt-get install docker-ce docker-ce-cli containerd.io -y 
		DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
		mkdir -p $DOCKER_CONFIG/cli-plugins
		curl -SL https://github.com/docker/compose/releases/download/v2.25.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
		sudo chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
		docker compose version
		
	else
		echo "Docker 已安装。"
	fi
}

# 安装基本组件
function install_basic_soft() {
	
	# 更新系统包列表
	sudo apt update && sudo apt upgrade -y
	# 安装基本组件
	# sudo apt install pkg-config curl build-essential libssl-dev libclang-dev -y
    sudo apt install curl build-essential pkg-config libssl-dev wget jq make gcc chrony -y
	install_git
	# install_docker
echo "=========================fractald所需软件安装完成======================================"

}

function view_fractald_log() {
	sudo journalctl -u fractald -fo cat
}

function create_wallet() {
	cd /root/fractald-0.1.7-x86_64-linux-gnu/bin
	sudo ./bitcoin-wallet -wallet=wallet -legacy create
}

function view_wallet_pk() {
	cd /root/fractald-0.1.7-x86_64-linux-gnu/bin
	sudo ./bitcoin-wallet -wallet=/root/.bitcoin/wallets/wallet/wallet.dat -dumpfile=/root/.bitcoin/wallets/wallet/MyPK.dat dump
	sudo cd && awk -F 'checksum,' '/checksum/ {print "Your Wallet Private Key:" $2}' .bitcoin/wallets/wallet/MyPK.dat
}

# fractald节点安装功能
function install_fractald_node() {
	
	# 更新系统包列表
	wget https://github.com/fractal-bitcoin/fractald-release/releases/download/v0.2.1/fractald-0.2.1-x86_64-linux-gnu.tar.gz
	
	sudo tar -zxvf fractald-0.2.1-x86_64-linux-gnu.tar.gz
	
	cd fractald-0.2.1-x86_64-linux-gnu
	
	sudo mkdir data
	
	cp ./bitcoin.conf ./data
	
	sudo tee /etc/systemd/system/fractald.service > /dev/null <<EOF
	[Unit]
	Description=Fractal Node
	After=network.target

	[Service]
	User=root
	WorkingDirectory=/root/fractald-0.2.1-x86_64-linux-gnu
	ExecStart=/root/fractald-0.2.1-x86_64-linux-gnu/bin/bitcoind -datadir=/root/fractald-0.2.1-x86_64-linux-gnu/data/ -maxtipage=504576000
	Restart=always
	RestartSec=3
	LimitNOFILE=infinity

	[Install]
	WantedBy=multi-user.target
EOF
	
	sudo systemctl daemon-reload && \
	sudo systemctl enable fractald && \
	sudo systemctl start fractald

    echo "=========================fractald节点安装完成======================================"

}

# 主菜单
function main_menu() {
    while true; do
	    clear
	    echo "安装基础组件，免费开源，请勿相信收费"
	    echo "================================================================"
	    echo "请选择要执行的操作:"
	    echo "1. 安装基础软件"
		echo "2. 安装fractald节点"
		echo "3. 查看fractald日志"
		echo "4. 创建钱包"
		echo "5. 创建钱包私钥"
	    read -p "请输入选项: " OPTION
	
	    case $OPTION in
	    1) install_basic_soft ;;
		2) install_fractald_node ;;
		3) view_fractald_log ;;
		4) create_wallet ;;
		5) view_wallet_pk ;;
	    *) echo "无效选项。" ;;
	    esac
	        echo "按任意键返回主菜单..."
	        read -n 1
	 done
}

# 显示主菜单
main_menu
