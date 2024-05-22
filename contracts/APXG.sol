// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IBlast.sol";

contract APXG is ERC20, AccessControl {
    IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);
    bytes32 public constant CONVERT_ROLE = keccak256("CONVERT_ROLE");

    constructor() ERC20("ApeXpal.io Token", "APXG") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CONVERT_ROLE, msg.sender);
        _mint(address(this), 500_000_000 * 10 ** 18);
        BLAST.configureClaimableGas();
    }

    function setConvertRole(
        address user,
        bool _enable
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(user != address(0), "user is the zero0 address");
        if (_enable) {
            _grantRole(CONVERT_ROLE, user);
        } else {
            _revokeRole(CONVERT_ROLE, user);
        }
    }

    function withdraw(
        address user,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        SafeERC20.safeTransfer(IERC20(address(this)), user, amount);
    }

    function convert(
        address user,
        uint256 amount
    ) external onlyRole(CONVERT_ROLE) {
        SafeERC20.safeTransfer(IERC20(address(this)), user, amount);
    }

    function claimAllGas() external onlyRole(DEFAULT_ADMIN_ROLE) {
        BLAST.claimAllGas(address(this), msg.sender);
    }
}
