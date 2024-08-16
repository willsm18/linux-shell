#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

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

# 检查Go环境
function check_go_installation() {
    if command -v go > /dev/null 2>&1; then
        echo "Go 环境已安装"
        return 0
    else
        echo "Go 环境未安装，正在安装..."
        return 1
    fi
}

# 查看 PM2 服务状态
function check_service_status() {
    pm2 list
}

# 卸载节点功能
function uninstall_node() {
    echo "你确定要卸载0gchain 节点程序吗？这将会删除所有相关的数据。[Y/N]"
    read -r -p "请确认: " response

    case "$response" in
        [yY][eE][sS]|[yY])
            echo "开始卸载节点程序..."
            pm2 stop 0gchaind && pm2 delete 0gchaind
            rm -rf $HOME/.0gchain $HOME/0gchain $(which 0gchaind) && rm -rf 0g-chain
            echo "节点程序卸载完成。"
            ;;
        *)
            echo "取消卸载操作。"
            ;;
    esac
}

function install_storage_node_env() {

    sudo apt-get update
    sudo apt-get install clang cmake build-essential git screen cargo -y


    # 安装 Go
    sudo rm -rf /usr/local/go
    curl -L https://go.dev/dl/go1.22.0.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    source $HOME/.bash_profile


    # 克隆仓库
    git clone -b v0.4.2 https://github.com/0glabs/0g-storage-node.git

    # 进入对应目录构建
    cd 0g-storage-node
    git submodule update --init

    # 构建代码
    echo "准备构建，该步骤消耗一段时间。请保持 SSH 不要断开。看到 Finish 字样为构建完成。"
    cargo build --release

}


function install_storage_node() {

    # 编辑配置

    read -p "请输入你想导入的EVM钱包私钥，不要有0x: " miner_key
    # read -p "请输入设备 IP 地址（本地机器请输入127.0.0.1）: " public_address
    read -p "请输入使用的 JSON-RPC : " json_rpc
	
    sed -i '
    s|blockchain_rpc_endpoint = ".*"|blockchain_rpc_endpoint = "'$json_rpc'"|
    s|miner_key = ""|miner_key = "'$miner_key'"|
    ' $HOME/0g-storage-node/run/config-testnet-turbo.toml

    # 启动
    cd ~/0g-storage-node/run
    screen -dmS zgs_node_session $HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config-testnet-turbo.toml


    echo '====================== 安装完成，使用 screen -ls 命令查询即可 ==========================='

}

function install_storage_kv() {

    # 克隆仓库
    git clone https://github.com/0glabs/0g-storage-kv.git


    #进入对应目录构建
    cd 0g-storage-kv
    git submodule update --init

    # 构建代码
    cargo build --release

    #后台运行
    cd run

    echo "请输入RPC节点信息: "
    read blockchain_rpc_endpoint


cat > config.toml <<EOF
stream_ids = ["000000000000000000000000000000000000000000000000000000000000f2bd", "000000000000000000000000000000000000000000000000000000000000f009", "00000000000000000000000000"]

db_dir = "db"
kv_db_dir = "kv.DB"

rpc_enabled = true
rpc_listen_address = "127.0.0.1:6789"
zgs_node_urls = "http://127.0.0.1:5678"

log_config_file = "log_config"

blockchain_rpc_endpoint = "$blockchain_rpc_endpoint"
log_contract_address = "0x22C1CaF8cbb671F220789184fda68BfD7eaA2eE1"
log_sync_start_block_number = 670000

EOF

    echo "配置已成功写入 config.toml 文件"
    screen -dmS storage_kv ../target/release/zgs_kv --config config.toml

}

# 查看存储节点日志
function check_storage_logs() {
    tail -f "$(find ~/0g-storage-node/run/log/ -type f -printf '%T+ %p\n' | sort -r | head -n 1 | cut -d' ' -f2-)"
}

# 过滤错误日志
function check_storage_error() {
    tail -f -n50 ~/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d) | grep ERROR
}

# 重启存储节点
function restart_storage() {
    # 退出现有进程
    screen -S zgs_node_session -X quit
    # 启动
    cd ~/0g-storage-node/run
    screen -dmS zgs_node_session $HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config-testnet-turbo.toml
    echo '====================== 启动成功，请通过screen -r zgs_node_session 查询 ==========================='

}

# 修改日志等级
function change_storage_log_level() {
    echo "DEBUG(1) > INFO(2) > WARN(3) > ERROR(4)"
    echo "DEBUG 等级日志文件最大，ERROR 等级日志文件最小"
    read -p "请选择日志等级(1-4): " level
    case "$level" in
        1)
            echo "debug,hyper=info,h2=info" > $HOME/0g-storage-node/run/log_config ;;
        2)
            echo "info,hyper=info,h2=info" > $HOME/0g-storage-node/run/log_config ;;
        3)
            echo "warn,hyper=info,h2=info" > $HOME/0g-storage-node/run/log_config ;;
        4)
            echo "error,hyper=info,h2=info" > $HOME/0g-storage-node/run/log_config ;;
    esac
    echo "修改完成，请重新启动存储节点"
}


# 统计日志文件大小
function storage_logs_disk_usage(){
    du -sh ~/0g-storage-node/run/log/
    du -sh ~/0g-storage-node/run/log/*
}


# 删除存储节点日志
function delete_storage_logs(){
    echo "确定删除存储节点日志？[Y/N]"
    read -r -p "请确认: " response
        case "$response" in
        [yY][eE][sS]|[yY])
            rm -r ~/0g-storage-node/run/log/*
            echo "删除完成，请重启存储节点"
            ;;
        *)
            echo "取消操作"
            ;;
    esac

}


# 转换 ETH 地址
function transfer_EIP() {
    read -p "请输入你的钱包名称: " wallet_name
    echo "0x$(0gchaind debug addr $(0gchaind keys show $wallet_name -a) | grep hex | awk '{print $3}')"

}

function uninstall_storage_node() {
    echo "你确定要卸载0g ai 存储节点程序吗？这将会删除所有相关的数据。[Y/N]"
    read -r -p "请确认: " response

    case "$response" in
        [yY][eE][sS]|[yY])
            echo "开始卸载节点程序..."
            rm -rf $HOME/0g-storage-node
            echo "节点程序卸载完成。"
            ;;
        *)
            echo "取消卸载操作。"
            ;;
    esac
}

function update_script() {
    SCRIPT_PATH="./0g-storage.sh"  # 定义脚本路径
    SCRIPT_URL="https://raw.githubusercontent.com/willsm18/linux-shell/main/0g-storage.sh"

    # 备份原始脚本
    cp $SCRIPT_PATH "${SCRIPT_PATH}.bak"

    # 下载新脚本并检查是否成功
    if curl -o $SCRIPT_PATH $SCRIPT_URL; then
        chmod +x $SCRIPT_PATH
        echo "脚本已更新。请退出脚本后，执行bash 0g.sh 重新运行此脚本。"
    else
        echo "更新失败。正在恢复原始脚本。"
        mv "${SCRIPT_PATH}.bak" $SCRIPT_PATH
    fi

}

# 主菜单
function main_menu() {
    while true; do
        clear
        echo "=======================存储节点功能================================"
        echo "1. 安装存储节点环境"
	echo "2. 安装存储节点"
        echo "3. 查看存储节点日志"
        echo "4. 过滤错误日志"
        echo "5. 重启存储节点"
        echo "6. 卸载存储节点"
        echo "7. 修改日志等级"
        echo "8. 统计日志文件大小"
        echo "9. 删除存储节点日志"
        read -p "请输入选项（1-8）: " OPTION

        case $OPTION in
        1) install_storage_node_env ;;
	2) install_storage_node ;;
        3) check_storage_logs ;;
        4) check_storage_error;;
        5) restart_storage ;;
        6) uninstall_storage_node ;;
        7) change_storage_log_level ;;
        8) storage_logs_disk_usage ;;
        9) delete_storage_logs ;;
        *) echo "无效选项。" ;;
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done

}

# 显示主菜单
main_menu
