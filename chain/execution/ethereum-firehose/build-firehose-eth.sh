#!/bin/bash
set -euo pipefail

docker build \
  --build-arg FIREHOSE_ETHEREUM=v2.15.9 \
  --build-arg FIREHOSE_GETH_VERSION=v1.16.8-fh3.0-2 \
  -t custometh/eth-firehose:v1.16.8-b \
  .