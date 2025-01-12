#!/usr/local/bin/bash

# Declare associative arrays
declare -A RPC_URLS
declare -A VERIFIER_URLS
declare -A DEPLOY_SCRIPTS

# Network configurations
RPC_URLS["monad-devnet"]="https://rpc-devnet.monadinfra.com/rpc/3fe540e310bbb6ef0b9f16cd23073b0a"
RPC_URLS["edu-test"]="https://rpc.open-campus-codex.gelato.digital"
RPC_URLS["neo-test"]="https://neoxt4seed1.ngd.network"
RPC_URLS["neo"]="https://mainnet-1.rpc.banelabs.org"
RPC_URLS["op-test"]="https://sepolia.optimism.io"
RPC_URLS["op"]="https://mainnet.optimism.io"

# Verifier configurations
VERIFIER_URLS["monad-devnet"]="https://explorer.monad-devnet.devnet101.com/api/"
VERIFIER_URLS["edu-test"]="https://opencampus-codex.blockscout.com/api/"
VERIFIER_URLS["neo-test"]="https://xt4scan.ngd.network:8877/api/"
VERIFIER_URLS["neo"]="https://xexplorer.neo.org/api/"
VERIFIER_URLS["op-test"]="https://optimism-sepolia.blockscout.com/api/"
VERIFIER_URLS["op"]="https://optimism.blockscout.com/api/"

# Script configurations
DEPLOY_SCRIPTS["bet"]="script/BetDeploy.s.sol:BetScript"
DEPLOY_SCRIPTS["distributor"]="script/DistributorDeploy.s.sol:DistributorScript"

# env is optional, default is .env
if [ $# -ne 2 ] && [ $# -ne 3 ]; then
    echo "Usage: ./deploy_verify.sh <network> <contract> <env>"
    echo "Networks: ${!RPC_URLS[@]}"
    echo "Contracts: ${!DEPLOY_SCRIPTS[@]}"
    exit 1
fi

NETWORK=$1
CONTRACT=$2
ENV_FILE=${3:-.env}

# Validate network
if [ -z "${RPC_URLS[$NETWORK]}" ]; then
    echo "Invalid network. Choose from: ${!RPC_URLS[@]}"
    exit 1
fi

# Validate contract
if [ -z "${DEPLOY_SCRIPTS[$CONTRACT]}" ]; then
    echo "Invalid contract. Choose from: ${!DEPLOY_SCRIPTS[@]}"
    exit 1
fi

RPC_URL=${RPC_URLS[$NETWORK]}
VERIFIER_URL=${VERIFIER_URLS[$NETWORK]}
SCRIPT=${DEPLOY_SCRIPTS[$CONTRACT]}

echo "Network: $NETWORK"
echo "Contract: $CONTRACT"
echo "RPC URL: $RPC_URL"
echo "Verifier URL: $VERIFIER_URL"
echo "Script: $SCRIPT"

forge clean

set -o allexport
source $ENV_FILE
set +o allexport

forge script \
    $SCRIPT \
    --rpc-url $RPC_URL \
    --broadcast \
    --verify \
    --verifier blockscout \
    --verifier-url $VERIFIER_URL \
    --skip-simulation \
    -vvvv
