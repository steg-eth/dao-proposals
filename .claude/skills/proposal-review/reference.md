# Review Reference

Shared reference data for all proposal calldata reviews.

## ENS Key Addresses

| Contract | Address |
|----------|---------|
| ENS Token | `0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72` |
| ENS Governor | `0x323A76393544d5ecca80cd6ef2A560C6a395b7E3` |
| ENS Timelock (wallet.ensdao.eth) | `0xFe89cc7aBB2C4183683ab71653C4cdc9B02D44b7` |
| ENS Root | `0xaB528d626EC275E3faD363fF1393A41F581c5897` |
| ENS Registry | `0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e` |
| DNSSEC Oracle | `0x0fc3152971714E5ed7723FAFa650F86A4BaF30C5` |
| Security Council Multisig | `0xaA5cD05f6B62C3af58AE9c4F3F7A2aCC2Cdc2Cc7` |
| Security Council Contract | `0xB8fA0cE3f91F41C5292D07475b445c35ddF63eE0` |

For the full list, see `src/ens/Constants.sol` (ENSConstants library).

For other DAOs, see `src/dao-registry.json`.

## Available Helpers

Currently no helpers are defined for ENS. For proposals involving Safe transactions, Zodiac Roles, or MultiSend batching, add helpers to `src/ens/helpers/` following the Blockful pattern (see `blockful/dao-proposals` for reference implementations).

## Decimal Reference

| Token | Decimals | Example |
|-------|----------|---------|
| USDC | 6 | `900_000 * 10**6` = 900K USDC |
| USDT | 6 | `100_000 * 10**6` = 100K USDT |
| ETH/WETH | 18 | `1 ether` = 1 ETH |
| ENS | 18 | `100_000 * 10**18` = 100K ENS |

## Common Function Selectors

Always derive from interfaces: `IERC20.transfer.selector`, `IWETH.deposit.selector`, etc. Never hardcode hex bytes4 values.

| Selector | Function |
|----------|----------|
| `0xa9059cbb` | `transfer(address,uint256)` |
| `0x095ea7b3` | `approve(address,uint256)` |
| `0x23b872dd` | `transferFrom(address,address,uint256)` |
| `0xe0dba60f` | `setController(address,bool)` |
| `0x0aa626c3` | `batchAddToAllowlist(string[])` |
