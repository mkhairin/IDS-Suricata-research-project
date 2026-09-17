#!/bin/bash

# --- TARGET CONFIGURATION ---
# IMPORTANT: Replace 'x.x' with your Metasploitable IP!
TARGET_IP="192.168.x.x"
TARGET_USER="msfadmin"
TARGET_PASS="msfadmin"
SAFE_EXE_URL="http://live.sysinternals.com/procmon.exe"

echo "[+] STARTING NORMAL TRAFFIC SIMULATION"
echo "[+] Target: $TARGET_IP"
echo "================================================================="

# -----------------------------------------------------------------
# 1. DOWNLOAD BINARY FILE (.exe)
# Document: "wget a .exe file from an HTTP website... an admin downloads work tools"
# -----------------------------------------------------------------
echo "[1/7] Simulating .exe Download (Legitimate Tools)..."
# FIX: Added -T 10 (timeout) to avoid hanging if the internet is slow
wget -q -T 10 --user-agent="Mozilla/5.0 (Windows NT 10.0)" $SAFE_EXE_URL -O /dev/null
echo "	-> Status: Done. (Target Alert: ET POLICY PE EXE)"
sleep 2

# -----------------------------------------------------------------
# 2. SYSTEM UPDATE / CLI BROWSING
# Document: "curl or apt-get to external websites... normal OS updates"
# -----------------------------------------------------------------
echo "[2/7] Simulating System Update (CLI User-Agent)..."
# FIX: Removed extra quote marks at the end of the line that caused errors
# Added -m 10 (max time)
curl -s -m 10 -A "Debian APT-HTTP/1.3 (1.0.1ubuntu2)" "http://archive.ubuntu.com/ubuntu/dists/bionic/Release" > /dev/null
echo "	-> Status: Done. (Target Alert: ET POLICY GNU/Linux APT)"
sleep 2

# -----------------------------------------------------------------
# 3. AGGRESSIVE SSH LOGIN (VALID LOGIN)
# Document: "Repeated SSH login with the correct password... admin is active"
# -----------------------------------------------------------------
echo "[3/7] Simulating Repeated SSH Login (Valid Credentials)..."
# FIX: Changed {1...5} (incorrect) to {1..5} (correct)
for i in {1..5}
do
 sshpass -p "$TARGET_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 $TARGET_USER@$TARGET_IP "exit" 2>/dev/null
   echo -n "."
done
echo ""
echo "	-> Status: Done. (Target Alert: ET SCAN Potential SSH Brute Force)"
sleep 2

# -----------------------------------------------------------------
# 4. NETWORK DIAGNOSTIC (JUMBO PING)
# Document: "Ping with jumbo packet size... basic network diagnosis"
# -----------------------------------------------------------------
echo "[4/7] Simulating Network Diagnostic (Jumbo Ping 2000 bytes)..."
# Send large ICMP packets (2000 bytes)
ping -c 5 -s 2000 $TARGET_IP > /dev/null
echo "	-> Status: Done. (Target Alert: GPL ICMP INFO PING / Large Packet)"
sleep 2


# -----------------------------------------------------------------
# 5. FTP LOGIN (CLEARTEXT)
# Document: "Login to the FTP server... normal activity on older networks"
# -----------------------------------------------------------------
echo "[5/7] Simulating FTP Login (Cleartext)..."
# Login to FTP using curl (added timeout -m 5)
curl -s -m 5 "ftp://$TARGET_USER:$TARGET_PASS@$TARGET_IP/" > /dev/null
echo "	-> Status: Done. (Target Alert: ET POLICY FTP Login Successful)"
sleep 2

# -----------------------------------------------------------------
# 6. DEV / NON-STANDARD PORT
# Document: "Access a web server on an odd port (8180)... application testing"
# -----------------------------------------------------------------
echo "[6/7] Simulating Access to a Non-Standard Web Port (8180)..."
# Try HTTP access on port 8180 (default Tomcat port on Metasploitable)
curl -s -m 3 "http://$TARGET_IP:8180/" > /dev/null
if [ $? -ne 0 ]; then
    echo "      (Note: Port 8180 may be closed, but the request was still sent)"
fi
echo "	-> Status: Done. (Target Alert: ET POLICY HTTP on non-standard port)"
sleep 2

# -----------------------------------------------------------------
# 7. "THE LOST USER" (404 STORM)
# Document: "Request non-existent web pages repeatedly... typo-driven traffic"
# -----------------------------------------------------------------
echo "[7/7] Simulating 'Lost User' (Multiple 404 Errors)..."
for i in {1..5}
do
   # Request random non-existent files
   curl -s -o /dev/null "http://$TARGET_IP/file_secret_$RANDOM.php"
   curl -s -o /dev/null "http://$TARGET_IP/misspelled_$RANDOM.html"
done
echo "	-> Status: Done. (Target Alert: ET SCAN Potential HTTP 404)"

echo "================================================================="
echo "[+] SIMULATION COMPLETE. Check 'eve.json' to review False Positives."