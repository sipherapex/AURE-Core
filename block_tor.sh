#!/bin/bash
# تحميل قائمة عناوين تور
curl -sSL "https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=$(curl -s https://api.ipify.org)" -o /tmp/tor_ips.txt

# حظر كل عنوان في القائمة
while read -r ip; do
  # تجنب حظر السطور التي تبدأ بـ #
  [[ "$ip" =~ ^# ]] && continue
  iptables -A INPUT -s "$ip" -p tcp --dport 11995 -j DROP
done < /tmp/tor_ips.txt

echo "تم حظر جميع عقد تور عن المنفذ 11995 بنجاح."
