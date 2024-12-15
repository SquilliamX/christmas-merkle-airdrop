// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { ChristmasToken } from "./ChristmasToken.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    // we can call all the functions from the library SafeERC20 for all variables that are of type IERC20
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    /// @notice The root hash of the merkle tree, immutable once set
    /// @dev Used to verify the validity of claims against the merkle proof
    bytes32 private immutable i_merkleRoot;

    /// @notice The ERC20 token contract that will be distributed in the airdrop
    /// @dev Immutable to ensure the token address cannot be changed after deployment
    IERC20 private immutable i_airdropToken;

    // mapping to identify whether an address has claimed or not
    mapping(address claimer => bool claimed) private s_hasClaimed;

    // Event emitted when someone successfully claims their airdrop tokens
    // @param account The address of the claimer
    // @param amount The amount of tokens claimed
    event Claim(address account, uint256 amount);

    /// @notice Constructor initializes the contract with merkle root and token address
    /// @param merkleRoot The root hash of the merkle tree containing all valid claims
    /// @param airdropToken The ERC20 token contract address that will be airdropped
    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    /// @notice Allows users to claim their airdrop tokens if they have a valid proof
    /// @param account The address that will receive the tokens
    /// @param amount The amount of tokens to be claimed
    /// @param merkleProof Array of hashes that proves the claim is valid
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        // Check if the account has already claimed their tokens
        if (s_hasClaimed[account] == true) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // encode the account and the amount together, then hashed the encoded value.
        // wraps the hash as bytes and hashes it again to avoid hash collisions just in case. (this is known as a
        // pre-image attack.A pre-image attack is when an attacker tries to find an input that produces the same hash
        // output, by encoding twice, we avoid this problem).
        // this is the standard way of encode and hash leaf nodes.
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));

        // Verify that this leaf node is part of the merkle tree
        // merkleProof: Array of hashes providing the branch path from leaf to root
        // i_merkleRoot: The root hash of the merkle tree stored during contract deployment
        // leaf: The hash of the node we're trying to verify (contains account and amount)
        // If verification fails (proof is invalid), revert the transaction
        // calls the verify function from the openzeppelin's MerkleProof contract. This verify will compare the sum of
        // the leaf and the proof(branch) and makes sure that the root is equal to the expected root.
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        // update the mapping for users that have claimed before we send tokens to prevent reentrancy
        s_hasClaimed[account] = true;
        // before we send tokens we want to emit event
        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }

    /// @notice Getter function to retrieve the merkle root hash
    /// @dev This value is immutable and set during contract deployment
    /// @return bytes32 The merkle root hash used for verification
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    /// @notice Getter function to retrieve the airdrop token contract address
    /// @dev This value is immutable and set during contract deployment
    /// @return IERC20 The ERC20 token contract being distributed
    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}
