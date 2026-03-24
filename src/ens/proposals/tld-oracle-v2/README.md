# TLD Oracle v2

Authorizes TLDMinter as an ENS Root controller and seeds the initial 1,166-entry gTLD allowlist.

## Proposal

Two calls, executed atomically through the DAO timelock:

1. `root.setController(address(tldMinter), true)`
2. `tldMinter.batchAddToAllowlist(string[] tlds)` — 1,166 post-2012 ICANN gTLDs

## Verify

```bash
forge test --match-path "src/ens/proposals/tld-oracle-v2/*" -vv
```

## Links

- RFC: https://discuss.ens.domains/t/rfc-a-programmable-fast-path-for-tld-assignment/21859
- Contract repo: https://github.com/eurekaetcetera/dnssec-solutions/tree/master/TLD-oracle
- Sepolia deployment: `0x48729B7e0bA736123a57c4B6A492BDAbedAF980F`
- Mainnet deployment: TBD
