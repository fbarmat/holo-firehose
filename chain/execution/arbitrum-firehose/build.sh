#!/bin/bash
set -euo pipefail

docker build \
  --build-arg FIREHOSE_ETHEREUM=v2.15.9 \
  -t customarb/arbitrum-firehose:v3.9.3-g \
  .