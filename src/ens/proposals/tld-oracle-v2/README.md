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

## Policy

- **Rate limit:** 10 claims per rolling 7-day window (circular buffer, no boundary bursts)
- **Minimum delay:** 7 days before execution; veto open until `execute()` is called
- **Proof freshness:** 14 days max age
- **Emergency pause:** DAO Timelock or Security Council

## Verify

```bash
forge test --match-path "src/ens/proposals/tld-oracle-v2/*" --fork-url $MAINNET_RPC_URL -vv
```

5 tests: governance lifecycle, full claim lifecycle, DAO veto, Security Council veto, premature execution revert.

## Links

- Temp check draft: [temp-check-draft.md](temp-check-draft.md)
- RFC: https://discuss.ens.domains/t/rfc-a-programmable-fast-path-for-tld-assignment/21859
- Contract repo: https://github.com/steg-eth/dnssec-solutions/tree/master/TLD-oracle
- Sepolia contract: [`0x48729B7e...dAF980F`](https://sepolia.etherscan.io/address/0x48729B7e0bA736123a57c4B6A492BDAbedAF980F)
- Sepolia receipts: [`submitClaim`](https://sepolia.etherscan.io/tx/0xe76d7ded41fd286cbfded251bebcf2ca8c5db1e18e5baccd15d701a82323e785) | [`execute`](https://sepolia.etherscan.io/tx/0x99998721d5e108f11c8e695e0543e5c2473f09d2fe6a04005dd51e4d329e9ec9)
- Mainnet deployment: TBD (pre-deployed via EOA, verified on Etherscan before vote)

> **Note:** `contracts/` contains a snapshot of TLDMinter v2.0.0 sources pinned at the time of this proposal. Canonical source: [steg-eth/dnssec-solutions](https://github.com/steg-eth/dnssec-solutions/tree/master/TLD-oracle).
