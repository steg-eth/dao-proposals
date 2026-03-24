# TLD Oracle v2

Authorizes TLDMinter as an ENS Root controller and seeds the initial 1,166-entry gTLD allowlist.

## Proposal

Two proposals, executed through the DAO timelock. A single `batchAddToAllowlist` with all 1,166 TLDs exceeds the 30M block gas limit, so the allowlist is split across batches.

### Proposal A (5 calls, ~24.2M gas)

1. CREATE2 factory → deploy TLDMinter at `0xf096afBc6ebD704Dbd215999045A3FE29C064b6b`
2. Root → `setController(tldMinter, true)`
3. TLDMinter → `batchAddToAllowlist(TLDs 1–300)`
4. TLDMinter → `batchAddToAllowlist(TLDs 301–600)`
5. TLDMinter → `batchAddToAllowlist(TLDs 601–900)`

### Proposal B (1 call, ~6.5M gas, submitted after Proposal A executes)

1. TLDMinter → `batchAddToAllowlist(TLDs 901–1166)`

## Verify

```bash
forge test --match-path "src/ens/proposals/tld-oracle-v2/*" --fork-url $MAINNET_RPC_URL -vv
```

## Links

- RFC: https://discuss.ens.domains/t/rfc-a-programmable-fast-path-for-tld-assignment/21859
- Contract repo: https://github.com/eurekaetcetera/dnssec-solutions/tree/master/TLD-oracle
- Sepolia deployment: `0x48729B7e0bA736123a57c4B6A492BDAbedAF980F`
- Mainnet deployment: `0xf096afBc6ebD704Dbd215999045A3FE29C064b6b` (pending Proposal A execution — deterministic via CREATE2, salt `bytes32(0)`)

> **Note:** `contracts/` contains a snapshot of TLDMinter v2.0.0 sources pinned at the time of this proposal. Canonical source: [eurekaetcetera/dnssec-solutions](https://github.com/eurekaetcetera/dnssec-solutions/tree/master/TLD-oracle).
