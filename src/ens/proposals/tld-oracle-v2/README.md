# TLD Oracle v2

Authorizes TLDMinter as an ENS Root controller and seeds the initial 1,166-entry gTLD allowlist.

## Proposal

TLDMinter is deployed via EOA before the governance vote, verified on Etherscan. This follows the standard ENS proposal pattern (see RATIONALE.md § "Deployment pattern").

Single proposal, executed through the DAO timelock (5 calls, ~29.1M gas). Ethereum's current block gas limit is 60M, providing ~51% headroom.

1. Root → `setController(tldMinter, true)`
2. TLDMinter → `batchAddToAllowlist(TLDs 1–300)`
3. TLDMinter → `batchAddToAllowlist(TLDs 301–600)`
4. TLDMinter → `batchAddToAllowlist(TLDs 601–900)`
5. TLDMinter → `batchAddToAllowlist(TLDs 901–1166)`

## Verify

```bash
forge test --match-path "src/ens/proposals/tld-oracle-v2/*" --fork-url $MAINNET_RPC_URL -vv
```

## Links

- RFC: https://discuss.ens.domains/t/rfc-a-programmable-fast-path-for-tld-assignment/21859
- Contract repo: https://github.com/steg-eth/dnssec-solutions/tree/master/TLD-oracle
- Sepolia deployment: `0x48729B7e0bA736123a57c4B6A492BDAbedAF980F`
- Mainnet deployment: TBD (pre-deployed via EOA, verified on Etherscan before vote)

> **Note:** `contracts/` contains a snapshot of TLDMinter v2.0.0 sources pinned at the time of this proposal. Canonical source: [eurekaetcetera/dnssec-solutions](https://github.com/eurekaetcetera/dnssec-solutions/tree/master/TLD-oracle).
