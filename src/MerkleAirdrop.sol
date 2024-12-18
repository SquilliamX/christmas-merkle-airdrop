// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

// Import required contracts and libraries
import { ChristmasToken } from "./ChristmasToken.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Contract inherits from EIP712 for structured data signing
contract MerkleAirdrop is EIP712 {
    // we can call all the functions from the library SafeERC20 for all variables that are of type IERC20
    using SafeERC20 for IERC20;

    // Custom error definitions for reverting with specific failure reasons
    error MerkleAirdrop__InvalidProof(); // Thrown when the merkle proof verification fails
    error MerkleAirdrop__AlreadyClaimed(); // Thrown when an address attempts to claim twice
    error MerkleAirdrop__InvalidSignature(); // Thrown when the signature verification fails

    /// @notice The root hash of the merkle tree, immutable once set
    /// @dev Used to verify the validity of claims against the merkle proof
    bytes32 private immutable i_merkleRoot;

    /// @notice The ERC20 token contract that will be distributed in the airdrop
    /// @dev Immutable to ensure the token address cannot be changed after deployment
    IERC20 private immutable i_airdropToken;

    // Mapping to track which addresses have already claimed their tokens
    mapping(address claimer => bool claimed) private s_hasClaimed;

    // EIP712 type hash for the structured data signing
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    // Struct defining the data structure for an airdrop claim
    struct AirdropClaim {
        address account; // Address that will receive the tokens
        uint256 amount; // Amount of tokens to be claimed
    }

    // Event emitted when someone successfully claims their airdrop tokens
    // @param account The address of the claimer
    // @param amount The amount of tokens claimed
    event Claim(address account, uint256 amount);

    /// @notice Constructor initializes the contract with merkle root and token address
    /// @param merkleRoot The root hash of the merkle tree containing all valid claims
    /// @param airdropToken The ERC20 token contract address that will be airdropped
    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = merkleRoot; // Store the merkle root
        i_airdropToken = airdropToken; // Store the token contract address
    }

    /// @notice Allows users to claim their airdrop tokens if they have a valid proof
    /// @param account The address that will receive the tokens
    /// @param amount The amount of tokens to be claimed
    /// @param merkleProof Array of hashes that proves the claim is valid
    function claim(
        address account, // Address that will receive tokens
        uint256 amount, // Amount of tokens to be claimed
        bytes32[] calldata merkleProof, // Proof of inclusion in merkle tree
        uint8 v, // Recovery byte of the signature
        bytes32 r, // First 32 bytes of the signature
        bytes32 s // Last 32 bytes of the signature
    )
        external
    {
        // Check if the account has already claimed their tokens
        if (s_hasClaimed[account] == true) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        // Verify the signature matches the claiming account
        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
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
        // emit event before we send tokens
        emit Claim(account, amount);

        // Transfer the tokens to the claiming account
        i_airdropToken.safeTransfer(account, amount);
    }

    // Returns the EIP712 typed data hash for a claim
    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        // Create and return the typed data hash using EIP712 standard
        return _hashTypedDataV4(
            keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({ account: account, amount: amount })))
        );
    }

    /// @notice Getter function to retrieve the merkle root hash
    /// @return bytes32 The merkle root hash used for verification
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    /// @notice Getter function to retrieve the airdrop token contract address
    /// @return IERC20 The ERC20 token contract being distributed
    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }

    // Validates if the signature was created by the claiming account
    function _isValidSignature(
        address account, // Address that should have signed the message
        bytes32 digest, // Hash of the data that was signed
        uint8 v, // Recovery byte of the signature
        bytes32 r, // First 32 bytes of the signature
        bytes32 s // Last 32 bytes of the signature
    )
        internal
        pure
        returns (bool)
    {
        // Recover the signer's address from the signature components
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        // Return true if the recovered signer matches the expected account
        return actualSigner == account;
    }
}
