// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Script } from "forge-std/Script.sol";
import { MerkleAirdrop } from "../src/MerkleAirdrop.sol";
import { ChristmasToken } from "../src/ChristmasToken.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeployMerkleAirDrop is Script {
    function deployMerkleAirDrop() public returns (MerkleAirdrop, ChristmasToken) { }

    function run() external returns (MerkleAirdrop, ChristmasToken) {
        return deployMerkleAirDrop();
    }
}
