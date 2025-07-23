#!/usr/local/bin/bash

# Declare associative arrays
declare -A RPC_URLS
declare -A VERIFIER_URLS
declare -A DEPLOY_SCRIPTS
declare -A VERIFIER_TYPES

# Network configurations
RPC_URLS["monad-devnet"]="https://rpc-devnet.monadinfra.com/rpc/3fe540e310bbb6ef0b9f16cd23073b0a"
RPC_URLS["edu-test"]="https://open-campus-codex-sepolia.drpc.org"
RPC_URLS["edu"]="https://rpc.edu-chain.raas.gelato.cloud"
RPC_URLS["neo-test"]="https://neoxt4seed1.ngd.network"
RPC_URLS["neo"]="https://mainnet-1.rpc.banelabs.org"
RPC_URLS["op-test"]="https://sepolia.optimism.io"
RPC_URLS["op"]="https://mainnet.optimism.io"
RPC_URLS["base-test"]="https://sepolia.base.org"
RPC_URLS["bsc-test"]="https://data-seed-prebsc-1-s1.bnbchain.org:8545"
RPC_URLS["bsc"]="https://bsc-dataseed.bnbchain.org"
RPC_URLS["ju-test"]="https://testnet-rpc.juchain.org"

# Verifier type configurations (blockscout or etherscan)
VERIFIER_TYPES["monad-devnet"]="blockscout"
VERIFIER_TYPES["edu-test"]="blockscout"
VERIFIER_TYPES["edu"]="blockscout"
VERIFIER_TYPES["neo-test"]="blockscout"
VERIFIER_TYPES["neo"]="blockscout"
VERIFIER_TYPES["op-test"]="blockscout"
VERIFIER_TYPES["op"]="blockscout"
VERIFIER_TYPES["bsc-test"]="etherscan"

# Verifier configurations
VERIFIER_URLS["monad-devnet"]="https://explorer.monad-devnet.devnet101.com/api/"
VERIFIER_URLS["edu-test"]="https://opencampus-codex.blockscout.com/api/"
VERIFIER_URLS["edu"]="https://educhain.blockscout.com/api/"
VERIFIER_URLS["neo-test"]="https://xt4scan.ngd.network:8877/api/"
VERIFIER_URLS["neo"]="https://xexplorer.neo.org/api/"
VERIFIER_URLS["op-test"]="https://optimism-sepolia.blockscout.com/api/"
VERIFIER_URLS["op"]="https://optimism.blockscout.com/api/"
VERIFIER_URLS["base-test"]="https://base-sepolia.blockscout.com/api/"
VERIFIER_URLS["bsc"]="https://api.bscscan.com/api"
VERIFIER_URLS["ju-test"]="https://testnet.juscan.io/api/"
# BSC uses Etherscan, so no verifier URL needed

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
VERIFIER_TYPE=${VERIFIER_TYPES[$NETWORK]}
SCRIPT=${DEPLOY_SCRIPTS[$CONTRACT]}

echo "Network: $NETWORK"
echo "Contract: $CONTRACT"
echo "RPC URL: $RPC_URL"
echo "Verifier Type: $VERIFIER_TYPE"
if [ "$VERIFIER_TYPE" = "blockscout" ]; then
    echo "Verifier URL: $VERIFIER_URL"
elif [ "$VERIFIER_TYPE" = "etherscan" ]; then
    echo "Using Etherscan API (key from env)"
fi
echo "Script: $SCRIPT"

forge clean

set -o allexport
source $ENV_FILE
set +o allexport

# Build forge command based on verifier type
if [ "$VERIFIER_TYPE" = "etherscan" ]; then
    # Check if ETHERSCAN_API_KEY is set
    if [ -z "$ETHERSCAN_API_KEY" ]; then
        echo "Error: ETHERSCAN_API_KEY is not set"
        echo "Please set it in your .env file or environment"
        echo "Example: ETHERSCAN_API_KEY=your_api_key_here"
        exit 1
    fi
    
    forge script \
        $SCRIPT \
        --rpc-url $RPC_URL \
        --broadcast \
        --verify \
        --verifier etherscan \
        --etherscan-api-key $ETHERSCAN_API_KEY \
        --skip-simulation \
        -vvvv
else
    # Default to blockscout
    forge script \
        $SCRIPT \
        --rpc-url $RPC_URL \
        --broadcast \
        --verify \
        --verifier blockscout \
        --verifier-url $VERIFIER_URL \
        --skip-simulation \
        -vvvv
fi
