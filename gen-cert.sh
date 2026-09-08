#!/usr/bin/env bash
set -e
echo "== Version de OpenSSL =="
openssl version

echo "== Generando certificado autofirmado ML-DSA-65 =="
openssl req -x509 -newkey ml-dsa-65 \
    -keyout /pqc-lab/certs/server.key \
    -out /pqc-lab/certs/server.crt \
    -days 365 -nodes \
    -subj "/CN=tenispro.local"
