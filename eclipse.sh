#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display the main menu
show_menu() {
    clear
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${CYAN}    Eclipse Node Automatic Install Toolkit    ${NC}"
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${GREEN}1. Install Eclipse Node (Complete Setup)${NC}"
    echo -e "${GREEN}2. Backup Your Wallet${NC}"
    echo -e "${GREEN}3. Start Mining${NC}"
    echo -e "${GREEN}4. Check Node Status & Manage Mining${NC}"
    echo -e "${GREEN}5. Show Public Key/Address${NC}"
    echo -e "${GREEN}6. Check System Requirements${NC}"
    echo -e "${RED}7. Exit${NC}"
    echo -e "${CYAN}==========================================${NC}"
    read -p "Enter your choice [1-7]: " choice
}

# Function to check system requirements
check_system() {
    echo -e "${YELLOW}=== System Requirements Check ===${NC}"
    
    # Check OS
    echo -n "OS: "
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        echo "$NAME $VERSION"
    else
        echo "Unknown (couldn't detect OS)"
    fi
    
    # Check CPU cores
    cores=$(nproc)
    echo -n "CPU Cores: $cores - "
    if [ $cores -ge 4 ]; then
        echo -e "${GREEN}✓ Sufficient${NC}"
    else
        echo -e "${YELLOW}⚠ Minimum 4 cores recommended${NC}"
    fi
    
    # Check RAM
    ram=$(free -g | awk '/Mem:/ {print $2}')
    echo -n "RAM (GB): $ram - "
    if [ $ram -ge 8 ]; then
        echo -e "${GREEN}✓ Sufficient${NC}"
    elif [ $ram -ge 4 ]; then
        echo -e "${YELLOW}⚠ Minimum 4GB (8GB recommended)${NC}"
    else
        echo -e "${RED}✗ Insufficient${NC}"
    fi
    
    # Check Storage
    storage=$(df -h / | awk 'NR==2 {print $4}')
    echo -n "Root FS Available: $storage - "
    
    # Check Rust installation
    echo -n "Rust: "
    if command -v rustc &> /dev/null; then
        echo -e "${GREEN}✓ Installed${NC}"
    else
        echo -e "${RED}✗ Not installed${NC}"
    fi
    
    # Check Solana installation
    echo -n "Solana CLI: "
    if command -v solana &> /dev/null; then
        echo -e "${GREEN}✓ Installed${NC}"
    else
        echo -e "${RED}✗ Not installed${NC}"
    fi
    
    # Check Bitz installation
    echo -n "Bitz Miner: "
    if command -v bitz &> /dev/null; then
        echo -e "${GREEN}✓ Installed${NC}"
    else
        echo -e "${RED}✗ Not installed${NC}"
    fi
    
    echo -e "\n${YELLOW}Note: For optimal performance, we recommend:"
    echo -e "- Ubuntu 20.04/22.04 LTS"
    echo -e "- 4+ CPU cores"
    echo -e "- 8GB+ RAM"
    echo -e "- 50GB+ free storage${NC}"
    
    read -p "Press Enter to continue..."
}

# Function to install Eclipse Node
install_eclipse_node() {
    echo -e "${YELLOW}=== Eclipse Node Installation ===${NC}"
    
    # Install Rust
    echo -e "${BLUE}[1/5] Installing Rust...${NC}"
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source $HOME/.cargo/env
        echo -e "${GREEN}Rust installed successfully!${NC}"
    else
        echo -e "${YELLOW}Rust already installed. Skipping...${NC}"
    fi
    
    # Install Solana
    echo -e "${BLUE}[2/5] Installing Solana...${NC}"
    if ! command -v solana &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSfL https://solana-install.solana.workers.dev | bash -s -- -y
        echo 'export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc
        source ~/.bashrc
        echo -e "${GREEN}Solana installed successfully!${NC}"
    else
        echo -e "${YELLOW}Solana already installed. Skipping...${NC}"
    fi
    
    # Generate new keypair
    echo -e "${BLUE}[3/5] Generating new keypair...${NC}"
    if [ ! -f ~/.config/solana/id.json ]; then
        echo -e "${YELLOW}Please set a passphrase for security or press Enter to skip${NC}"
        solana-keygen new
        echo -e "${GREEN}Keypair generated successfully!${NC}"
    else
        echo -e "${YELLOW}Keypair already exists at ~/.config/solana/id.json${NC}"
    fi
    
    # Install bitz
    echo -e "${BLUE}[4/5] Installing bitz miner...${NC}"
    if ! command -v bitz &> /dev/null; then
        cargo install bitz
        echo -e "${GREEN}Bitz miner installed successfully!${NC}"
    else
        echo -e "${YELLOW}Bitz already installed. Skipping...${NC}"
    fi
    
    # Set Solana config URL
    echo -e "${BLUE}[5/5] Configuring Solana CLI...${NC}"
    solana config set --url https://eclipse.helius-rpc.com/
    
    echo -e "\n${GREEN}=== Eclipse Node installation completed successfully! ===${NC}"
    echo -e "\n${YELLOW}Important Information:${NC}"
    echo -e "${BLUE}Public Key: ${NC}$(solana-keygen pubkey)"
    echo -e "${YELLOW}Please fund your wallet with at least 0.005 ETH to start mining.${NC}"
    read -p "Press Enter to continue..."
}

# Function to backup wallet
backup_wallet() {
    echo -e "${YELLOW}=== Wallet Backup ===${NC}"
    
    if [ ! -f ~/.config/solana/id.json ]; then
        echo -e "${RED}Wallet file not found! Have you run the installer?${NC}"
        read -
