#!/bin/bash
#set name for display at herominers and user to use
read -p "Enter a name for system (generally the hostname): " name
read -p "Enter the username to use (generally who you are logged in as): " user

apt update && apt upgrade -y
apt install lm-sensors inxi unzip -y

#set system type for laptop or desktop
read -n 1 -p "Is this system a laptop, desktop, or would you like to exit? (L/D/E) " ans;
case $ans in
    l|L)
        echo
        read -p "Enter the wifi password: " wifipass
        port=1112
        lan=$(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}')
        wlan=$(ip link | awk -F: '$0 !~ "lo|vir|eno|eth|^[^0-9]"{print $2;getline}')
        #install wpa_supplicant, start and enable wpa_supplicant
        apt install wpasupplicant -y
        systemctl start wpa_supplicant
        systemctl enable wpa_supplicant
        #change settings so laptop lid does not turn off or sleep laptop
        sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
        sed -i 's/#HandleLidSwitchExternalPower=suspend/HandleLidSitchExternalPower=ignore/' /etc/systemd/logind.conf
        sed -i 's/#HandleLidSwitchDocked=ignore/HandleLidSwitchDocked=ignore/' /etc/systemd/logind.conf
        #add line to sshd conf for root login
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
        #remove all of cloud-init
        apt purge cloud-init -y
        rm -rf /etc/cloud/ && rm -rf /var/lib/cloud/
        #backup netplan file and create new one with correct network data
        mv /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.bak
        #create new netplan file
        cat > /etc/netplan/00-installer-config.yaml <<EOF
        network:
          version: 2
          ethernets:
            $lan:
              dhcp4: true
              optional: true
          wifis:
            $wlan:
              dhcp4: true
              optional: true
              access-points:
                "green"
                  password: "$wifipass"
EOF
        netplan apply;;
    d|D)
        port=1111
        lan=$(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}')
        #add line to sshd conf for root login
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
        #remove all of cloud-init
        echo 'datasource_list: [ None ]' | sudo -s tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg
        apt purge cloud-init -y
        rm -rf /etc/cloud/ && rm -rf /var/lib/cloud/
        #backup netplan file and create new one with correct network data
        mv /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.bak
        #create new netplan file
        cat > /etc/netplan/00-installer-config.yaml <<EOF
        network:
          version: 2
          ethernets:
            $lan:
              dhcp4: true
              optional: true
EOF
        netplan apply;;
    *)
        exit;;
esac
#download xmrig monero miner
wget https://github.com/xmrig/xmrig/releases/download/v6.13.1/xmrig-6.13.1-focal-x64.tar.gz
#decompress xmrig monero miner
tar -xzf /home/$user/xmrig/xmrig-6.13.1-focal-x64.tar.gz -C /home/$user/xmrig/
#remove xmrig compressed file
rm xmrig-6.13.1-focal-x64.tar.gz
#create config.json
cat > /home/$user/xmrig-6.13.1-focal-x64/config.json <<EOF
{
    "api": {
        "id": null,
        "worker-id": null
    },
    "http": {
        "enabled": false,
        "host": "127.0.0.1",
        "port": 0,
        "access-token": null,
        "restricted": true
    },
    "autosave": true,
    "background": false,
    "colors": true,
    "title": true,
    "randomx": {
        "init": -1,
        "init-avx2": -1,
        "mode": "auto",
        "1gb-pages": true,
        "rdmsr": true,
        "wrmsr": true,
        "cache_qos": false,
        "numa": true,
        "scratchpad_prefetch_mode": 1
    },
    "cpu": {
        "enabled": true,
        "huge-pages": true,
        "huge-pages-jit": false,
        "hw-aes": null,
        "priority": null,
        "memory-pool": false,
        "yield": true,
        "max-threads-hint": 100,
        "asm": true,
        "argon2-impl": null,
        "astrobwt-max-size": 550,
        "astrobwt-avx2": false,
        "cn/0": false,
        "cn-lite/0": false
    },
    "opencl": {
        "enabled": false,
        "cache": true,
        "loader": null,
        "platform": "AMD",
        "adl": true,
        "cn/0": false,
        "cn-lite/0": false
    },
    "cuda": {
        "enabled": false,
        "loader": null,
        "nvml": true,
        "cn/0": false,
        "cn-lite/0": false
    },
    "donate-level": null,
    "donate-over-proxy": null,
    "log-file": null,
    "pools": [
        {
            "algo": rx/0,
            "coin": monero,
            "url": "us.monero.herominers.com:$port"
            "user": "467vAdG8mRNW5mJHnySfXhHijx7BorgvNVqnjS8kKCXcTQev9oxuss4Hs1Xn3vApsAJDTLsQgU7uEK7UVxUcuc9cSCJbvWZ",
            "pass": "$name",
            "rig-id": null,
            "nicehash": false,
            "keepalive": false,
            "enabled": true,
            "tls": false,
            "tls-fingerprint": null,
            "daemon": false,
            "socks5": null,
            "self-select": null,
            "submit-to-origin": false
        }
    ],
    "print-time": 60,
    "health-print-time": 60,
    "dmi": true,
    "retries": 5,
    "retry-pause": 5,
    "syslog": false,
    "tls": {
        "enabled": false,
        "protocols": null,
        "cert": null,
        "cert_key": null,
        "ciphers": null,
        "ciphersuites": null,
        "dhparam": null
    },
    "user-agent": null,
    "verbose": 0,
    "watch": true,
    "pause-on-battery": false,
    "pause-on-active": false
}
EOF

#create xmrig service
cat > /etc/systemd/system/xmrig.service <<EOF
[Unit]
Description=xmrig Monero Miner
After=network.target
[Service]
User=root
Group=root
StandardOutput=journal
StandardError=journal
ExecStart=/home/$user/xmrig/xmrig
Restart=always
[Install]
WantedBy=multi-user.target
EOF

#enable xlarig service and reboot
systemctl enable xmrig
systemctl start xmrig

reboot now
