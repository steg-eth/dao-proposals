# TLD Oracle v2 — Gas Breakdown

Measured against mainnet fork via `MeasureGas.s.sol` (2026-04-03).

| Call | Target | Action | Gas |
|------|--------|--------|----:|
| 1 | Root | `setController(tldMinter, true)` | 27,809 |
| 2 | TLDMinter | `batchAddToAllowlist(TLDs 1-300)` | 7,473,523 |
| 3 | TLDMinter | `batchAddToAllowlist(TLDs 301-600)` | 7,484,020 |
| 4 | TLDMinter | `batchAddToAllowlist(TLDs 601-900)` | 7,494,509 |
| 5 | TLDMinter | `batchAddToAllowlist(TLDs 901-1,166)` | 6,653,469 |
| | | **Total** | **29,133,330** |
| | | Block gas limit | 60,000,000 |
| | | **Headroom** | **~51%** |

Single proposal, 5 calls. TLDMinter is pre-deployed via EOA before the vote.

## Reproduce

```bash
git clone https://github.com/steg-eth/dao-proposals.git
cd dao-proposals
cp .env.example .env && echo "MAINNET_RPC_URL=https://eth.drpc.org" >> .env
forge script script/MeasureGas.s.sol --fork-url $MAINNET_RPC_URL
```
