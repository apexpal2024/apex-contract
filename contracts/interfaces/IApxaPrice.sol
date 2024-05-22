// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IApxgPrice {
    function price() external view returns (uint256);

    function updater() external view returns (address);

    function getPrice() external view returns (uint256);

    function updateUpdater(address _updater) external;

    function updatePrice(uint256 _price) external;
}
