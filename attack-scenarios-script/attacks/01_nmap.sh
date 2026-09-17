#!/bin/bash

# =================================================================
# SCENARIO 01: PORT SCANNING (NMAP) - PAYLOAD ROTATION
# Strategy: 3 Level Depth (Basic, Evasion, Advanced)
# Input: Receives argument $1 as the Round Number
# =================================================================

# Receive Input Round Number from Daily Round
ROUND=${1:-1} # Default to round 1 if empty

# CONFIGURATION
TARGET_IP="192.168.x.x" # Make sure this is your Metasploitable IP
LOG_FILE="logs/nmap_session_$(date +%F).log"

# Colors for Report Display
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =================================================================
# PAYLOAD ROTATION LOGIC (PAYLOAD DIVERSITY)
# Changes the Level 2 & 3 techniques based on the round phase
# =================================================================
if [ "$ROUND" -le 10 ]; then
    # --- SET A (Round 1-10) ---
    # Level 2: Standard Fragmentation (8 bytes)
    TECHNIQUE_L2="-f"
    DESC_L2="Fragmented Scan (Standard 8-byte)"
    
    # Level 3: FIN Scan
    TECHNIQUE_L3="-sF"
    DESC_L3="FIN Scan (Stealth)"

elif [ "$ROUND" -le 20 ]; then
    # --- SET B (Round 11-20) ---
    # Level 2: MTU Manipulation (16 bytes)
    TECHNIQUE_L2="--mtu 16"
    DESC_L2="MTU Fragmentation (16-byte)"
    
    # Level 3: Null Scan (No Flags)
    TECHNIQUE_L3="-sN"
    DESC_L3="Null Scan (No Flags)"

else
    # --- SET C (Round 21-30) ---
    # Level 2: Data Length Padding
    TECHNIQUE_L2="--data-length 25"
    DESC_L2="Data Length Padding (25 bytes junk)"
    
    # Level 3: Xmas Scan (Full Flags)
    TECHNIQUE_L3="-sX"
    DESC_L3="Xmas Scan (FIN, PSH, URG)"
fi

echo "[+] [01_NMAP] Starting Port Scanning Scenario..."
echo "[+] Target: $TARGET_IP"
echo "[+] Mode: Round $ROUND ($DESC_L2 & $DESC_L3)"
echo "[+] Start Time: $(date)"

# -----------------------------------------------------------------
# LEVEL 1: NOISY / BASIC SCAN (BASELINE - STAYS THE SAME)
# Goal: Baseline. Must be detected 100%.
# Technique: Aggressive scan (T4), Version Detection (-sV), All Ports.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 1] Running Aggressive Service Scan (-sV -T4)...${NC}"

# Store the command in a variable (Level 1 is always static)
CMD="nmap -sV -T4 -F $TARGET_IP"

# Display the command on screen (for reporting evidence)
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Execute the original command (output saved to log file)
$CMD -oN logs/nmap_lvl1_r${ROUND}.txt > /dev/null 2>&1
echo " -> Completed. (Target: noisy ET SCAN / GPL SCAN alerts)"
sleep 5

# -----------------------------------------------------------------
# LEVEL 2: EVASION / FRAGMENTATION (DYNAMIC)
# Goal: Test Suricata's reassembly packet engine.
# Technique: Changes according to $TECHNIQUE_L2
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 2] Running Evasion Scan ($DESC_L2)...${NC}"

# Store the command in a variable (using a dynamic technique variable)
CMD="nmap $TECHNIQUE_L2 -sS -p 21,22,80,3306 $TARGET_IP"

# Display the command on screen
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Execute the original command
$CMD -oN logs/nmap_lvl2_r${ROUND}.txt > /dev/null 2>&1
echo "    -> Completed. (Expected: ET SCAN / Potential Evasion alerts)"
sleep 5

# -----------------------------------------------------------------
# LEVEL 3: ADVANCED / STEALTH & DECOY (DYNAMIC)
# Goal: Confuse the analyst and IDS.
# Technique: Decoy (-D) plus stealth technique $TECHNIQUE_L3
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 3] Running Decoy & Stealth Scan (-D RND + $DESC_L3)...${NC}"

# Store the command in a variable (using a dynamic technique variable)
CMD="nmap -D RND:5 $TECHNIQUE_L3 -p 80 $TARGET_IP"

# Display the command on screen
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Execute the original command
$CMD -oN logs/nmap_lvl3_r${ROUND}.txt > /dev/null 2>&1
echo "    -> Completed. (Expected: Real IP detected among decoys)"

echo "[+] [01_NMAP] Scenario Completed at $(date)"
echo "-----------------------------------------------------------"