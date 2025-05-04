#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <clientname>"
  exit 1
fi

CLIENT="$1"

# Check if CA files exist
if [[ -f caKey.pem && -f caCert.pem ]]; then
  echo "[+] Reusing existing caKey.pem and caCert.pem"
else
  echo "[+] Generating new CA key and certificate..."
  pki --gen --type falcon1024 --outform pem > caKey.pem
  pki --self --type priv --in caKey.pem --ca --lifetime 3652 \
      --dn "C=CH, O=SynergyQuantum, CN=PQ VPN CA" \
      --outform pem > caCert.pem
fi

# Create client directory and subdirectories
echo "[+] Setting up folder structure for client: $CLIENT"
mkdir -p "$CLIENT"/{ecdsa,pkcs12,pkcs8,private,pubkey,rsa,x509,x509ca,x509aa,x509ac,x509crl,x509ocsp}

# Generate client key and certificate
echo "[+] Generating client key and certificate..."
pki --gen --type dilithium5 --outform pem > "$CLIENT/pkcs8/${CLIENT}Key.pem"

pki --issue --cacert caCert.pem --cakey caKey.pem \
    --type priv --in "$CLIENT/pkcs8/${CLIENT}Key.pem" --lifetime 1461 \
    --dn "C=CH, O=SynergyQuantum, CN=${CLIENT}.synergyquantum.in" \
    --san "${CLIENT}.synergyquantum.in" --outform pem > "$CLIENT/x509/${CLIENT}Cert.pem"

# Copy CA cert to client folder
cp caCert.pem "$CLIENT/x509ca/"

echo "[+] All done. Certificates and keys generated for '$CLIENT'."