#!/bin/bash
ipset create asic_farms hash:net -exist

while true; do
    # 1. تحديث القوائم
    curl -sSL "https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=$(curl -s https://api.ipify.org)" -o /tmp/tor_ips.txt
    curl -s https://raw.githubusercontent.com/X4BNet/lists_vpn/main/ipv4.txt | grep -E "DataCenter|Hosting" | awk '{print $1}' > /tmp/farms.txt

    # 2. إضافة للقائمة السوداء
    cat /tmp/tor_ips.txt /tmp/farms.txt | grep -v '^#' | while read -r ip; do
        ipset add asic_farms "$ip" -exist
    done

    # 3. تطهير المحفظة (طرد أي IP موجود في القائمة السوداء حالياً)
    for connected_ip in $(/root/litecoin/src/aure-cli getpeerinfo | grep '"addr":' | awk -F'"' '{print $4}' | cut -d: -f1); do
        if ipset test asic_farms "$connected_ip" 2>/dev/null; then
            /root/litecoin/src/aure-cli setban "$connected_ip" add 86400
            echo "--- تم ركل وتطهير: $connected_ip ---"
        fi
    done

    # 4. التأكد من قاعدة الجدار
    iptables -C INPUT -m set --match-set asic_farms src -p tcp --dport 11995 -j DROP 2>/dev/null || \
    iptables -I INPUT -m set --match-set asic_farms src -p tcp --dport 11995 -j DROP

    sleep 30
done
