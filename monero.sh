#!/bin/bash
#set name for display at herominers and user to use
#read -p "Enter a name for system (generally the hostname): " name
read -p "Enter the username to use (generally who you are logged in as): " user

name=$(hostname)
#user=$(whoami)

apt update && apt upgrade -y
apt install lm-sensors inxi unzip wget -y

#download xmrig monero miner
#wget https://github.com/xmrig/xmrig/releases/download/v6.13.1/xmrig-6.13.1-linux-x64.tar.gz
wget https://github.com/xmrig/xmrig/releases/download/v6.21.3/xmrig-6.21.3-linux-static-x64.tar.gz

#decompress xmrig monero miner
#tar -xzf xmrig-6.13.1-linux-x64.tar.gz
tar -xzf xmrig-6.21.3-linux-static-x64.tar.gz

#remove xmrig compressed file
#rm xmrig-6.13.1-linux-x64.tar.gz
rm xmrig-6.21.3-linux-static-x64.tar.gz

#set system type for laptop or desktop
read -n 1 -p "Is this system a [l]aptop, [d]esktop, desktop with [G]PU, or would you like to [e]xit? (L/D/E/G) " ans;
case $ans in

l|L)
echo
read -p "Enter the wifi password: " wifipass
port=3333
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
        "green":
          password: "$wifipass"
EOF
netplan apply;;
gpu_state=false

d|D)
port=5555
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
gpu_state=false

g|G)
port=5555
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
#install build tools
apt install build-essential cmake libuv1-dev libssl-dev libhwloc-dev software-properties-common -y
#download and make cuda
wget https://developer.download.nvidia.com/compute/cuda/12.4.1/local_installers/cuda-repo-debian12-12-4-local_12.4.1-550.54.15-1_amd64.deb
dpkg -i cuda-repo-debian12-12-4-local_12.4.1-550.54.15-1_amd64.deb
cp /var/cuda-repo-debian12-12-4-local/cuda-*-keyring.gpg /usr/share/keyrings/
add-apt-repository contrib
apt update
apt install cuda-toolkit-12-4 -y
#download and install xmrig cuda from source
git clone https://github.com/xmrig/xmrig-cuda.git
mkdir xmrig-cuda/build && cd xmrig-cuda/build
cmake .. -DCUDA_LIB=/usr/local/cuda/lib64/stubs/libcuda.so -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda
make -j$(nproc)
# move cuda file(s) to main xmig directory
mv libxmrix-* /home/$user/xmrig-6.21.3/
# remove xmrig cuda directory
rm -rf /home/$user/xmrig-cuda
gpu_state=true

*)
exit;;

esac

#create xmrig config.json
cat > /home/$user/xmrig-6.21.3/config.json <<EOF
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
        "enabled": $gpu_state,
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
            "algo": "rx/0",
            "coin": "monero",
            "url": "pool.supportxmr.com:$port",
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
ExecStart=/home/$user/xmrig-6.21.3/xmrig
Restart=always

[Install]
WantedBy=multi-user.target
EOF

#enable xlarig service and reboot
systemctl enable xmrig
systemctl start xmrig

reboot now
