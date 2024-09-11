#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/cat.sh"

sudo apt-get update
sudo apt-get install docker.io -y

VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')

DESTINATION=/usr/local/bin/docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION
sudo chmod 755 $DESTINATION

sudo apt-get install npm -y
sudo npm install n -g
sudo n stable
sudo npm i -g yarn

git clone https://github.com/CATProtocol/cat-token-box
cd cat-token-box
sudo yarn install
sudo yarn build

cd ./packages/tracker/
sudo chmod 777 docker/data
sudo chmod 777 docker/pgdata
sudo docker-compose up -d

cd ../../
sudo docker build -t tracker:latest .
sudo docker run -d \
    --name tracker \
    --add-host="host.docker.internal:host-gateway" \
    -e DATABASE_HOST="host.docker.internal" \
    -e RPC_HOST="host.docker.internal" \
    -p 3000:3000 \
    tracker:latest

echo "创建钱包"
sudo yarn cli wallet create
