// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Import necessary contracts and libraries
import { Script } from "forge-std/Script.sol";
import { DevOpsTools } from "foundry-devops/src/DevOpsTools.sol";
import { MerkleAirdrop } from "src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {
    // Custom error for when signature length is invalid
    error ClaimAirdropScript__InvalidSignatureLength();

    // default anvil address
    address CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 CLAIMING_AMOUNT = 25e18; // 25 tokens

    // Merkle proof values needed to verify the claim
    bytes32 PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    // Array containing the proof hashes in correct order
    bytes32[] proof = [PROOF_ONE, PROOF_TWO];
    // Signature created by signing the message hash with the claimer's private key
    bytes private SIGNATURE =
        hex"12e145324b60cd4d302bfad59f72946d45ffad8b9fd608e672fd7f02029de7c438cfa0b8251ea803f361522da811406d441df04ee99c3dc7d65f8550e12be2ca1c";

    // Function to execute the claim transaction
    function claimAirdrop(address airdrop) public {
        // Start recording transactions for broadcasting
        vm.startBroadcast();
        // Split the signature into its components (v, r, s)
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        // Call the claim function on the airdrop contract with all necessary parameters
        MerkleAirdrop(airdrop).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, proof, v, r, s);
        // Stop recording transactions
        vm.stopBroadcast();
    }

    // Function to split a signature into its components
    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        // the length of the v, r, s, is 65 characters long
        // (v = 32) + (r = 32) + (s = 1) = 65
        // if not 65 characters long, revert with "invalid signature length"
        if (sig.length != 65) {
            revert ClaimAirdropScript__InvalidSignatureLength();
        }
        // Use assembly to efficiently extract the signature components
        assembly {
            // signature should be written in the sequence r, s, v (however, when using other functions, interfaces, or
            // OpenZeppelin for example, they will usually follow the format v, r, s)
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function run() external {
        // Get the address of the most recently deployed MerkleAirdrop contract
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        // Call claimAirdrop with the found contract address
        claimAirdrop(mostRecentlyDeployed);
    }
}
