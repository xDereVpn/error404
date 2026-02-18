#!/bin/bash
# Auto Install Dropbear 2019.78 to /usr/sbin/dropbear
# Oleh: (LT) Lunatic Tunneling

clear
echo "[1] Menghapus dropbear versi lama..."
pkill dropbear > /dev/null 2>&1
rm -f /usr/sbin/dropbear
rm -f /usr/local/sbin/dropbear
rm -f /usr/local/bin/dropbear
rm -f /usr/bin/dropbear
rm -rf ~/dropbear-*

echo "[2] Install dependensi..."
apt update -y
apt install -y build-essential zlib1g-dev wget

echo "[3] Download Dropbear 2019.78..."
cd ~
wget -q https://matt.ucc.asn.au/dropbear/releases/dropbear-2019.78.tar.bz2

echo "[4] Extract file..."
tar -xjf dropbear-2019.78.tar.bz2
cd dropbear-2019.78

echo "[5] Konfigurasi dan compile..."
./configure > /dev/null
make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" > /dev/null

echo "[6] Menyalin binary ke /usr/sbin..."
cp dropbear /usr/sbin/
chmod +x /usr/sbin/dropbear

echo "[7] Mengecek versi dropbear..."
/usr/sbin/dropbear -V

echo -e "\n[✓] Dropbear versi 2019.78 berhasil diinstall di /usr/sbin/dropbear"


chmod 755 /usr/sbin/dropbear
systemctl restart dropbear

rm -rf dropbear-2019.78
rm -rf dropbear-2019.78.tar.bz2
