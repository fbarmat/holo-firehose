ARG FIREHOSE_ETHEREUM=v2.15.9
FROM ghcr.io/streamingfast/firehose-ethereum:${FIREHOSE_ETHEREUM}

ARG FIREHOSE_GETH_VERSION=v1.16.8-fh3.0-2

# Download & install the FH-instrumented geth as /usr/local/bin/arbitrum
RUN curl -fsSL \
  https://github.com/streamingfast/go-ethereum/releases/download/geth-${FIREHOSE_GETH_VERSION}/geth_linux \
  -o /usr/local/bin/geth \
  && chmod +x /usr/local/bin/geth

RUN /usr/local/bin/geth version