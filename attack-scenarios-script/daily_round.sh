#!/bin/bash

# =================================================================
# FILE: daily_round.sh (THE BOSS SCRIPT) - REVISI BATCH SUPPORT
# Deskripsi: Otomatisasi Pengujian IDS Berbasis Ronde Campuran
# Metodologi: Interleaved Design (Serangan + Trafik Normal)
# =================================================================

# --- KONFIGURASI INPUT (AGAR BISA DICICIL) ---
# Jika dijalankan tanpa angka, default jalankan Ronde 1 sampai 30
START_ROUND=${1:-1}
END_ROUND=${2:-30}

# --- KONFIGURASI JEDA WAKTU ---
DELAY_BETWEEN_ATTACKS=30  # Jeda istirahat antar serangan (detik)
DELAY_BETWEEN_NOISE=20    # Jeda istirahat setelah trafik normal (detik)
DELAY_BETWEEN_ROUNDS=120  # Jeda istirahat antar ronde (detik)

# Warna untuk Output Terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fungsi hitung mundur visual
function countdown() {
    secs=$1
    echo -ne "${YELLOW}    [Wait] Cooling down ($secs s)... "
    while [ $secs -gt 0 ]; do
        echo -ne "$secs\033[0K\r${YELLOW}    [Wait] Cooling down ($secs s)... "
        sleep 1
        : $((secs--))
    done
    echo -e "${NC}Ready!"
}

# Fungsi menjalankan modul serangan (UPDATED: Terima Ronde)
function run_module() {
    SCRIPT_NAME=$1
    MODULE_TITLE=$2
    CURRENT_ROUND=$3  # Tangkap nomor ronde dari loop utama
    
    echo -e "${BLUE}[+] [ATTACK] Menjalankan Modul: ${MODULE_TITLE}${NC}"
    echo -e "${BLUE}    [Info] Mengirim instruksi Ronde ke-$CURRENT_ROUND ke script...${NC}"
    
    if [ -f "attacks/$SCRIPT_NAME" ]; then
        # Jalankan script dengan mengirim parameter ronde
        ./attacks/$SCRIPT_NAME "$CURRENT_ROUND"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}    -> Modul Serangan Selesai.${NC}"
        else
            echo -e "${RED}    -> Modul Error! Cek log.${NC}"
        fi
        countdown $DELAY_BETWEEN_ATTACKS
    else
        echo -e "${RED}[!] ERROR: attacks/$SCRIPT_NAME tidak ditemukan!${NC}"
    fi
    echo ""
}

# Fungsi menjalankan trafik normal (Noise)
function run_noise() {
    echo -e "${CYAN}[+] [NOISE] Menjalankan Normal Traffic (Aktivitas Legal)...${NC}"
    echo -e "${CYAN}    Tujuan: Simulasi aktivitas user di tengah serangan.${NC}"
    
    if [ -f "./normal_traffic.sh" ]; then
        # Menjalankan script normal traffic
        ./normal_traffic.sh
        
        echo -e "${GREEN}    -> Normal Traffic Selesai.${NC}"
        countdown $DELAY_BETWEEN_NOISE
    else
        echo -e "${RED}[!] ERROR: File normal_traffic.sh tidak ditemukan di folder utama!${NC}"
    fi
    echo ""
}

# =================================================================
# MAIN PROGRAM
# =================================================================
clear
echo "==========================================================="
echo -e "   ${RED}SURICATA IDS RESEARCH AUTOMATION${NC}"
echo "   Methodology: Interleaved (Attack + Normal Noise)"
echo "==========================================================="
echo "Target Run    : Ronde $START_ROUND sampai $END_ROUND"
echo "Jeda Serangan : $DELAY_BETWEEN_ATTACKS detik"
echo "Start Time    : $(date)"
echo "==========================================================="

# Cek Izin Eksekusi normal_traffic.sh & attacks
chmod +x normal_traffic.sh attacks/*.sh 2>/dev/null

echo ""

# Loop Ronde (Mengikuti Input User START s.d END)
for (( round=START_ROUND; round<=END_ROUND; round++ ))
do
    echo -e "${YELLOW}###########################################################"
    echo -e " MEMULAI RONDE KE-$round"
    
    # Info Visual Set Mode (Agar kita tahu sekarang Set A, B, atau C)
    if [ "$round" -le 10 ]; then
        echo -e " MODE: SET A (BASELINE / STANDARD)"
    elif [ "$round" -le 20 ]; then
        echo -e " MODE: SET B (EVASION / VARIATION 1)"
    else
        echo -e " MODE: SET C (ADVANCED / VARIATION 2)"
    fi
    
    echo -e " Waktu: $(date)"
    echo -e "###########################################################${NC}"
    echo ""

    # --- KELOMPOK 1: RECON & BRUTE FORCE ---
    # Kita kirim variabel "$round" ke fungsi run_module
    run_module "01_nmap.sh" "01 - Port Scanning (Nmap)" "$round"
    run_module "02_hydra.sh" "02 - SSH Brute Force (Hydra)" "$round"

    # >>> SISIPAN 1: NORMAL TRAFFIC <<<
    run_noise

    # --- KELOMPOK 2: NETWORK STRESS ---
    run_module "03_dos.sh" "03 - DoS Attack (Hping3)" "$round"
    
    # --- KELOMPOK 3: WEB ATTACKS ---
    run_module "04_sqlmap.sh" "04 - SQL Injection (Sqlmap)" "$round"

    # >>> SISIPAN 2: NORMAL TRAFFIC <<<
    run_noise
    
    run_module "05_xss.sh" "05 - XSS Injection (Curl)" "$round"
    run_module "06_trav.sh" "06 - Path Traversal (Curl)" "$round"
    
    # --- KELOMPOK 4: EXPLOITATION ---
    run_module "07_rce.sh" "07 - RCE (Metasploit)" "$round"

    # --- AKHIR RONDE ---
    echo -e "${GREEN}>>> RONDE $round SELESAI.${NC}"
    
    if [ $round -lt $END_ROUND ]; then
        echo -e "${BLUE}Istirahat panjang sebelum ronde berikutnya...${NC}"
        countdown $DELAY_BETWEEN_ROUNDS
    else
        echo -e "${GREEN}BATCH INI SELESAI PADA $(date)!${NC}"
    fi
    echo ""
done

echo "==========================================================="
echo "Penelitian Selesai. Silakan analisis 'logs/' dan 'eve.json'"
echo "==========================================================="