// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

interface ITLDMinter {
    function batchAddToAllowlist(string[] calldata tlds) external;
}

interface IRoot {
    function setController(address controller, bool enabled) external;
}

contract EncodeCalldata is Script {
    using stdJson for string;

    address constant ROOT = 0xaB528d626EC275E3faD363fF1393A41F581c5897;

    function run() public view {
        // TLDMinter is pre-deployed via EOA — set this to the deployed address
        address minter = vm.envAddress("TLDMINTER_ADDRESS");

        // Call 1: setController
        bytes memory call1 = abi.encodeWithSelector(
            IRoot.setController.selector, minter, true
        );

        // Load batches and encode Calls 2-5
        string[4] memory batchFiles = [
            "src/ens/proposals/tld-oracle-v2/allowlist-batch-1.json",
            "src/ens/proposals/tld-oracle-v2/allowlist-batch-2.json",
            "src/ens/proposals/tld-oracle-v2/allowlist-batch-3.json",
            "src/ens/proposals/tld-oracle-v2/allowlist-batch-4.json"
        ];

        console.log("=== ENCODED CALLDATA (single proposal, 5 calls) ===");
        console.log("");
        console.log("TLDMinter address:", minter);
        console.log("");

        console.log("--- Call 1: setController ---");
        console.log("target:", ROOT);
        console.log("calldata length:", call1.length);
        console.log("calldata:");
        console.logBytes(call1);
        console.log("");

        for (uint256 i = 0; i < 4; i++) {
            string memory json = vm.readFile(batchFiles[i]);
            bytes memory raw = json.parseRaw(".tlds");
            string[] memory batch = abi.decode(raw, (string[]));

            bytes memory callN = abi.encodeWithSelector(
                ITLDMinter.batchAddToAllowlist.selector, batch
            );

            console.log("--- Call", i + 2, ": batchAddToAllowlist ---");
            console.log("target:", minter);
            console.log("batch size:", batch.length);
            console.log("calldata length:", callN.length);
            console.log("calldata:");
            console.logBytes(callN);
            console.log("");
        }
    }
}
