# Infra-fh

Infrastructure for deploying [StreamingFast Firehose](https://firehose.streamingfast.io/) blockchain indexing nodes for **Ethereum** and **Arbitrum One** using Docker Compose.

Firehose provides high-performance, streaming-first access to blockchain data by instrumenting execution clients to emit rich, ordered block data.

## Supported Networks

| Network          | Execution Client       | Consensus Client      | Firehose Base               |
| ---------------- | ---------------------- | --------------------- | --------------------------- |
| Ethereum Mainnet | Geth `v1.16.8-fh3.0-2` | Lighthouse `v8.1.0`   | `firehose-ethereum:v2.15.9` |
| Arbitrum One     | Nitro `v3.9.3-fh3.0-1` | — (uses parent chain) | `firehose-ethereum:v2.15.9` |

## Project Structure

```
.
├── generate_jwt.sh                         # JWT secret generator for EL/CL communication
└── chain/
    └── execution/
        ├── eth-firehose.yml                # Docker Compose — Ethereum Firehose + Lighthouse
        ├── arbitrum-one-firehose.yml       # Docker Compose — Arbitrum One Firehose
        ├── config/
        │   ├── eth-firehose-mainnet.yaml   # Firehose config for Ethereum
        │   └── arbitrum-one-firehose.yaml  # Firehose config for Arbitrum One
        ├── ethereum-firehose/
        │   ├── Dockerfile                  # Custom Ethereum Firehose image
        │   └── build-firehose-eth.sh       # Build script
        └── arbitrum-firehose/
            ├── Dockerfile                  # Custom Arbitrum Firehose image
            └── build.sh                    # Build script
```

## Prerequisites

- **Docker** and **Docker Compose** (with overlay network support)
- **OpenSSL** (for JWT generation)
- Sufficient disk space for blockchain data (bind-mounted to `/mnt/chain/` by default)

## Getting Started

### 1. Generate a JWT Secret

A shared JWT token is required for Ethereum execution/consensus client communication:

```bash
./generate_jwt.sh
```

This creates `chain/jwttoken/jwt.hex` containing a 32-byte hex secret. The script is idempotent and will not overwrite an existing token.

### 2. Build Custom Docker Images

#### Ethereum Firehose

```bash
cd chain/execution/ethereum-firehose/
./build-firehose-eth.sh
```

Produces: `custometh/eth-firehose:v1.16.8-b`

#### Arbitrum Firehose

```bash
cd chain/execution/arbitrum-firehose/
./build.sh
```

Produces: `customarb/arbitrum-firehose:v3.9.3-g`

### 3. Configure Environment Variables

Set the following environment variables before deploying (defaults shown):

| Variable                             | Default                   | Description                            |
| ------------------------------------ | ------------------------- | -------------------------------------- |
| `PROJECT_ROOT_ETHEREUM`              | —                         | Root path for Ethereum config files    |
| `PROJECT_ROOT_ARBITRUM`              | —                         | Root path for Arbitrum config files    |
| `ETH_FIREHOSE_DATA_PATH`             | `/mnt/chain/eth-fh-data`  | Ethereum Firehose state/data           |
| `ETH_FIREHOSE_BLOCKS_DATA_PATH`      | `/mnt/chain/eth-fh`       | Ethereum merged blocks storage         |
| `ARBITRUM_FIREHOSE_DATA_PATH`        | `/mnt/chain/arb1-fh-data` | Arbitrum Firehose state/data           |
| `ARBITRUM_FIREHOSE_BLOCKS_DATA_PATH` | `/mnt/chain/arb1-fh`      | Arbitrum merged blocks storage         |
| `CHAIN_LIGHTHOUSE_DATA_PATH`         | `/mnt/chain/eth-cl`       | Lighthouse beacon data                 |
| `EXT_IP`                             | `0.0.0.0`                 | External IP for Lighthouse ENR address |

### 4. Deploy

#### Ethereum Mainnet

```bash
docker compose -f chain/execution/eth-firehose.yml up -d
```

This starts two services:

- **eth-fh** — Firehose-instrumented Geth (execution) with merger, relayer, and index-builder
- **lighthouse** — Lighthouse beacon node (consensus) with checkpoint sync via `sync-mainnet.beaconcha.in`

#### Arbitrum One

> **Note:** Arbitrum One requires a running Ethereum node as its parent chain. Make sure Ethereum is deployed first.

```bash
docker compose -f chain/execution/arbitrum-one-firehose.yml up -d
```

This starts:

- **arb1-fh** — Firehose-instrumented Nitro node connected to the parent Ethereum chain

## Architecture

### Firehose Components

Each Firehose deployment runs the following internal components:

| Component         | Purpose                                                     |
| ----------------- | ----------------------------------------------------------- |
| **reader-node**   | Instrumented blockchain client emitting Firehose block data |
| **relayer**       | Distributes blocks from reader to downstream consumers      |
| **merger**        | Merges one-block files into 100-block bundles               |
| **firehose**      | gRPC endpoint for streaming block data                      |
| **index-builder** | Builds block indexes (100,000 block size)                   |

### Networking

Services communicate over Docker overlay networks:

- `eth-chain-net` — Ethereum execution + consensus
- `arbitrum-one-chain-net` — Arbitrum Firehose
- `arbitrum-one-monitor-net` — Arbitrum monitoring

### Exposed Ports

| Service           | Port  | Protocol | Purpose                     |
| ----------------- | ----- | -------- | --------------------------- |
| Ethereum Firehose | 10015 | gRPC     | Firehose streaming endpoint |
| Lighthouse        | 15052 | HTTP     | Beacon API                  |
| Lighthouse        | 9000  | TCP/UDP  | P2P                         |
| Arbitrum Firehose | 10015 | gRPC     | Firehose streaming endpoint |
| Arbitrum Merger   | 13021 | gRPC     | Merger gRPC endpoint        |

## Operational Notes

- **Restart policy:** All services use `unless-stopped`
- **Graceful shutdown:** 300-second stop grace period for clean chain shutdown
- **Logging:** JSON file driver with 3 GB max size and 3 file rotation
- **Monitoring:** Promtail labels are configured for log aggregation
- **Sync mode:** Ethereum Geth runs in `full` sync mode
- **Rate limiting:** Firehose is configured with bucket size 50 and 1-second fill rate
- **Session limits:** Max 700 sessions per user

## Security

- JWT secrets are stored in `chain/jwttoken/` (gitignored)
- Environment files (`.env*`) are gitignored
- A `secrets/` directory is gitignored for additional sensitive configuration
