# PQC Tenis PoC

Prueba de concepto de **TLS 1.3 con criptografía post-cuántica (PQC)** usando el soporte nativo de OpenSSL 3.5 — sin depender de `oqs-provider` ni parches externos. Certificado firmado con **ML-DSA-65** (FIPS 204) e intercambio de claves híbrido **X25519MLKEM768** (FIPS 203).

Este proyecto forma parte del TFM *"Cifrado cuántico: eficacia y viabilidad"*, centrado en la adopción práctica de PQC en infraestructuras TLS reales.

## ¿Por qué esta PoC?

A partir de 2025-2026, los principales navegadores (Chrome, Firefox) empezaron a soportar de forma nativa el intercambio de claves post-cuántico híbrido. Sin embargo, el ecosistema de certificados y servidores web todavía está en transición. Esta PoC demuestra:

- Que es posible levantar un servidor TLS 1.3 completamente funcional con algoritmos post-cuánticos usando **solo OpenSSL 3.5**, sin necesidad de bibliotecas experimentales.
- La diferencia real de comportamiento entre un navegador con soporte PQC y uno sin él.

## Arquitectura

Cliente (navegador) ──TLS 1.3──> openssl s_server (contenedor Docker)
├── Certificado: ML-DSA-65
└── Key exchange: X25519MLKEM768

## Requisitos

- Docker instalado (`docker --version`)
- Un navegador con soporte ML-KEM para ver el caso "positivo": Chrome 131+, Firefox 132+
- (Opcional) un navegador/versión anterior para ver el caso "negativo": Chrome <124, Firefox <130, Safari (aún sin soporte a fecha de este README)

## Uso rápido

### Probarlo con la imagen publicada
docker pull ghcr.io/marietee12/pqc-tenis-poc:latest
docker run -p 8443:8443 ghcr.io/marietee12/pqc-tenis-poc:latest

### Construirlo desde el código
docker build -t pqc-tenis-poc .
docker run -p 8443:8443 pqc-tenis-poc

Una vez arrancado, visita: **https://localhost:8443**

> ⚠️ El certificado es autofirmado (`CN=tenispro.local`), tu navegador mostrará una advertencia de seguridad la primera vez. Es esperado en una PoC — acepta el riesgo para continuar.

## Verificar el intercambio de claves post-cuántico
Para confirmar que el intercambio de claves fue realmente post-cuántico:

openssl s_client -connect localhost:8443 -groups X25519MLKEM768 | grep "Negotiated"

Deberías ver `X25519MLKEM768` como grupo negociado.

## Comparativa: navegador con soporte PQC vs sin soporte

| | Navegador **con** soporte ML-KEM | Navegador **sin** soporte ML-KEM |
|---|---|---|
| Ejemplo | Chrome 131+, Firefox 132+ | Chrome <124, Firefox <130 |
| Grupo negociado | `X25519MLKEM768` (híbrido post-cuántico) | Fallback a `X25519` clásico, o error de handshake si se fuerza solo PQC |
| Indicador visual | Candado normal, conexión TLS 1.3 estándar (el navegador no distingue visualmente PQC de clásico) | Igual, salvo que la conexión use un grupo distinto — visible solo inspeccionando el handshake |
| Cómo comprobarlo | DevTools → Security tab → "Key Exchange Group" | Mismo panel, mostrará `x25519` en vez de `X25519MLKEM768` |

### Capturas

*(añadir imágenes en `docs/screenshots/` y referenciarlas aquí, ver sección siguiente)*

**Navegador con soporte PQC — negociación X25519MLKEM768:**
![Chrome con soporte PQC](docs/screenshots/chrome-pqc-ok.png)

**Navegador sin soporte PQC — fallback a X25519 clásico:**
![Navegador sin soporte PQC](docs/screenshots/browser-no-pqc.png)

**Verificación por terminal con openssl s_client:**
![Verificación openssl s_client](docs/screenshots/openssl-verify.png)

## Estructura del proyecto

.
├── Dockerfile # Compila OpenSSL 3.5.7 desde fuente
├── docker-compose.yml
├── entrypoint.sh # Genera certificado si no existe y arranca openssl s_server
├── gen-cert.sh # Genera certificado autofirmado ML-DSA-65
├── www/ # Contenido servido por openssl s_server -WWW
└── README.md


## Notas de seguridad

Esta imagen es una **PoC educativa**, no está pensada para producción:
- Usa `openssl s_server`, no un servidor web de producción (nginx, Apache).
- El certificado es autofirmado y sin rotación.
- No incluye autenticación ni rate limiting.

## Referencias

- [NIST FIPS 203 — ML-KEM](https://csrc.nist.gov/pubs/fips/203/final)
- [NIST FIPS 204 — ML-DSA](https://csrc.nist.gov/pubs/fips/204/final)
- [OpenSSL 3.5 Release Notes](https://openssl-library.org/news/)

## Autor

Mario — TFM *"Cifrado cuántico: eficacia y viabilidad"*
