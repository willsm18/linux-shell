#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

function check_and_install_dependencies() {
    # 检查是否已安装 Rust 和 Cargo
    if ! command -v cargo &> /dev/null; then
        echo "Rust 和 Cargo 未安装，正在安装..."
        curl https://sh.rustup.rs -sSf | sh -s -- -y
        source $HOME/.cargo/env
    else
        echo "Rust 和 Cargo 已安装。"
    fi

    # 检查是否已安装 Solana CLI
    if ! command -v solana-keygen &> /dev/null; then
        echo "Solana CLI 未安装，正在安装..."
        sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"
    else
        echo "Solana CLI 已安装。"
    fi

    # 检查是否已安装 Ore CLI
if ! ore -V &> /dev/null; then
    echo "Ore CLI 未安装，正在安装..."
    cargo install ore-cli
else
    echo "Ore CLI 已安装。"
fi

        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        export PATH="$HOME/.cargo/bin:$PATH"
}


# 查询奖励
function view_rewards() {
    ore --rpc https://api.mainnet-beta.solana.com --keypair ~/.config/solana/id.json rewards
}

# 领取奖励
function claim_rewards() {
    ore --rpc https://api.mainnet-beta.solana.com --keypair ~/.config/solana/id.json claim
}

function multiple() {
#!/bin/bash

echo "更新系统软件包..."
sudo apt update && sudo apt upgrade -y
echo "安装必要的工具和依赖..."
sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen
check_and_install_dependencies
  
}

multiple
