## example

```
sui client call \
  --package 0x9ceadc5c4ea0993abe9d5864adcdb0436a45638ea6513fb9ed1fb5cfbfd97d39 \
  --module distributor \
  --function create_red_packet \
  --args \
    0x24740815b1ecaf209bedeaae944767bf45edf3bf87de2ae6ade07220edefecb9 \
    "test-uuid" \
    '["github-user1","github-user2"]' \
    '[10,10]' \
    0xd699d8f89cfda92ad67fe48cfad256ecff2b5e03a7590f237df16d697e4c7091 \
  --gas-budget 2000000
```
