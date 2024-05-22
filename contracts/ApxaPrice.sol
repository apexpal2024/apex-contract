// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ApxaPrice is Initializable, OwnableUpgradeable {
    uint256 public price;
    address public updater; 

    function initialize(address _updater) public initializer {
        __Ownable_init(msg.sender);
        updater = _updater;
        price = 500000; // defaut 0.005usd (decimals 8)
    }

    function getPrice() external view returns (uint256) {
        return price;
    }

    function updateUpdater(address _updater) external onlyOwner {
        updater = _updater;
    }

    function updatePrice(uint256 _price) external {
        require(
            msg.sender == updater || msg.sender == owner(),
            "Apxa Price:You are not updater"
        );
        price = _price;
    }
}
