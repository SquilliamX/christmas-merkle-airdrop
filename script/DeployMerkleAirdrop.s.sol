// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Script } from "forge-std/Script.sol";
import { MerkleAirdrop } from "../src/MerkleAirdrop.sol";
import { ChristmasToken } from "../src/ChristmasToken.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeployMerkleAirDrop is Script {
    // our merkle root
    bytes32 private s_merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    // the amount each user is getting airdropped, multiplied by 4 since there are 4 users
    uint256 private s_amountToTransfer = 4 * 25e18;

    function deployMerkleAirDrop() public returns (MerkleAirdrop, ChristmasToken) {
        // everything inbetween broadcasts will be live on the blockchain
        vm.startBroadcast();
        // deploy new instance of the Christmas token
        ChristmasToken token = new ChristmasToken();
        // deploy new instance of the MerkleAirdrop contract with the merkle root and the christmas token, since these
        // are the parameters that the MerkleAirdrop contract takes in the constructor
        MerkleAirdrop airdrop = new MerkleAirdrop(s_merkleRoot, IERC20(address(token)));
        // mint ourselves the tokens (whoever deploys this deployment script will get the tokens)
        token.mint(token.owner(), s_amountToTransfer);

        // The transfer function in ERC20 always moves tokens from msg.sender
        // During the broadcast section of a Forge script, all transactions are sent from the deployer's address
        // So msg.sender for this transfer is your wallet address (the owner)
        // transfer tokens from owners(our address) to the address of the Merkle Airdrop contract that was just
        // deployed.
        token.transfer(address(airdrop), s_amountToTransfer);
        // stop executing transactions
        vm.stopBroadcast();

        // return the airdrop & token contracts and addresses
        return (airdrop, token);
    }

    function run() external returns (MerkleAirdrop, ChristmasToken) {
        return deployMerkleAirDrop();
    }
}
