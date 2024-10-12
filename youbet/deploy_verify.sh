set -e

export RPC_URL="$1"
export VERIFIER="$2"
export BLOCK_SCOUT_URL="$3"

source .env 

VERIFIER_ARGS=""
if [ "$VERIFIER" = "blockscout" ]; then
    VERIFIER_ARGS="--verifier-url $BLOCK_SCOUT_URL/api/"
elif [ "$VERIFIER" = "etherscan" ]; then
    VERIFIER_ARGS="--etherscan-api-key $ETHERSCAN_API_KEY"
fi

forge clean 

forge script \
    script/BetDeploy.s.sol:BetScript \
    --skip-simulation \
    --rpc-url  $RPC_URL \
    --broadcast \
    --verify \
    --verifier $VERIFIER \
    $VERIFIER_ARGS \
    -vvvv