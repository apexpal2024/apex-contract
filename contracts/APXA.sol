// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IBlast.sol";

contract APXA is ERC20, ERC20Burnable, AccessControl {
    IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("APXA", "APXA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _mint(address(this), 6_000_000 * 10 ** 18);
        BLAST.configureClaimableGas();
    }

    function setMinterRole(
        address user,
        bool _enable
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(user != address(0), "user is the zero address");
        if (_enable) {
            _grantRole(MINTER_ROLE, user);
        } else {
            _revokeRole(MINTER_ROLE, user);
        }
    }

    function convert(
        address user,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) {
        require(user != address(0), "user is the zero address");
        _mint(user, amount);
    }

    function burn(uint256 amount) public override {
        _burn(_msgSender(), amount);
    }

    function withdraw(
        address user,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        SafeERC20.safeTransfer(IERC20(address(this)), user, amount);
    }

    function claimAllGas() external onlyRole(DEFAULT_ADMIN_ROLE) {
        BLAST.claimAllGas(address(this), msg.sender);
    }
}
