# dao-proposals

Governance proposal calldata and verification tests for ENS DAO proposals by estmcmxci.eth.

## Verify a proposal

```bash
cp .env.example .env
# Add your MAINNET_RPC_URL
forge test --match-path "src/ens/proposals/<proposal-name>/*" -vv
```

## Proposals

| Proposal | Status | Forum |
|----------|--------|-------|
| [tld-oracle-v2](src/ens/proposals/tld-oracle-v2/) | Draft | [RFC](https://discuss.ens.domains/t/rfc-a-programmable-fast-path-for-tld-assignment/21859) |
