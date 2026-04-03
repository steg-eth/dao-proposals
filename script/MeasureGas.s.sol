// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

interface ITLDMinter {
    function batchAddToAllowlist(string[] calldata tlds) external;
    function version() external pure returns (string memory);
}

interface IRoot {
    function setController(address controller, bool enabled) external;
}

contract MeasureGas is Script {
    using stdJson for string;

    address constant ROOT          = 0xaB528d626EC275E3faD363fF1393A41F581c5897;
    address constant DNSSEC_IMPL   = 0x0fc3152971714E5ed7723FAFa650F86A4BaF30C5;
    address constant ENS_REGISTRY  = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    address constant DAO_TIMELOCK  = 0xFe89cc7aBB2C4183683ab71653C4cdc9B02D44b7;
    address constant SC_MULTISIG   = 0xaA5cD05f6B62C3af58AE9c4F3F7A2aCC2Cdc2Cc7;
    address constant SC_CONTRACT   = 0xB8fA0cE3f91F41C5292D07475b445c35ddF63eE0;
    address constant FACTORY       = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    bytes32 constant SALT = bytes32(0);

    function run() public {
        // Pre-deploy TLDMinter (simulates EOA deployment before the vote)
        bytes memory initCode = abi.encodePacked(
            vm.getCode("TLDMinter.sol:TLDMinter"),
            abi.encode(
                DNSSEC_IMPL, ROOT, ENS_REGISTRY, DAO_TIMELOCK,
                SC_MULTISIG, SC_CONTRACT,
                uint256(7 days), uint256(10), uint256(7 days), uint256(14 days)
            )
        );

        // Deploy via CREATE2 just to get a concrete address for gas measurement
        (bool ok,) = FACTORY.call(abi.encodePacked(SALT, initCode));
        require(ok, "pre-deploy failed");
        address minter = vm.computeCreate2Address(SALT, keccak256(initCode), FACTORY);
        console.log("TLDMinter address:", minter);
        console.log("");

        // Load batch files
        string[4] memory batchFiles = [
            "src/ens/proposals/tld-oracle/allowlist-batch-1.json",
            "src/ens/proposals/tld-oracle/allowlist-batch-2.json",
            "src/ens/proposals/tld-oracle/allowlist-batch-3.json",
            "src/ens/proposals/tld-oracle/allowlist-batch-4.json"
        ];

        // ── Measure proposal gas (5 calls, executed by DAO timelock) ──
        vm.startPrank(DAO_TIMELOCK);

        // Call 1: setController
        uint256 g1 = gasleft();
        IRoot(ROOT).setController(minter, true);
        uint256 controllerGas = g1 - gasleft();

        // Calls 2-5: batchAddToAllowlist (4 batches)
        uint256 totalBatchGas = 0;
        for (uint256 i = 0; i < 4; i++) {
            string memory json = vm.readFile(batchFiles[i]);
            bytes memory raw = json.parseRaw(".tlds");
            string[] memory batch = abi.decode(raw, (string[]));

            uint256 gN = gasleft();
            ITLDMinter(minter).batchAddToAllowlist(batch);
            uint256 batchGas = gN - gasleft();
            totalBatchGas += batchGas;

            console.log("Batch %d: %d TLDs, %d gas", i + 1, batch.length, batchGas);
        }

        vm.stopPrank();

        uint256 totalGas = controllerGas + totalBatchGas;
        uint256 gasLimit = block.gaslimit;
        uint256 buffer = 2_000_000;

        console.log("");
        console.log("=== GAS BREAKDOWN ===");
        console.log("Call 1 (setController):", controllerGas);
        console.log("Calls 2-5 (batches 1-4):", totalBatchGas);
        console.log("");
        console.log("Proposal total (5 calls):", totalGas);
        console.log("Block gas limit:", gasLimit);
        console.log("");

        if (totalGas > gasLimit - buffer) {
            console.log("WARNING: Proposal exceeds block gas limit minus 2M buffer");
        } else {
            console.log("OK: Proposal fits within block gas limit");
            console.log("  Headroom:", gasLimit - totalGas, "gas");
        }
    }
}
