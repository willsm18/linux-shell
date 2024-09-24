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

# 检查并安装 Git
check_git() {
  if ! git --version &> /dev/null; then
    echo "Git 未安装。正在安装 Git..."
    sudo apt update && sudo apt install -y git
  else
    echo "Git 已安装：$(git --version)"
  fi
}

# 检查并安装 Python 3.11
check_python() {
  if ! python3.11 --version &> /dev/null; then
    echo "Python 3.11 未安装。正在安装 Python 3.11..."
    sudo apt update && sudo apt install -y software-properties-common
    sudo add-apt-repository ppa:deadsnakes/ppa
    sudo apt update && sudo apt install -y python3.11 python3.11-venv python3.11-dev
  else
    sudo apt update && sudo apt install -y software-properties-common
    sudo add-apt-repository ppa:deadsnakes/ppa
    sudo apt update && sudo apt install -y python3.11 python3.11-venv python3.11-dev
    echo "Python 3.11 已安装：$(python3.11 --version)"
  fi
}

# 检查并安装 Poetry
check_poetry() {
  if ! poetry --version &> /dev/null; then
    echo "Poetry 未安装。正在安装 Poetry..."
    curl -sSL https://install.python-poetry.org | python3.11 -
    echo "Poetry 已安装：$(poetry --version)"
  else
    echo "Poetry 已安装：$(poetry --version)"
  fi
}

# 检查并安装 Node.js 和 npm
check_node_npm() {
  if ! node --version &> /dev/null; then
    echo "Node.js 未安装。正在安装 Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
  else
    echo "Node.js 已安装：$(node --version)"
  fi

  if ! npm --version &> /dev/null; then
    echo "npm 未安装。正在安装 npm..."
    sudo apt install -y npm
  else
    echo "npm 已安装：$(npm --version)"
  fi
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
    # 执行检查并安装
    check_git
    check_python
    check_poetry
    check_node_npm
    clone_repo
    echo "依赖项安装完成。"
}

# 克隆仓库
clone_repo() {
    echo "克隆 vana-dlp-chatgpt 仓库..."
    git clone https://github.com/vana-com/vana-dlp-chatgpt.git
    cd vana-dlp-chatgpt
    install_python_dependencies
}

# 安装 项目依赖项
install_python_dependencies() {
    echo "使用 pip 安装 vana..."
    pip install vana || { echo "依赖安装失败，脚本终止"; exit 1; }
}

# 安装 vana CLI 工具
install_vana_cli() {
    echo "安装 vana CLI..."
    pip install vana
}

# 运行密钥生成函数
function run_keygen() {
    echo "运行密钥生成..."
    ./keygen.sh
    echo "请输入您的姓名、电子邮件和密钥时长。"
}

# 创建钱包
create_wallet() {
    echo "创建钱包..."
    cd vana-dlp-chatgpt
    ./vanacli wallet create --wallet.name default --wallet.hotkey default
    echo "请保存钱包的助记词。"
    run_keygen
    export_private_keys
    add_satori_to_metamask
}

# 导出钱包的私钥
export_private_keys() {
    echo "导出冷钱包和热钱包私钥..."
    ./vanacli wallet export_private_key --wallet.name default --key.type coldkey
    ./vanacli wallet export_private_key --wallet.name default --key.type hotkey
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
    sudo apt install -y cmdtest
    npm install --global yarn
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
    cd vana-dlp-chatgpt
    poetry run python -m chatgpt.nodes.validator
}

# 主菜单
function main_menu() {
    # 主循环
    while true; do
        clear
        echo "请选择一个操作:"
        echo "1. 安装 Docker"
        echo "2. 安装依赖项"
        echo "3. 创建钱包并导入私钥"
        echo "4. 部署 DLP 智能合约"
        echo "5. 配置 DLP"
        echo "6. 运行验证者节点"
        echo "7. 退出"
        read -p "请输入选项 (1/2/3/4/5/6/7/8): " choice
        case $choice in
            1) install_docker;;
            2) install_dependencies;;
            3) create_wallet;;
            4) deploy_dlp_contracts;;
            5) configure_dlp;;
            6) run_validator_node;;
            7) echo "退出脚本。"
                exit 0;;
            *) echo "无效选项，请输入 1, 2, 3, 4, 5, 6, 7 或 8.";;
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done
}
# 显示主菜单
main_menu
