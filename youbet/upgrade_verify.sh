set -e

export RPC_URL="$1"
export PROXY_ADDRESS="$2"
export VERIFIER="$3"
export BLOCK_SCOUT_URL="$4"

source .env 

VERIFIER_ARGS=""
if [ "$VERIFIER" = "blockscout" ]; then
    VERIFIER_ARGS="--verifier-url $BLOCK_SCOUT_URL/api/"
elif [ "$VERIFIER" = "etherscan" ]; then
    VERIFIER_ARGS="--etherscan-api-key $ETHERSCAN_API_KEY"
fi

forge clean 

forge script \
    script/BetUpgrade.s.sol:BetScript \
    --rpc-url  $RPC_URL \
    --skip-simulation \
    --broadcast \
    --verify \
    --verifier $VERIFIER \
    $VERIFIER_ARGS \
    -vvvv