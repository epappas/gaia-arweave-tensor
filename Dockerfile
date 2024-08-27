FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y erlang \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    wget \
    libssl-dev \
    libgmp-dev \
    libsqlite3-dev \
    make \
    cmake \
    gcc \
    g++ \
    git \
    screen \
    pkg-config \
    jq \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    python3-dev

WORKDIR /app/arweave

ADD . /app/arweave

RUN ./rebar3 as prod release

RUN ./testnet/assert_testnet.sh && \
  ./testnet/rebuild_testnet.sh

# CMD ./testnet/start_testnet.sh

EXPOSE 1984

ENTRYPOINT [ "./scripts/entrypoint.sh" ]