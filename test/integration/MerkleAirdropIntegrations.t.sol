// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Import necessary contracts and libraries
import { Test, console } from "forge-std/Test.sol";
import { MerkleAirdrop } from "../../src/MerkleAirdrop.sol";
import { ChristmasToken } from "../../src/ChristmasToken.sol";
import { ZkSyncChainChecker } from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import { DeployMerkleAirdrop } from "script/DeployMerkleAirdrop.s.sol";

contract MerkleAirDropIntegrationsTest is ZkSyncChainChecker, Test {
    // Declare state variables for the contracts we'll be testing
    MerkleAirdrop public airdrop;
    ChristmasToken public token;

    // Define constants used in the test
    // This is the Merkle root generated from the merkle tree (from output.json)
    bytes32 public constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    // Amount each address can claim (25 tokens with 18 decimals)
    uint256 public constant AMOUNT_TO_CLAIM = 25e18;
    // Total amount to send to the airdrop contract (4 addresses * 25 tokens)
    uint256 public constant AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;
    // First proof hash from the merkle proof array (from output.json)
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    // Second proof hash from the merkle proof array (from output.json)
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    // Array containing the proof hashes needed to verify the claim
    bytes32[] public PROOF = [proofOne, proofTwo];

    address public gasPayer;

    // Variables to store the test user's address and private key
    address user;
    uint256 userPrivateKey;

    // Setup function that runs before each test
    function setUp() public {
        // if not zksync, then deploy with deployment script, if we are on ZkSync, continue
        if (!isZkSyncChain()) {
            // create new instance of the deployment contract script
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            // save the airdrop and token contracts & addresses that the deployment script `run` function returns
            (airdrop, token) = deployer.run();
        } else {
            // Deploy a new ChristmasToken contract
            token = new ChristmasToken();
            // Deploy a new MerkleAirdrop contract with the merkle root and token address
            airdrop = new MerkleAirdrop(ROOT, token);
            // Mint tokens to the token contract owner (this test contract)
            token.mint(token.owner(), AMOUNT_TO_SEND);
            // Transfer tokens to the airdrop contract for distribution
            token.transfer(address(airdrop), AMOUNT_TO_SEND);
        }
        // Create a test user address and private key using Forge's makeAddrAndKey cheatcode
        (user, userPrivateKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    // Test function to verify users can claim their tokens
    function testUsersCanClaimIntegrations() public {
        // Get the user's initial token balance
        uint256 startingBalance = token.balanceOf(user);

        bytes32 digest = airdrop.getMessageHash(user, AMOUNT_TO_CLAIM);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        vm.prank(gasPayer);
        // Attempt to claim tokens with the user's address, amount, and merkle proof
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        // Get the user's final token balance
        uint256 endingBalance = token.balanceOf(user);
        // Log the ending balance for debugging
        console.log("Ending Balance:", endingBalance);

        // Verify the user received the correct amount of tokens
        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM);
    }
}
