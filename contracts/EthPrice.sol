// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract EthPrice is Initializable, OwnableUpgradeable {
    bytes32 public priceId;
    AggregatorV3Interface internal dataFeed_ETH_USD;

    function initialize(address _dataFeed_ETH_USD) public initializer {
        __Ownable_init(msg.sender);
        dataFeed_ETH_USD = AggregatorV3Interface(_dataFeed_ETH_USD);
    }

    function updateDataFeedEthUsd(
        address _dataFeed_ETH_USD
    ) external onlyOwner {
        dataFeed_ETH_USD = AggregatorV3Interface(_dataFeed_ETH_USD);
    }

    function getPriceETH() public view returns (uint256) {
        (, int data, , , ) = dataFeed_ETH_USD.latestRoundData();
        require(data > 0, "Swap: Invalid ETH price");
        return uint256(data);
    }
}
