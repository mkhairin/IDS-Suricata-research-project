#!/bin/bash

# =================================================================
# FILE: daily_round.sh (THE BOSS SCRIPT) - BATCH SUPPORT REVISION
# Description: Automated Mixed-Round IDS Testing
# Methodology: Interleaved Design (Attack + Normal Traffic)
# =================================================================

# --- INPUT CONFIGURATION (SO IT CAN BE RUN IN PARTS) ---
# If run without numbers, the default is Round 1 to 30
START_ROUND=${1:-1}
END_ROUND=${2:-30}

# --- TIMING CONFIGURATION ---
DELAY_BETWEEN_ATTACKS=30  # Rest time between attacks (seconds)
DELAY_BETWEEN_NOISE=20    # Rest time after normal traffic (seconds)
DELAY_BETWEEN_ROUNDS=120  # Rest time between rounds (seconds)

# Colors for Terminal Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Visual countdown function
function countdown() {
    secs=$1
    echo -ne "${YELLOW}    [Wait] Cooling down ($secs s)... "
    while [ $secs -gt 0 ]; do
        echo -ne "$secs\033[0K\r${YELLOW}    [Wait] Cooling down ($secs s)... "
        sleep 1
        : $((secs--))
    done
    echo -e "${NC}Ready!"
}

# Function to run an attack module (UPDATED: Accepts Round)
function run_module() {
    SCRIPT_NAME=$1
    MODULE_TITLE=$2
    CURRENT_ROUND=$3  # Capture the round number from the main loop
    
    echo -e "${BLUE}[+] [ATTACK] Running Module: ${MODULE_TITLE}${NC}"
    echo -e "${BLUE}    [Info] Sending round instruction to script for round $CURRENT_ROUND...${NC}"
    
    if [ -f "attacks/$SCRIPT_NAME" ]; then
        # Run the script with the round parameter
        ./attacks/$SCRIPT_NAME "$CURRENT_ROUND"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}    -> Attack Module Complete.${NC}"
        else
            echo -e "${RED}    -> Module Error! Check logs.${NC}"
        fi
        countdown $DELAY_BETWEEN_ATTACKS
    else
        echo -e "${RED}[!] ERROR: attacks/$SCRIPT_NAME not found!${NC}"
    fi
    echo ""
}

# Function to run normal traffic (Noise)
function run_noise() {
    echo -e "${CYAN}[+] [NOISE] Running Normal Traffic (Legitimate Activity)...${NC}"
    echo -e "${CYAN}    Purpose: Simulate user activity during the attack.${NC}"
    
    if [ -f "./normal_traffic.sh" ]; then
        # Run the normal traffic script
        ./normal_traffic.sh
        
        echo -e "${GREEN}    -> Normal Traffic Complete.${NC}"
        countdown $DELAY_BETWEEN_NOISE
    else
        echo -e "${RED}[!] ERROR: normal_traffic.sh not found in the main folder!${NC}"
    fi
    echo ""
}

# =================================================================
# MAIN PROGRAM
# =================================================================
clear
echo "==========================================================="
echo -e "   ${RED}SURICATA IDS RESEARCH AUTOMATION${NC}"
echo "   Methodology: Interleaved (Attack + Normal Noise)"
echo "==========================================================="
echo "Target Run    : Round $START_ROUND to $END_ROUND"
echo "Attack Delay  : $DELAY_BETWEEN_ATTACKS seconds"
echo "Start Time    : $(date)"
echo "==========================================================="

# Check execution permissions for normal_traffic.sh and attacks
chmod +x normal_traffic.sh attacks/*.sh 2>/dev/null

echo ""

# Round loop (following user input START to END)
for (( round=START_ROUND; round<=END_ROUND; round++ ))
do
    echo -e "${YELLOW}###########################################################"
    echo -e " STARTING ROUND $round"
    
    # Visual info for set mode (so we know whether the current set is A, B, or C)
    if [ "$round" -le 10 ]; then
        echo -e " MODE: SET A (BASELINE / STANDARD)"
    elif [ "$round" -le 20 ]; then
        echo -e " MODE: SET B (EVASION / VARIATION 1)"
    else
        echo -e " MODE: SET C (ADVANCED / VARIATION 2)"
    fi
    
    echo -e " Time: $(date)"
    echo -e "###########################################################${NC}"
    echo ""

    # --- GROUP 1: RECON & BRUTE FORCE ---
    # We send the "$round" variable to the run_module function
    run_module "01_nmap.sh" "01 - Port Scanning (Nmap)" "$round"
    run_module "02_hydra.sh" "02 - SSH Brute Force (Hydra)" "$round"

    # >>> INSERT 1: NORMAL TRAFFIC <<<
    run_noise

    # --- GROUP 2: NETWORK STRESS ---
    run_module "03_dos.sh" "03 - DoS Attack (Hping3)" "$round"
    
    # --- GROUP 3: WEB ATTACKS ---
    run_module "04_sqlmap.sh" "04 - SQL Injection (Sqlmap)" "$round"

    # >>> INSERT 2: NORMAL TRAFFIC <<<
    run_noise
    
    run_module "05_xss.sh" "05 - XSS Injection (Curl)" "$round"
    run_module "06_trav.sh" "06 - Path Traversal (Curl)" "$round"
    
    # --- GROUP 4: EXPLOITATION ---
    run_module "07_rce.sh" "07 - RCE (Metasploit)" "$round"

    # --- END OF ROUND ---
    echo -e "${GREEN}>>> ROUND $round COMPLETE.${NC}"
    
    if [ $round -lt $END_ROUND ]; then
        echo -e "${BLUE}Long break before the next round...${NC}"
        countdown $DELAY_BETWEEN_ROUNDS
    else
        echo -e "${GREEN}THIS BATCH COMPLETED ON $(date)!${NC}"
    fi
    echo ""
done

echo "==========================================================="
echo "Research Complete. Please analyze 'logs/' and 'eve.json'"
echo "==========================================================="