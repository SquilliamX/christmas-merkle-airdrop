// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// we use ownable because we want this contract to have a owner so he mint tokens to whomever he chooses
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract ChristmasToken is ERC20, Ownable {
    // pass the constructor params needed from parent contracts ERC20 and Ownable
    // name of this token is `ChristmasToken` and the ticker is `CHRMST`
    // the owner is whoever deploys this contract
    constructor() ERC20("ChristmasToken", "CHRMST") Ownable(msg.sender) { }

    // `onlyOwner` modifier makes this function only callable by the deployer of this contract, since he will be the
    // owner.
    function mint(address to, uint256 amount) external onlyOwner {
        // call the parent contracts `_mint` function and pass the to and amount inputted by the owner of this contract
        _mint(to, amount);
    }
}
