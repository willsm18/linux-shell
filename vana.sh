#!/bin/bash

# 安装 Docker
install_docker() {
    echo "安装 Docker..."
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    echo "Docker 安装完成。"
}

# 设置环境变量文件
setup_env_file() {
    echo "设置 .env 文件..."
    cp .env.example .env
    echo "请手动填充 DLP 特定的信息到 .env 文件中。"
}

# 安装必要的依赖项
install_dependencies() {
    echo "安装依赖项..."
    sudo apt update -y
    sudo apt install -y git python3.11 python3-pip nodejs npm
    pip install poetry
    echo "依赖项安装完成。"
}

# 克隆仓库
clone_repo() {
    echo "克隆 vana-dlp-chatgpt 仓库..."
    git clone https://github.com/vana-com/vana-dlp-chatgpt.git
    cd vana-dlp-chatgpt
}

# 安装 Python 依赖项
install_python_dependencies() {
    echo "安装 Python 依赖项..."
    poetry install
}

# 安装 vana CLI 工具
install_vana_cli() {
    echo "安装 vana CLI..."
    pip install vana
}

# 创建钱包
create_wallet() {
    echo "创建钱包..."
    vanacli wallet create --wallet.name default --wallet.hotkey default
    echo "请保存钱包的助记词。"
}

# 导出钱包的私钥
export_private_keys() {
    echo "导出冷钱包和热钱包私钥..."
    vanacli wallet export_private_key --wallet.name default --key.type coldkey
    vanacli wallet export_private_key --wallet.name default --key.type hotkey
    echo "请手动将这些私钥导入 Metamask 中。"
}

# 添加 Satori 测试网到 Metamask
add_satori_to_metamask() {
    echo "请手动添加 Satori 测试网到 Metamask，使用以下信息："
    echo "网络名称: Satori Testnet"
    echo "RPC URL: https://rpc.satori.vana.org"
    echo "链ID: 14801"
    echo "货币符号: VANA"
}

# 部署 DLP 智能合约
deploy_dlp_contracts() {
    echo "克隆 vana-dlp-smart-contracts 仓库..."
    cd ..
    git clone https://github.com/vana-com/vana-dlp-smart-contracts.git
    cd vana-dlp-smart-contracts
    echo "安装智能合约依赖项..."
    yarn install

    echo "配置 .env 文件并导入冷钱包私钥..."
    read -p "请输入您的冷钱包私钥: " coldkey_private_key
    echo "DEPLOYER_PRIVATE_KEY=$coldkey_private_key" >> .env
    echo "OWNER_ADDRESS=<你的冷钱包地址>" >> .env
    echo "SATORI_RPC_URL=https://rpc.satori.vana.org" >> .env
    echo "DLP_NAME=<你的DLP名称>" >> .env
    echo "DLP_TOKEN_NAME=<你的DLP代币名称>" >> .env
    echo "DLP_TOKEN_SYMBOL=<你的DLP代币符号>" >> .env

    echo "部署智能合约..."
    npx hardhat deploy --network satori --tags DLPDeploy
}

# 配置 DLP
configure_dlp() {
    echo "配置 DLP 合约..."
    echo "请访问 https://satori.vanascan.io/address/ 并执行配置操作。"
}

# 运行验证者节点
run_validator_node() {
    echo "启动验证者节点..."
    poetry run python -m chatgpt.nodes.validator
}

# 主菜单
show_menu() {
    echo "请选择一个操作:"
    echo "1. 安装 Docker"
    echo "2. 安装依赖项"
    echo "3. 克隆仓库并安装依赖项"
    echo "4. 创建钱包并导入私钥"
    echo "5. 部署 DLP 智能合约"
    echo "6. 配置 DLP"
    echo "7. 运行验证者节点"
    echo "8. 退出"
}

# 主循环
while true; do
    show_menu
    read -p "请输入选项 (1/2/3/4/5/6/7/8): " choice
    case $choice in
        1)
            install_docker
            ;;
        2)
            install_dependencies
            ;;
        3)
            clone_repo
            install_python_dependencies
            ;;
        4)
            create_wallet
            export_private_keys
            add_satori_to_metamask
            ;;
        5)
            deploy_dlp_contracts
            ;;
        6)
            configure_dlp
            ;;
        7)
            run_validator_node
            ;;
        8)
            echo "退出脚本。"
            exit 0
            ;;
        *)
            echo "无效选项，请输入 1, 2, 3, 4, 5, 6, 7 或 8."
            ;;
    esac
done
