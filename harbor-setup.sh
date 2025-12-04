
#   ------------    Harbor Setup - Run below on Harbor VM    ------------

#!/bin/bash
set -e

# ------------ Docker Installation ------------

sudo apt update
sudo apt install -y docker.io docker-compose openssl
sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker $USER
newgrp docker

# ------------ Harbor Installation ------------

wget https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-online-installer-v2.10.0.tgz
tar xzf harbor-online-installer-v2.10.0.tgz
cd harbor

cp harbor.yml.tmpl harbor.yml
vi harbor.yml

# ------------ Edit harbor.yml accordingly ------------

hostname: < Harbor-IP-ADD >

https:
  port: 443
  certificate: /etc/harbor/certs/harbor.crt
  private_key: /etc/harbor/certs/harbor.key

sudo ./install.sh
sudo docker ps


# -------------------------------------------------------------------------------------

sudo mkdir -p /etc/harbor/certs
cd /etc/harbor/certs

sudo tee openssl.cnf > /dev/null <<EOF
[ req ]
default_bits       = 4096
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[ dn ]
C  = US
ST = State
L  = City
O  = MyOrg
OU = Dev
CN = < Harbor-IP-ADD >

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
IP.1 = < Harbor-IP-ADD >
EOF

sudo openssl genrsa -out ca.key 4096
sudo openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
    -out ca.crt -subj "/CN=Harbor-CA"

sudo openssl genrsa -out harbor.key 4096
sudo openssl req -new -key harbor.key -out harbor.csr -config openssl.cnf

sudo openssl x509 -req -in harbor.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out harbor.crt -days 3650 \
  -extensions req_ext -extfile openssl.cnf

sudo mkdir -p /etc/docker/certs.d/< Harbor-IP-ADD >
sudo cp ca.crt /etc/docker/certs.d/< Harbor-IP-ADD >/ca.crt
sudo systemctl restart docker

#   ------------    Check login from - Harbor machine    ------------

docker login https://< Harbor-IP-ADD >

# Username: admin

# Password: (from harbor.yml, default Harbor12345)


# -------------------------------------------------------------------------------------


#   ------------    Harbor configuration - Run below on Jenkins VM    ------------

# Copy ca.crt into you jenkins machine 

sudo mkdir -p /etc/docker/certs.d/< Harbor-IP-ADD >
sudo cp ca.crt /etc/docker/certs.d/< Harbor-IP-ADD >/ca.crt
sudo systemctl restart docker


#   ------------    Check login from - Jenkins machine    ------------

docker login https://3.227.12.28

# Username: admin

# Password: (from harbor.yml, default Harbor12345)