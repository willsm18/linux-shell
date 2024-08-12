#!/bin/bash

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

prompt() {
    local message="$1"
    read -p "$message" input
    echo "$input"
}

execute_and_prompt() {
    local message="$1"
    local command="$2"
    echo -e "${YELLOW}${message}${NC}"
    eval "$command"
    echo -e "${GREEN}Done.${NC}"
}

echo -e "${YELLOW}Installing Rust...${NC}"
echo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
echo -e "${GREEN}Rust installed: $(rustc --version)${NC}"
echo

echo -e "${YELLOW}Removing Node.js...${NC}"
echo
sudo apt-get remove -y nodejs
echo

echo -e "${YELLOW}Installing NVM and Node.js LTS...${NC}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
sleep 2
source ~/.bashrc
nvm install --lts
nvm use --lts
echo -e "${GREEN}Node.js installed: $(node -v)${NC}"
echo
if [ -d "testnet-deposit" ]; then
    execute_and_prompt "Removing existing testnet-deposit folder..." "rm -rf testnet-deposit"
fi
echo -e "${YELLOW}Cloning repository and installing npm dependencies...${NC}"
echo
git clone https://github.com/Eclipse-Laboratories-Inc/testnet-deposit
cd testnet-deposit
npm install
echo

echo -e "${YELLOW}Installing Solana CLI...${NC}"
echo

sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

echo -e "${GREEN}Solana CLI installed: $(solana --version)${NC}"
echo
echo -e "${YELLOW}Choose an option:${NC}"
echo -e "1) Create a new Solana wallet"
echo -e "2) Import an existing Solana wallet"

read -p "Enter your choice (1 or 2): " choice

WALLET_FILE=~/my-wallet.json
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
NEW_WALLET_FILE="${WALLET_FILE%.json}_$TIMESTAMP.json"

# Check if the wallet file exists
if [ -f "$WALLET_FILE" ]; then
    echo -e "${YELLOW}Existing wallet file found. Removing it...${NC}"
    mv "$WALLET_FILE" "$NEW_WALLET_FILE"
fi

if [ "$choice" -eq 1 ]; then
    echo -e "${YELLOW}Generating new Solana keypair...${NC}"
    solana-keygen new -o "$WALLET_FILE"
    echo -e "${YELLOW}Save these mnemonic phrases in a safe place. If there is any airdrop in the future, you will be eligible from this wallet, so save it.${NC}"
elif [ "$choice" -eq 2 ]; then
    echo -e "${YELLOW}Recovering existing Solana keypair...${NC}"
    solana-keygen recover -o "$WALLET_FILE"
else
    echo -e "${RED}Invalid choice. Exiting.${NC}"
    exit 1
fi

read -p "Enter your mneomic phrase: " mnemonic
echo

cat << EOF > secrets.json
{
  "seedPhrase": "$mnemonic"
}
EOF

cat << 'EOF' > derive-wallet.cjs
const { seedPhrase } = require('./secrets.json');
const { HDNodeWallet } = require('ethers');
const fs = require('fs');

const mnemonicWallet = HDNodeWallet.fromPhrase(seedPhrase);
const privateKey = mnemonicWallet.privateKey;

console.log();
console.log('ETHEREUM PRIVATE KEY:', privateKey);
console.log();
console.log('SEND MIN 0.05 SEPOLIA ETH TO THIS ADDRESS:', mnemonicWallet.address);

fs.writeFileSync('pvt-key.txt', privateKey, 'utf8');
EOF

if ! npm list ethers &>/dev/null; then
  echo "ethers.js not found. Installing..."
  echo
  npm install ethers
  echo
fi

node derive-wallet.cjs
echo

echo -e "${YELLOW}Configuring Solana CLI...${NC}"
echo
solana config set --url https://testnet.dev2.eclipsenetwork.xyz/
solana config set --keypair ~/my-wallet.json
echo
echo -e "${GREEN}Solana Address: $(solana address)${NC}"
echo