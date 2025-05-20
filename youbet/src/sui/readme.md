## example

```
sui client call \
  --package 0x1e072cf08d86d2572133f3141969b8dfb538744cf1c382ea4fc96a807a9347ab \
  --module distributor \
  --function create_red_packet \
  --args \
    0x15105000a9eb3d99c2df9185820ee479f6cd229999d9713da99cf2b50bb3d3aa \
    "test-uuid" \
    '["github-user1","github-user2"]' \
    '[1000000,2000000]' \
    0xd954c70f653fc02a8d696ef468f8d157779400de667623274e976a9ecea67f67 \
  --gas-budget 200000000 \
  --gas 0x7ee2594cdd0f644fd92f4f6b0d5e34d3c3f3a30e451eab186a1d1e60c85ad39f

```
