#!/bin/bash

# Network configurations
RPC_URLS["edu-test"]="https://rpc.open-campus-codex.gelato.digital"
RPC_URLS["op-test"]="https://sepolia.optimism.io"
RPC_URLS["op"]="https://mainnet.optimism.io"

# Verifier configurations
VERIFIER_URLS["edu-test"]="https://opencampus-codex.blockscout.com/api/"
VERIFIER_URLS["op-test"]="https://optimism-sepolia.blockscout.com/api/"
VERIFIER_URLS["op"]="https://optimism.blockscout.com/api/"

# Script configurations
DEPLOY_SCRIPTS["bet"]="script/BetDeploy.s.sol:BetScript"
DEPLOY_SCRIPTS["distributor"]="script/DistributorDeploy.s.sol:DistributorScript"

# env is optional, default is .env
if [ $# -ne 2 ] && [ $# -ne 3 ]; then
    echo "Usage: ./deploy_verify.sh <network> <contract> <env>"
    echo "Networks: edu-test, op-test, op"
    echo "Contracts: bet, distributor"
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
