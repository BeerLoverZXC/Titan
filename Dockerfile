FROM ubuntu:latest

RUN apt-get update && apt-get upgrade -y
RUN apt-get install time curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

ENV HOME=/app

WORKDIR /app

ENV MONIKER="StakeShark"
ENV CHAIN_ID="titan-test-3"
ENV GO_VER="1.22.3"
ENV WALLET="wallet"
ENV PATH="/usr/local/go/bin:/app/go/bin:${PATH}"
ENV SEEDS="bb075c8cc4b7032d506008b68d4192298a09aeea@47.76.107.159:26656"
ENV PEERS="ac90c7d177a2aa738fe80742ea2d7cf0514dbce2@titan.peer.t.stavr.tech:10126"


RUN wget "https://golang.org/dl/go$GO_VER.linux-amd64.tar.gz" && \
tar -C /usr/local -xzf "go$GO_VER.linux-amd64.tar.gz" && \
rm "go$GO_VER.linux-amd64.tar.gz" && \
mkdir -p go/bin

RUN git clone https://github.com/Titannet-dao/titan-chain.git && \
cd titan-chain && \
git fetch origin && \
make install

RUN titand init StakeShark --chain-id titan-test-3

RUN sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0025uttnt\"/;" $HOME/.titan/config/app.toml && \
sed -i.bak -e "s/^external_address *=.*/external_address = \"$(wget -qO- eth0.me):26656\"/" $HOME/.titan/config/config.toml && \
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.titan/config/config.toml && \
sed -i.bak -e "s/^seeds =.*/seeds = \"$SEEDS\"/" $HOME/.titan/config/config.toml && \
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 40/g' $HOME/.titan/config/config.toml && \
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 10/g' $HOME/.titan/config/config.toml && \
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.titan/config/app.toml && \
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"1000\"/" $HOME/.titan/config/app.toml && \
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.titan/config/app.toml && \
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.titan/config/config.toml && \
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.titan/config/config.toml

RUN wget -O $HOME/.titan/config/addrbook.json https://raw.githubusercontent.com/Titannet-dao/titan-chain/main/addrbook/addrbook.json && \
wget -O $HOME/.titan/config/genesis.json https://raw.githubusercontent.com/Titannet-dao/titan-chain/main/genesis/genesis.json


RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
    echo 'sleep 10000' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
