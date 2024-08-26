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
    git

WORKDIR /app/arweave

ADD ./apps /app/arweave/apps
ADD ./bin /app/arweave/bin
ADD ./config /app/arweave/config
ADD ./data /app/arweave/data
ADD ./scripts /app/arweave/scripts
ADD ./testnet /app/arweave/testnet
ADD ./ar_config.json /app/arweave/ar_config.json
ADD ./ar-rebar3 /app/arweave/ar-rebar3
ADD ./arweave-server /app/arweave/arweave-server
ADD ./erlang_ls.config /app/arweave/erlang_ls.config
ADD ./rebar.config /app/arweave/rebar.config
ADD ./rebar.lock /app/arweave/rebar.lock
ADD ./rebar3 /app/arweave/rebar3

RUN ./rebar3 as prod release

RUN ./testnet/assert_testnet.sh && \
  ./testnet/rebuild_testnet.sh

# CMD ./testnet/start_testnet.sh

EXPOSE 1984

ENTRYPOINT [ "./bin/start", "config_file", "./ar_config.json" ]