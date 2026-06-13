#!/bin/bash

# =================================================================
# SKENARIO 01: PORT SCANNING (NMAP) - ROTASI PAYLOAD
# Strategi: 3 Level Depth (Basic, Evasion, Advanced)
# Input: Menerima argumen $1 sebagai Nomor Ronde
# =================================================================

# Menerima Input Nomor Ronde dari Daily Round
ROUND=${1:-1} # Default ke ronde 1 jika kosong

# KONFIGURASI
TARGET_IP="192.168.113.50" # Pastikan ini IP Metasploitable Anda
LOG_FILE="logs/nmap_session_$(date +%F).log"

# Warna untuk Tampilan Laporan
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =================================================================
# LOGIKA ROTASI PAYLOAD (PAYLOAD DIVERSITY)
# Mengubah teknik Level 2 & 3 berdasarkan fase ronde
# =================================================================
if [ "$ROUND" -le 10 ]; then
    # --- SET A (Ronde 1-10) ---
    # Level 2: Fragmentasi Standar (8 bytes)
    TECHNIQUE_L2="-f"
    DESC_L2="Fragmented Scan (Standard 8-byte)"
    
    # Level 3: FIN Scan
    TECHNIQUE_L3="-sF"
    DESC_L3="FIN Scan (Stealth)"

elif [ "$ROUND" -le 20 ]; then
    # --- SET B (Ronde 11-20) ---
    # Level 2: MTU Manipulation (16 bytes)
    TECHNIQUE_L2="--mtu 16"
    DESC_L2="MTU Fragmentation (16-byte)"
    
    # Level 3: Null Scan (No Flags)
    TECHNIQUE_L3="-sN"
    DESC_L3="Null Scan (No Flags)"

else
    # --- SET C (Ronde 21-30) ---
    # Level 2: Data Length Padding
    TECHNIQUE_L2="--data-length 25"
    DESC_L2="Data Length Padding (25 bytes junk)"
    
    # Level 3: Xmas Scan (Full Flags)
    TECHNIQUE_L3="-sX"
    DESC_L3="Xmas Scan (FIN, PSH, URG)"
fi

echo "[+] [01_NMAP] Memulai Skenario Port Scanning..."
echo "[+] Target: $TARGET_IP"
echo "[+] Mode: Ronde $ROUND ($DESC_L2 & $DESC_L3)"
echo "[+] Waktu Mulai: $(date)"

# -----------------------------------------------------------------
# LEVEL 1: NOISY / BASIC SCAN (BASELINE - TETAP SAMA)
# Tujuan: Baseline. Harus terdeteksi 100%.
# Teknik: Scan agresif (T4), Version Detection (-sV), All Ports.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 1] Running Aggresive Service Scan (-sV -T4)...${NC}"

# Simpan command ke variabel (Level 1 Selalu Statis)
CMD="nmap -sV -T4 -F $TARGET_IP"

# Tampilkan Command ke layar (Untuk Bukti Laporan)
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Eksekusi command asli (output disimpan ke file log)
$CMD -oN logs/nmap_lvl1_r${ROUND}.txt > /dev/null 2>&1
echo " -> Selesai. (Target: Alert ET SCAN / GPL SCAN berisik)"
sleep 5

# -----------------------------------------------------------------
# LEVEL 2: EVASION / FRAGMENTATION (DINAMIS)
# Tujuan: Menguji reassembly packet engine Suricata.
# Teknik: Berubah sesuai variabel $TECHNIQUE_L2
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 2] Running Evasion Scan ($DESC_L2)...${NC}"

# Simpan command ke variabel (Menggunakan variabel teknik dinamis)
CMD="nmap $TECHNIQUE_L2 -sS -p 21,22,80,3306 $TARGET_IP"

# Tampilkan Command ke layar
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Eksekusi command asli
$CMD -oN logs/nmap_lvl2_r${ROUND}.txt > /dev/null 2>&1
echo "    -> Selesai. (Harapan: Alert ET SCAN / Potential Evasion)"
sleep 5

# -----------------------------------------------------------------
# LEVEL 3: ADVANCED / STEALTH & DECOY (DINAMIS)
# Tujuan: Membingungkan Analyst & IDS.
# Teknik: Decoy (-D) ditambah teknik stealth $TECHNIQUE_L3
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 3] Running Decoy & Stealth Scan (-D RND + $DESC_L3)...${NC}"

# Simpan command ke variabel (Menggunakan variabel teknik dinamis)
CMD="nmap -D RND:5 $TECHNIQUE_L3 -p 80 $TARGET_IP"

# Tampilkan Command ke layar
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Eksekusi command asli
$CMD -oN logs/nmap_lvl3_r${ROUND}.txt > /dev/null 2>&1
echo "    -> Selesai. (Harapan: Deteksi IP Asli di antara Decoy)"

echo "[+] [01_NMAP] Skenario Selesai pada $(date)"
echo "-----------------------------------------------------------"