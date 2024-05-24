// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IAPXA.sol";
import "./interfaces/IBlast.sol";

contract Farm is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IAPXA public APXA;
    IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);
    
    bytes32 public root;
    address public rootUpdater;
    uint256 public currentRootVersion;
    
    mapping(address => uint256) public lastClaimVersion;

    event Claimed(address indexed account, uint256 amount);

    function initialize(
        address _APXA,
        address _rootUpdater
    ) external initializer {
        __Ownable_init(msg.sender);
        APXA = IAPXA(_APXA);
        rootUpdater = _rootUpdater;
        currentRootVersion = 0;
        BLAST.configureClaimableGas();
    }

    function claim(bytes32[] memory proof, uint256 amount) public nonReentrant {
        require(
            lastClaimVersion[msg.sender] < currentRootVersion,
            "You have already claimed"
        );

        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, amount)))
        );
        require(MerkleProof.verify(proof, root, leaf), "Invalid Merkle proof");
        
        lastClaimVersion[msg.sender] = currentRootVersion;
        APXA.convert(msg.sender, amount);
        
        emit Claimed(msg.sender, amount);
    }

    function getRoot() public view returns (bytes32) {
        return root;
    }

    function updateRoot(bytes32 _root) public {
        require(
            msg.sender == rootUpdater || msg.sender == owner(),
            "Not authorized"
        );
        require(_root != root, "The new root is the same as the current root");

        root = _root;
        currentRootVersion++;
    }

    function setRootUpdater(address _rootUpdater) public onlyOwner {
        rootUpdater = _rootUpdater;
    }


    function claimAllGas() external onlyOwner {
        BLAST.claimAllGas(address(this), msg.sender);
    }
}
