ARG FIREHOSE_ETHEREUM=v2.15.9

FROM ghcr.io/streamingfast/nitro:v3.9.3-fh3.0-1 AS nitro
FROM ghcr.io/streamingfast/firehose-ethereum:${FIREHOSE_ETHEREUM}

COPY --from=nitro /usr/local/bin/nitro /usr/local/bin/nitro