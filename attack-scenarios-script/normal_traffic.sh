#!/bin/bash

# --- KONFIGURASI TARGET ---
# PENTING: Ganti 'x.x' dengan IP Metasploitable Anda!
TARGET_IP="192.168.x.x"
TARGET_USER="msfadmin"
TARGET_PASS="msfadmin"
SAFE_EXE_URL="http://live.sysinternals.com/procmon.exe"

echo "[+] MEMULAI SIMULASI TRAFFIC NORMAL"
echo "[+] Target: $TARGET_IP"
echo "================================================================="

# -----------------------------------------------------------------
# 1. DOWNLOAD FILE BINARY (.exe)
# Dokumen: "wget file .exe dari web HTTP... admin download tools kerja"
# -----------------------------------------------------------------
echo "[1/7] Simulasi Download File .exe (Legal Tools)..."
# PERBAIKAN: Ditambah -T 10 (timeout) agar tidak hang jika internet lemot
wget -q -T 10 --user-agent="Mozilla/5.0 (Windows NT 10.0)" $SAFE_EXE_URL -O /dev/null
echo "	-> Status: Done. (Target Alert: ET POLICY PE EXE)"
sleep 2

# -----------------------------------------------------------------
# 2. UPDATE SYSTEM / CLI BROWSING
# Dokumen: "curl atau apt-get ke website luar... update OS wajar"
# -----------------------------------------------------------------
echo "[2/7] Simulasi System Update (User-Agent CLI)..."
# PERBAIKAN: Menghapus tanda kutip (") berlebih di akhir baris yang bikin error
# Ditambah -m 10 (max time) 
curl -s -m 10 -A "Debian APT-HTTP/1.3 (1.0.1ubuntu2)" "http://archive.ubuntu.com/ubuntu/dists/bionic/Release" > /dev/null
echo "	-> Status: Done. (Target Alert: ET POLICY GNU/Linux APT)"
sleep 2

# -----------------------------------------------------------------
# 3. SSH LOGIN AGRESIF (VALID LOGIN)
# Dokumen: "Login SSH dengan password BENAR berulang kali... admin rajin"
# -----------------------------------------------------------------
echo "[3/7] Simulasi SSH Login Berulang (Valid Credentials)..."
# PERBAIKAN: Mengubah {1...5} (salah) menjadi {1..5} (benar)
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
# Dokumen: "Ping dengan ukuran paket jumbo... diagnosa jaringan dasar"
# -----------------------------------------------------------------
echo "[4/7] Simulasi Network Diagnostic (Jumbo Ping 2000 bytes)..."
# Mengirim paket ICMP besar (2000 bytes)
ping -c 5 -s 2000 $TARGET_IP > /dev/null
echo "	-> Status: Done. (Target Alert: GPL ICMP INFO PING / Large Packet)"
sleep 2


# -----------------------------------------------------------------
# 5. FTP LOGIN (CLEARTEXT)
# Dokumen: "Login ke FTP Server... aktivitas wajar di jaringan lawas"
# -----------------------------------------------------------------
echo "[5/7] Simulasi FTP Login (Cleartext)..."
# Login FTP menggunakan curl (ditambah timeout -m 5)
curl -s -m 5 "ftp://$TARGET_USER:$TARGET_PASS@$TARGET_IP/" > /dev/null
echo "	-> Status: Done. (Target Alert: ET POLICY FTP Login Successful)"
sleep 2

# -----------------------------------------------------------------
# 6. DEV / NON-STANDARD PORT
# Dokumen: "Akses web server di port aneh (8180)... testing aplikasi"
# -----------------------------------------------------------------
echo "[6/7] Simulasi Akses Port Web Tidak Standar (8180)..."
# Mencoba akses HTTP ke port 8180 (Port Tomcat default di Metasploitable)
curl -s -m 3 "http://$TARGET_IP:8180/" > /dev/null
if [ $? -ne 0 ]; then
    echo "      (Note: Port 8180 mungkin tertutup, tapi request sudah dikirim)"
fi
echo "	-> Status: Done. (Target Alert: ET POLICY HTTP on non-standard port)"
sleep 2

# -----------------------------------------------------------------
# 7. "THE LOST USER" (404 STORM)
# Dokumen: "Request halaman web yang tidak ada secara beruntun... typo"
# -----------------------------------------------------------------
echo "[7/7] Simulasi 'Lost User' (Multiple 404 Errors)..."
for i in {1..5}
do
   # Request file acak yang tidak ada
   curl -s -o /dev/null "http://$TARGET_IP/file_rahasia_$RANDOM.php"
   curl -s -o /dev/null "http://$TARGET_IP/salah_ketik_$RANDOM.html"
done
echo "	-> Status: Done. (Target Alert: ET SCAN Potential HTTP 404)"

echo "================================================================="
echo "[+] SIMULASI SELESAI. Cek 'eve.json' untuk melihat False Positive."