#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/willsm.sh"

# 检查并安装 Node.js 和 npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js 已安装"
    else
        echo "Node.js 未安装，正在安装..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "npm 已安装"
    else
        echo "npm 未安装，正在安装..."
        sudo apt-get install -y npm
    fi
}

# 检查并安装 PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 已安装"
    else
        echo "PM2 未安装，正在安装..."
        npm install pm2@latest -g
    fi
}

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

# 节点安装功能
function install_node() {
	
	# 更新系统包列表
	sudo apt update
	# 安装基本组件
	sudo apt install pkg-config curl build-essential libssl-dev libclang-dev -y
	install_nodejs_and_npm
    install_pm2
	install_git
	install_docker
echo "=========================安装完成======================================"

}

# 主菜单
function main_menu() {
    clear
    echo "安装基础组件，免费开源，请勿相信收费"
    echo "================================================================"
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    read -p "请输入选项（1）: " OPTION

    case $OPTION in
    1) install_node ;;
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
