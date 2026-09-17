#!/bin/bash

# =================================================================
# TOOLS: SESSION ID UPDATER
# Function: Replace the PHPSESSID in all attack scripts at once
# =================================================================

# 1. Ask the user for the new ID
echo -e "\e[33m[INPUT] Please paste the new PHPSESSID from DVWA:\e[0m"
read -p "ID > " NEW_ID

# Validate input (must not be empty)
if [ -z "$NEW_ID" ]; then
    echo -e "\e[31m[ERROR] ID cannot be empty!\e[0m"
    exit 1
fi

# 2. List of files to update
# Adjust the folder path if the scripts are under the attacks/ folder
FILES=(
    "attacks/04_sqlmap.sh"
    "attacks/05_xss.sh"
    "attacks/06_trav.sh"
)

echo ""
echo -e "\e[34m[PROCESS] Updating the session ID to: $NEW_ID ...\e[0m"

# 3. Loop through each file and update it
for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        # SED TECHNIQUE:
        # Find the pattern 'PHPSESSID=....' and replace it with the new ID
        # Regex [a-zA-Z0-9]* matches the old ID characters
        sed -i "s/PHPSESSID=[a-zA-Z0-9_]*/PHPSESSID=$NEW_ID/g" "$FILE"
        
        echo -e " -> [OK] Updated: $FILE"
    else
        echo -e "\e[31m -> [SKIP] File not found: $FILE\e[0m"
    fi
done

echo ""
echo -e "\e[32m[SUCCESS] All scripts are ready to use with the new session ID!\e[0m"

# 4. Verification (optional: display the updated line)
echo "-----------------------------------------------------"
grep "PHPSESSID" attacks/04_sqlmap.sh | head -n 1
echo "-----------------------------------------------------"
