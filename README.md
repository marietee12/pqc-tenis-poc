# PQC Tenis PoC

Demo de TLS 1.3 con criptografía post-cuántica (ML-DSA-65 + X25519MLKEM768) usando el soporte nativo de OpenSSL 3.5, sin depender de oqs-provider.

## Probarlo con la imagen publicada
docker pull ghcr.io/marietee12/pqc-tenis-poc:latest
docker run -p 8443:8443 ghcr.io/marietee12/pqc-tenis-poc:latest

Abre https://localhost:8443 en un navegador con soporte ML-KEM (Chrome 131+, Firefox 132+).

## Construirlo desde el código
docker build -t pqc-tenis-poc .
docker run -p 8443:8443 pqc-tenis-poc

## Verificar el intercambio de claves post-cuántico
openssl s_client -connect localhost:8443 -groups X25519MLKEM768 | grep "Negotiated"
