#!/usr/bin/env bash
set -e
mkdir -p /pqc-lab/certs
if [ ! -f /pqc-lab/certs/server.crt ]; then
    /pqc-lab/gen-cert.sh
fi

cd /pqc-lab/www
echo "== Sirviendo TenisPro Store con certificado ML-DSA en :8443 =="
exec openssl s_server \
    -cert /pqc-lab/certs/server.crt \
    -key /pqc-lab/certs/server.key \
    -accept 8443 \
    -WWW \
    -tls1_3 \
    -groups X25519MLKEM768:X25519:secp256r1
