# PQC Tenis Dual-Cert PoC

Prueba de concepto de **servidor TLS 1.3 con doble certificado** (post-cuántico + clásico), pensada para resolver el problema de compatibilidad detectado en la PoC hermana: [pqc-tenis-poc](https://github.com/marietee12/pqc-tenis-poc), donde los navegadores sin soporte ML-DSA no podían conectar en absoluto.

Este repo demuestra el patrón real de **crypto-agility** que las organizaciones necesitan durante la transición a PQC: servir un certificado **ML-DSA-65** a los clientes que lo soportan, y caer automáticamente a un certificado **ECDSA P-256** clásico para el resto — sin romper el servicio a nadie.

Forma parte del TFM *"Cifrado cuántico: eficacia y viabilidad"*.

## ¿Por qué esta PoC?

La PoC original (`pqc-tenis-poc`) sirve un único certificado ML-DSA-65. Cualquier cliente que no sepa verificar esa firma (Firefox y Edge en ciertas configuraciones, en las pruebas realizadas) recibe un `SSL_ERROR_NO_CYPHER_OVERLAP` y no puede acceder en absoluto.

En un despliegue real, eso es inaceptable: una empresa no puede permitirse que parte de sus usuarios se queden fuera el día que activa PQC en producción. Este repo demuestra la solución práctica **disponible hoy**: servir dos certificados en paralelo y dejar que el propio TLS negocie cuál usar.

## Arquitectura

Cliente (navegador) ──TLS 1.3──> openssl s_server (contenedor Docker)
├── -cert / -key → ML-DSA-65 (post-cuántico)
└── -dcert / -dkey → ECDSA P-256 (clásico, fallback)


El servidor elige automáticamente qué certificado enviar según los algoritmos de firma (`sigalgs`) que el cliente anuncia soportar en su `ClientHello`.

## Lección aprendida: `-cert2`/`-key2` vs `-dcert`/`-dkey`

Durante el desarrollo, la primera implementación usó `-cert2`/`-key2` para el certificado de fallback. **No funcionó**: el servidor seguía enviando siempre el certificado ML-DSA, incluso a clientes que solo anunciaban soporte ECDSA, resultando en `handshake failure`.

La flag correcta para combinar un certificado post-cuántico con uno tradicional es **`-dcert`/`-dkey`** — `-cert2`/`-key2` es un mecanismo distinto, ligado al uso de SNI (`-servername`), no pensado como selector genérico por tipo de algoritmo. La documentación de OpenSSL es ambigua en este punto, así que lo dejamos documentado aquí por si a alguien más le pasa lo mismo.

## Requisitos

- Docker instalado (`docker --version`)
- Cualquier navegador — ese es justo el punto de esta PoC. Tanto uno con soporte ML-KEM/ML-DSA (Chrome 131+, Firefox 132+) como uno sin él (Edge, Firefox más antiguo) deberían poder conectar.

## Uso rápido

### Probarlo con la imagen publicada
> docker pull ghcr.io/marietee12/pqc-tenis-dual-cert-poc:latest
>
> docker run -p 8443:8443 ghcr.io/marietee12/pqc-tenis-dual-cert-poc:latest

### Construirlo desde el código
> docker build -t pqc-tenis-dual-cert-poc .
>
> docker run -p 8443:8443 pqc-tenis-dual-cert-poc

Una vez arrancado, visita: **https://localhost:8443**

> ⚠️ Ambos certificados son autofirmados, tu navegador mostrará una advertencia de seguridad la primera vez. Es esperado en una PoC — acepta el riesgo para continuar.

## Verificar la negociación de certificado

Confirma que un cliente PQC-ready recibe ML-DSA-65:
> openssl s_client -connect localhost:8443 -groups X25519MLKEM768 < /dev/null | grep -i "sigalg\|Temp Key"

Confirma que un cliente restringido a algoritmos clásicos recibe ECDSA en su lugar:
> openssl s_client -connect localhost:8443 -sigalgs "ecdsa_secp256r1_sha256" -groups X25519 < /dev/null | grep -i "sigalg\|Temp Key"

## Comparativa: esta PoC vs la PoC solo-PQC

| | [pqc-tenis-poc](https://github.com/marietee12/pqc-tenis-poc) (solo-PQC) | pqc-tenis-dual-cert-poc (este repo) |
|---|---|---|
| Certificados servidos | Solo ML-DSA-65 | ML-DSA-65 + ECDSA P-256 |
| Navegador con soporte PQC | Funciona | Funciona |
| Navegador sin soporte PQC | `SSL_ERROR_NO_CYPHER_OVERLAP` — sin acceso | Funciona, cae a ECDSA automáticamente |
| Caso de uso | Demostrar el problema de compatibilidad | Demostrar la solución de transición |

### Capturas

**Chrome con soporte PQC — recibe certificado ML-DSA-65:**
![Chrome con soporte PQC](docs/screenshots/chrome-dual-pqc.png)

**Firefox sin soporte ML-DSA — cae automáticamente a certificado ECDSA:**
![Firefox con fallback ECDSA](docs/screenshots/firefox-dual-ecdsa.png)

## ¿Y un certificado híbrido (composite) en vez de dos separados?

No es viable todavía. El estándar que definiría un único certificado con ambas firmas combinadas (`draft-ietf-lamps-pq-composite-sigs`) sigue siendo un borrador del IETF, sin OIDs finales, y el propio equipo de OpenSSL ha descartado darle soporte hasta que el estándar se cierre. El único soporte que existe hoy es experimental (ej. Bouncy Castle), sin garantías de interoperabilidad entre implementaciones. Por eso esta PoC usa **dos certificados separados negociados por el servidor**, que es la alternativa estable disponible actualmente.

## Estructura del proyecto

.
├── Dockerfile # Compila OpenSSL 3.5.7 desde fuente
├── docker-compose.yml
├── entrypoint.sh # Genera certificados si no existen; arranca openssl s_server con -cert/-dcert
├── gen-cert.sh # Genera certificado ML-DSA-65 + certificado ECDSA P-256
├── www/ # Contenido servido por openssl s_server -WWW
└── README.md


## Notas de seguridad

Esta imagen es una **PoC educativa**, no está pensada para producción:
- Usa `openssl s_server`, no un servidor web de producción (nginx, Apache).
- Ambos certificados son autofirmados y sin rotación.
- No incluye autenticación ni rate limiting.

## Referencias

- [NIST FIPS 203 — ML-KEM](https://csrc.nist.gov/pubs/fips/203/final)
- [NIST FIPS 204 — ML-DSA](https://csrc.nist.gov/pubs/fips/204/final)
- [OpenSSL 3.5 Release Notes](https://openssl-library.org/news/)
- [draft-ietf-lamps-pq-composite-sigs](https://datatracker.ietf.org/doc/draft-ietf-lamps-pq-composite-sigs/)

## Autor

Mario — TFM *"Cifrado cuántico: eficacia y viabilidad"*
