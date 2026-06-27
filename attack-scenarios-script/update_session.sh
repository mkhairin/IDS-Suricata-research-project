#!/bin/bash

# =================================================================
# TOOLS: SESSION ID UPDATER
# Fungsi: Mengganti PHPSESSID di semua script serangan sekaligus
# =================================================================

# 1. Minta Input ID Baru dari User
echo -e "\e[33m[INPUT] Silakan Paste PHPSESSID Baru dari DVWA:\e[0m"
read -p "ID > " NEW_ID

# Validasi input (tidak boleh kosong)
if [ -z "$NEW_ID" ]; then
    echo -e "\e[31m[ERROR] ID tidak boleh kosong!\e[0m"
    exit 1
fi

# 2. Daftar File Target yang mau diupdate
# Sesuaikan path folder ini jika script ada di dalam folder attacks/
FILES=(
    "attacks/04_sqlmap.sh"
    "attacks/05_xss.sh"
    "attacks/06_trav.sh"
)

echo ""
echo -e "\e[34m[PROCESS] Sedang mengupdate Session ID ke: $NEW_ID ...\e[0m"

# 3. Loop untuk mengupdate setiap file
for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        # TEKNIK SED:
        # Mencari pola 'PHPSESSID=...."' dan menggantinya dengan ID baru
        # Regex [a-zA-Z0-9]* artinya mencari deretan huruf/angka ID lama
        sed -i "s/PHPSESSID=[a-zA-Z0-9_]*/PHPSESSID=$NEW_ID/g" "$FILE"
        
        echo -e " -> [OK] Updated: $FILE"
    else
        echo -e "\e[31m -> [SKIP] File tidak ditemukan: $FILE\e[0m"
    fi
done

echo ""
echo -e "\e[32m[SUKSES] Semua script siap digunakan dengan Session ID baru!\e[0m"

# 4. Verifikasi (Opsional: Menampilkan baris yang berubah)
echo "-----------------------------------------------------"
grep "PHPSESSID" attacks/04_sqlmap.sh | head -n 1
echo "-----------------------------------------------------"
