FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
ENV OPENSSL_VERSION=3.5.7

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential zlib1g-dev perl wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src
RUN wget -q https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
    && tar xzf openssl-${OPENSSL_VERSION}.tar.gz

WORKDIR /usr/src/openssl-${OPENSSL_VERSION}
RUN ./Configure --prefix=/opt/openssl35 --openssldir=/opt/openssl35/ssl shared zlib \
    && make -j"$(nproc)" \
    && make install_sw install_ssldirs

ENV PATH="/opt/openssl35/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/openssl35/lib64:/opt/openssl35/lib"

WORKDIR /pqc-lab
COPY gen-cert.sh entrypoint.sh ./
COPY www ./www
RUN chmod +x gen-cert.sh entrypoint.sh

EXPOSE 8443
ENTRYPOINT ["/pqc-lab/entrypoint.sh"]
