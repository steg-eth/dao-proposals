// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25 <0.9.0;

/// @title ENS Governance Constants
/// @notice Shared mainnet addresses used across ENS proposal tests and scripts.
library ENSConstants {
    // Governance
    address constant GOVERNOR    = 0x323A76393544d5ecca80cd6ef2A560C6a395b7E3;
    address constant TIMELOCK    = 0xFe89cc7aBB2C4183683ab71653C4cdc9B02D44b7;
    address constant ENS_TOKEN   = 0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72;

    // ENS Core
    address constant ROOT        = 0xaB528d626EC275E3faD363fF1393A41F581c5897;
    address constant REGISTRY    = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    address constant DNSSEC_IMPL = 0x0fc3152971714E5ed7723FAFa650F86A4BaF30C5;

    // Security Council
    address constant SC_MULTISIG = 0xaA5cD05f6B62C3af58AE9c4F3F7A2aCC2Cdc2Cc7;
    address constant SC_CONTRACT = 0xB8fA0cE3f91F41C5292D07475b445c35ddF63eE0;
}
