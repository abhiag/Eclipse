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
        # Install Solana
        curl --proto '=https' --tlsv1.2 -sSfL https://solana-install.solana.workers.dev | bash -s -- -y
        
        # Determine the correct installation path
        SOLANA_PATH="$HOME/.local/share/solana/install/active_release/bin"
        
        # Add to PATH if not already present
        if [[ ":$PATH:" != *":$SOLANA_PATH:"* ]]; then
            echo -e "${YELLOW}Adding Solana to PATH...${NC}"
            echo "export PATH=\"$SOLANA_PATH:\$PATH\"" >> ~/.bashrc
            
            # Also add to current session PATH
            export PATH="$SOLANA_PATH:$PATH"
            
            # Source bashrc for good measure
            source ~/.bashrc >/dev/null 2>&1
        fi
        
        # Verify installation
        if command -v solana &> /dev/null; then
            echo -e "${GREEN}Solana installed successfully!${NC}"
            echo -e "${YELLOW}Version: ${NC}$(solana --version)"
        else
            echo -e "${RED}Solana installation completed but could not verify.${NC}"
            echo -e "${YELLOW}Please check if $SOLANA_PATH exists and is in your PATH.${NC}"
        fi
    else
        echo -e "${YELLOW}Solana already installed.${NC}"
        echo -e "${YELLOW}Version: ${NC}$(solana --version)"
        echo -e "${YELLOW}Location: ${NC}$(which solana)"
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

# Function to handle wallet backup and restore
backup_wallet() {
    # Ensure Solana commands are available
    source ~/.bashrc 2>/dev/null
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

    while true; do
        clear
        echo -e "${YELLOW}=== Wallet Management ===${NC}"
        echo -e "1. ${GREEN}Backup${NC} private key"
        echo -e "2. ${CYAN}Import${NC} private key"
        echo -e "3. ${RED}Delete${NC} current wallet"
        echo -e "4. Return to main menu"
        read -p "Enter your choice [1-4]: " wallet_choice

        case $wallet_choice in
            1)
                echo -e "${YELLOW}=== Wallet Backup ===${NC}"
                
                if [ ! -f ~/.config/solana/id.json ]; then
                    echo -e "${RED}Wallet file not found!${NC}"
                    read -p "Press Enter to continue..."
                    continue
                fi

                echo -e "${BLUE}Your wallet information:${NC}"
                
                # Display public key if available
                if command -v solana-keygen >/dev/null 2>&1; then
                    echo -e "${CYAN}Public Key:${NC} $(solana-keygen pubkey)"
                else
                    echo -e "${YELLOW}Note: solana-keygen not found - cannot display public key${NC}"
                fi
                
                # Display the wallet contents with clear boundaries
                echo -e "\n${YELLOW}=== Wallet File Content ===${NC}"
                echo -e "${RED}╔══════════════════════════════════════════════════╗${NC}"
                echo -e "${RED}║ ██ WARNING: KEEP THIS INFORMATION EXTREMELY SECURE ██ ║${NC}"
                echo -e "${RED}╚══════════════════════════════════════════════════╝${NC}"
                echo -e "${GREEN}File location: ~/.config/solana/id.json${NC}\n"
                
                # Display the actual content with line numbers for easier copying
                echo -e "${CYAN}-----BEGIN WALLET DATA-----${NC}"
                cat -n ~/.config/solana/id.json
                echo -e "${CYAN}-----END WALLET DATA-----${NC}"
                
                # Create a backup file
                backup_file="eclipse_wallet_backup_$(date +%Y-%m-%d).json"
                cp ~/.config/solana/id.json "$backup_file"
                
                # Display backup information
                echo -e "\n${YELLOW}Backup Options:${NC}"
                echo -e "1. ${GREEN}Automated backup${NC} created at: ${BLUE}$(pwd)/$backup_file${NC}"
                echo -e "2. ${CYAN}Manual copy${NC} - You can:"
                echo -e "   - Select and copy the text above"
                echo -e "   - Paste into a new file when needed"
                echo -e "   - Use command: ${BLUE}cat > my_wallet_backup.json${NC} then paste contents"
                
                # Security warning
                echo -e "\n${RED}╔══════════════════════════════════════════════════╗${NC}"
                echo -e "${RED}║ ██  WARNING: ANYONE WITH THIS DATA CAN STEAL FUNDS  ██ ║${NC}"
                echo -e "${RED}║ ██  • Store encrypted copies only                 ██ ║${NC}"
                echo -e "${RED}║ ██  • Never share via unsecured channels          ██ ║${NC}"
                echo -e "${RED}╚══════════════════════════════════════════════════╝${NC}"
                
                read -p "Press Enter when you have securely stored this information..."
                ;;

            2)
    echo -e "${YELLOW}=== Import Private Key ===${NC}"
    echo -e "${YELLOW}Paste your wallet data (either JSON format or raw private key array):${NC}"
    echo -e "${CYAN}Example JSON format:${NC}"
    echo -e '{"version":3,"uuid":"...","crypto":{"ciphertext":"...","cipherparams":{"iv":"..."}}}'
    echo -e "${CYAN}Example raw key format:${NC}"
    echo -e "[139,13,109,131,168,149,106,106,72,122,225,...]"
    echo -e "\n${YELLOW}Press Ctrl+D when finished pasting${NC}"
    
    # Create temp file
    temp_file=$(mktemp)
    
    # Read pasted content
    cat > "$temp_file"
    
    # Check if input is JSON format
    if jq -e . "$temp_file" >/dev/null 2>&1; then
        # Valid JSON format
        mkdir -p ~/.config/solana
        cp "$temp_file" ~/.config/solana/id.json
        chmod 600 ~/.config/solana/id.json
        echo -e "\n${GREEN}✓ Wallet imported successfully (JSON format)${NC}"
        
    # Check if input is raw key array
    elif grep -q '^\[[0-9, ]*\]$' "$temp_file"; then
        # Convert raw array to JSON format
        echo -n '[' > ~/.config/solana/id.json
        tr -d '[]' < "$temp_file" | tr -s ' ' '\n' | grep -v '^$' | paste -sd, - >> ~/.config/solana/id.json
        echo ']' >> ~/.config/solana/id.json
        chmod 600 ~/.config/solana/id.json
        echo -e "\n${GREEN}✓ Wallet imported successfully (raw key format)${NC}"
        
    else
        echo -e "\n${RED}✗ Invalid input format!${NC}"
        echo -e "${YELLOW}Supported formats:${NC}"
        echo -e "1. Standard JSON wallet file"
        echo -e "2. Raw private key array like [139,13,109,...]"
        rm -f "$temp_file"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Cleanup
    rm -f "$temp_file"
    
    # Verify and show public key
    if command -v solana-keygen >/dev/null 2>&1; then
        echo -e "${CYAN}New public key:${NC} $(solana-keygen pubkey)"
    fi
    
    read -p "Press Enter to continue..."
                ;;

            3)
                echo -e "${YELLOW}=== Delete Wallet ===${NC}"
                if [ ! -f ~/.config/solana/id.json ]; then
                    echo -e "${RED}No wallet file found!${NC}"
                    read -p "Press Enter to continue..."
                    continue
                fi

                if command -v solana-keygen >/dev/null 2>&1; then
                    echo -e "${CYAN}Current public key:${NC} $(solana-keygen pubkey)"
                fi
                echo -e "\n${RED}WARNING: This will permanently delete your wallet file!${NC}"
                echo -e "${RED}Ensure you have a backup before proceeding!${NC}"
                read -p "Type 'CONFIRM DELETE' to proceed: " confirm
                
                if [ "$confirm" == "CONFIRM DELETE" ]; then
                    rm -f ~/.config/solana/id.json
                    echo -e "\n${GREEN}Wallet deleted successfully.${NC}"
                else
                    echo -e "${YELLOW}Deletion cancelled.${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;

            4)
                return
                ;;

            *)
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Function to start mining
start_mining() {
    echo -e "${YELLOW}=== Start Mining ===${NC}"
    
    # Check if screen exists
    if screen -list | grep -q "eclipse"; then
        echo -e "${YELLOW}Mining session already running in screen 'eclipse'${NC}"
        read -p "Do you want to restart it? [y/N]: " restart_choice
        if [[ $restart_choice =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Stopping existing mining session...${NC}"
            screen -S eclipse -X quit
            sleep 2
        else
            echo -e "${YELLOW}Returning to menu...${NC}"
            sleep 1
            return
        fi
    fi
    
    echo -e "${BLUE}Starting new mining session in screen...${NC}"
    screen -S eclipse -dm bash -c "bitz collect; exec bash"
    
    echo -e "\n${GREEN}Mining started successfully in screen session 'eclipse'!${NC}"
    echo -e "\n${YELLOW}Screen Commands:${NC}"
    echo -e "- Attach to session: ${CYAN}screen -r eclipse${NC}"
    echo -e "- Detach from session: ${CYAN}CTRL+A then D${NC}"
    echo -e "- List all screens: ${CYAN}screen -ls${NC}"
    echo -e "\n${YELLOW}Note: You need 0.005 ETH in your Eclipse wallet to start mining.${NC}"
    echo -e "${BLUE}Your address: ${NC}$(solana-keygen pubkey)"
    read -p "Press Enter to continue..."
}

# Function to check node status and manage mining
check_node_status() {
    while true; do
        clear
        echo -e "${YELLOW}=== Node Status & Mining Management ===${NC}"
        
        # Display public key
        echo -e "${BLUE}Your Public Key:${NC} $(solana-keygen pubkey)"
        
        # Check screen status
        if screen -list | grep -q "eclipse"; then
            echo -e "\n${GREEN}✔ Mining screen session is running${NC}"
            echo -e "${YELLOW}Screen Name:${NC} eclipse"
            echo -e "${YELLOW}Status:${NC} $(screen -ls | grep eclipse | awk '{print $NF}')"
            
            echo -e "\n${CYAN}Management Options:${NC}"
            echo -e "1. ${GREEN}Attach${NC} to mining session (view live output)"
            echo -e "2. ${YELLOW}Restart${NC} mining session"
            echo -e "3. ${RED}Stop${NC} mining session"
            echo -e "4. Return to main menu"
            
            read -p "Enter your choice [1-4]: " status_choice
            
            case $status_choice in
                1)
                    echo -e "${YELLOW}Attaching to mining session...${NC}"
                    echo -e "${CYAN}To detach later, press CTRL+A then D${NC}"
                    sleep 2
                    screen -r eclipse
                    ;;
                2)
                    echo -e "${YELLOW}Restarting mining session...${NC}"
                    screen -S eclipse -X quit
                    sleep 2
                    screen -S eclipse -dm bash -c "bitz collect; exec bash"
                    echo -e "${GREEN}Mining session restarted!${NC}"
                    sleep 2
                    ;;
                3)
                    echo -e "${RED}Stopping mining session...${NC}"
                    screen -S eclipse -X quit
                    echo -e "${GREEN}Mining session stopped.${NC}"
                    sleep 2
                    return
                    ;;
                4)
                    return
                    ;;
                *)
                    echo -e "${RED}Invalid option!${NC}"
                    sleep 1
                    ;;
            esac
        else
            echo -e "\n${RED}No active mining session found${NC}"
            
            echo -e "\n${CYAN}Options:${NC}"
            echo -e "1. ${GREEN}Start${NC} new mining session"
            echo -e "2. Return to main menu"
            
            read -p "Enter your choice [1-2]: " status_choice
            
            case $status_choice in
                1)
                    start_mining
                    ;;
                2)
                    return
                    ;;
                *)
                    echo -e "${RED}Invalid option!${NC}"
                    sleep 1
                    ;;
            esac
        fi
    done
}

# Function to show public key
show_public_key() {
    echo -e "${YELLOW}=== Wallet Address ===${NC}"
    echo -e "${BLUE}Your Public Key:${NC}"
    echo -e "$(solana-keygen pubkey)"
    
    echo -e "\n${YELLOW}Usage:${NC}"
    echo -e "- Use this address to receive ETH for mining"
    echo -e "- Share this address to receive payments"
    echo -e "- Fund with at least 0.005 ETH to start mining"
    
    echo -e "\n${CYAN}Quick copy command:${NC}"
    echo -e "solana-keygen pubkey | xclip -sel clip (Linux)"
    echo -e "solana-keygen pubkey | pbcopy (Mac)"
    
    read -p "Press Enter to continue..."
}

# Main program loop
while true; do
    show_menu
    case $choice in
        1) install_eclipse_node ;;
        2) backup_wallet ;;
        3) start_mining ;;
        4) check_node_status ;;
        5) show_public_key ;;
        6) check_system ;;
        7) echo -e "${RED}Exiting...${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option!${NC}"; sleep 2 ;;
    esac
done
