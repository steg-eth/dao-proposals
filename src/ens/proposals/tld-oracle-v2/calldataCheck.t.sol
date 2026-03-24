// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "forge-std/StdJson.sol";

interface ITLDMinter {
    function batchAddToAllowlist(string[] calldata tlds) external;
    function allowedTLDs(bytes32 labelHash) external view returns (bool);
    function version() external pure returns (string memory);
}

interface IRoot {
    function setController(address controller, bool enabled) external;
    function controllers(address controller) external view returns (bool);
}

interface ITLDMinterFactory {
    // Used to deploy TLDMinter in setUp before mainnet address is known
}

/**
 * @title TLDOracleV2CalldataCheck
 * @notice Verifies the TLD Oracle v2 governance proposal executes the expected outcome.
 *
 * Simulates the DAO timelock executing two calls atomically:
 *   1. root.setController(address(tldMinter), true)
 *   2. tldMinter.batchAddToAllowlist(tlds) — 1,166 post-2012 ICANN gTLDs
 *
 * To verify locally:
 *   Clone: git clone https://github.com/estmcmxci/dao-proposals.git
 *   Checkout: git checkout <commit>
 *   Run: forge test --match-path "src/ens/proposals/tld-oracle-v2/*" -vv
 */
contract TLDOracleV2CalldataCheck is Test {
    using stdJson for string;

    // ─────────────────────────────────────────────────────────────────
    // Mainnet Addresses
    // ─────────────────────────────────────────────────────────────────

    address constant ROOT         = 0xaB528d626EC275E3faD363fF1393A41F581c5897;
    address constant DNSSEC_IMPL  = 0x0fc3152971714E5ed7723FAFa650F86A4BaF30C5;
    address constant ENS_REGISTRY = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    address constant DAO_TIMELOCK = 0xFe89cc7aBB2C4183683ab71653C4cdc9B02D44b7;
    address constant SC_MULTISIG  = 0xaA5cD05f6B62C3af58AE9c4F3F7A2aCC2Cdc2Cc7;
    address constant SC_CONTRACT  = 0xB8fA0cE3f91F41C5292D07475b445c35ddF63eE0;

    // ─────────────────────────────────────────────────────────────────
    // State
    // ─────────────────────────────────────────────────────────────────

    ITLDMinter tldMinter;

    // ─────────────────────────────────────────────────────────────────
    // Setup
    // ─────────────────────────────────────────────────────────────────

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        // Deploy TLDMinter with mainnet constructor args
        // Replace with deployed address once live on mainnet:
        //   tldMinter = ITLDMinter(<mainnetAddress>);
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("TLDMinter.sol:TLDMinter"),
            abi.encode(
                DNSSEC_IMPL,
                ROOT,
                ENS_REGISTRY,
                DAO_TIMELOCK,
                SC_MULTISIG,
                SC_CONTRACT,
                uint256(7 days),
                uint256(10),
                uint256(7 days),
                uint256(14 days)
            )
        );
        address deployed;
        assembly { deployed := create(0, add(bytecode, 0x20), mload(bytecode)) }
        tldMinter = ITLDMinter(deployed);
    }

    // ─────────────────────────────────────────────────────────────────
    // Test
    // ─────────────────────────────────────────────────────────────────

    function test_proposalExecutesExpectedOutcome() public {
        string[] memory tlds = _loadAllowlist();

        vm.startPrank(DAO_TIMELOCK);

        // Call 1: authorize TLDMinter as Root controller
        IRoot(ROOT).setController(address(tldMinter), true);

        // Call 2: seed allowlist
        tldMinter.batchAddToAllowlist(tlds);

        vm.stopPrank();

        // ── Assertions ──────────────────────────────────────────────

        // Root controller set
        assertTrue(IRoot(ROOT).controllers(address(tldMinter)), "TLDMinter not registered as Root controller");

        // Spot-check known valid post-2012 gTLDs are allowlisted
        string[7] memory knownValid = ["link", "click", "help", "gift", "property", "sexy", "hiphop"];
        for (uint256 i = 0; i < knownValid.length; i++) {
            assertTrue(
                tldMinter.allowedTLDs(keccak256(abi.encodePacked(knownValid[i]))),
                string.concat(knownValid[i], " should be allowlisted")
            );
        }

        // Spot-check pre-2012 gTLDs are NOT allowlisted
        string[5] memory excluded = ["com", "net", "org", "info", "biz"];
        for (uint256 i = 0; i < excluded.length; i++) {
            assertFalse(
                tldMinter.allowedTLDs(keccak256(abi.encodePacked(excluded[i]))),
                string.concat(excluded[i], " should NOT be allowlisted")
            );
        }

        // Version check
        assertEq(tldMinter.version(), "2.0.0", "Unexpected contract version");

        // Allowlist count sanity check (1,166 TLDs)
        assertEq(tlds.length, 1166, "Allowlist should contain exactly 1,166 TLDs");
    }

    // ─────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────

    function _loadAllowlist() internal view returns (string[] memory) {
        string memory json = vm.readFile("src/ens/proposals/tld-oracle-v2/allowlist.json");
        bytes memory raw = json.parseRaw(".tlds");
        return abi.decode(raw, (string[]));
    }
}
