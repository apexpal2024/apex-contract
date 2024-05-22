// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IEthPrice {
    function getPriceETH() external view returns (uint256);

    function getPriceUnsafeETH() external view returns (uint256);
}
