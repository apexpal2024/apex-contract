// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IBlast.sol";

contract AirEgg is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    using Strings for uint256;
    IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);

    bool public claimEnabled;
    bytes32 public root;
    string public imageUri;
    string public imageSuffix;
    address public updater;
    uint256 private _nextTokenId;

    mapping(address => bool) public hasClaimed;

    function initialize(
        string memory _imageUri,
        string memory _imageSuffix,
        bytes32 _root,
        address _updater
    ) public initializer {
        __ERC721_init("ApeXpal OG Egg", "XPAL");
        __ERC721Enumerable_init();
        __Ownable_init(msg.sender);
        imageUri = _imageUri;
        imageSuffix = _imageSuffix;
        root = _root;
        updater = _updater;
        claimEnabled = true;
    }

    event Claimed(address indexed account, uint256 tokenId);
    event Hatched(address indexed account, uint256 tokenId);

    function claim(bytes32[] memory proof) public {
        require(claimEnabled, "Claim is disabled");
        require(!hasClaimed[msg.sender], "You have already claimed");
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender)))
        );
        require(MerkleProof.verify(proof, root, leaf), "Invalid Merkle proof");
        uint256 tokenId = _nextTokenId++;
        hasClaimed[msg.sender] = true;
        _safeMint(msg.sender, tokenId);
        emit Claimed(msg.sender, tokenId);
    }

    function hatchEgg(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender ||
                getApproved(tokenId) == msg.sender,
            "You are not the owner or approved"
        );
        _burn(tokenId);
        emit Hatched(msg.sender, tokenId);
    }

    function getUserAllTokens(
        address account
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(account);
        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            result[i] = tokenOfOwnerByIndex(account, i);
        }
        return result;
    }

    function setRoot(bytes32 _root) public {
        require(msg.sender == owner() || msg.sender == updater, "You are not updater");
        root = _root;
    }

    function setImageUri(string memory _uri) public onlyOwner {
        imageUri = _uri;
    }

    function setImageSuffix(string memory _suffix) public onlyOwner {
        imageSuffix = _suffix;
    }

    function setUpdater(address _updater) public onlyOwner {
        updater = _updater;
    }

    function safeMintByAdmin(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    function setClaimEnabled(bool _claimEnabled) public onlyOwner {
        claimEnabled = _claimEnabled;
    }

    function setHasClaimed(address account, bool claimed) public onlyOwner {
        hasClaimed[account] = claimed;
    }

    function claimAllGas() external onlyOwner {
        BLAST.claimAllGas(address(this), msg.sender);
    }

    // The following functions` are overrides required by Solidity.
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory jsonPreImage = string.concat(
            string.concat(
                string.concat('{"name": "ApeXpal OG Egg #', tokenId.toString()),
                '","description":"Having a ApeXpal OG Egg allows you to hatch your own Xpals. Xpals play an essential role in ApeXpal.","external_url":"https://apexpal.io","image":"'
            ),
            string.concat(imageUri, imageSuffix)
        );
        string memory jsonPostTraits = '"}';

        return
            string.concat(
                "data:application/json;utf8,",
                string.concat(jsonPreImage, jsonPostTraits)
            );
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
