# youbet

You Bet! We can pay for everything in flow.

## Deploy Script

Contract Deploy: `./deploy_verify.sh <RPC_URL> <VERIFIER> [BLOCK_SCOUT_URL]`

Contract Upgrade: `./upgrade_verify.sh <RPC_URL> <PROXY_ADDRESS> <VERIFIER> [BLOCK_SCOUT_URL]`

Deploy Example:

```bash
// deploy and verify by etherscan
./deploy_verify.sh https://rpc.xxx etherscan

// deploy and verify by blockscout
./deploy_verify.sh https://rpc.xxx blockscout https://blockscout.xxx
```

Upgrade Example:

```bash
// upgrade and verify by etherscan
./upgrade_verify.sh  https://rpc.xxx  0x4A91xxxx etherscan

// upgrade and verify by etherscan
./upgrade_verify.sh  https://rpc.xxx  0x4A91xxxx blockscout https://blockscout.xxx
```
