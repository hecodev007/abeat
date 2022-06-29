// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../openzeppelin/contracts/utils/structs/BitMaps.sol";
import "../openzeppelin/contracts/access/Ownable.sol";
import "../ERC721NFT/SSRNFT_new.sol";

contract NFTMarket is Ownable {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _bitmap;

    bytes32 public root;

    IERC20  public tokenERC20;

    IERC721 public tokenERC721;
    SSRNFT   public     nft;
    uint256 public price;
    uint256 public price_bnb;

    uint256 public buyAmount;

    mapping(uint => uint256) public typeNft;

    event BuyEvent(address owner, uint256 NFTid, uint256 index);

    receive() external payable {
        revert("R");
    }

    constructor(address _tokenERC20, address _tokenERC721) {
        tokenERC20 = IERC20(_tokenERC20);
        tokenERC721 = IERC721(_tokenERC721);
        nft = SSRNFT(_tokenERC721);
        typeNft[0] = 0;
        typeNft[1] = 165;
        typeNft[2] = 165 * 2;
    }

    function setRoot(bytes32 _root) public onlyOwner returns (bool) {
        root = _root;
        return true;
    }

    function setPrice(uint256 _price, uint256 _price_bnb) public onlyOwner returns (bool) {
        price = _price;
        price_bnb = _price_bnb;
        return true;
    }

    function get(uint256 index) public view returns (bool) {
        return _bitmap.get(index);
    }

    function tokensOf(address user, uint256 idStart, uint256 idEnd) public view returns (uint256[] memory, uint256) {
        require(idEnd >= idStart, "invalid index");
        uint256[] memory ids = new uint256[](idEnd - idStart + 1);
        uint256 j = 0;
        for (uint256 i = idStart; i <= idEnd; i++) {
            if (i < nft.totalSupply()) {
                if (nft.ownerOf(i) == user) {
                    ids[j++] = i;
                }

            }
        }
        return (ids,j);
    }

    function withdraw() external onlyOwner {
        SafeERC20.safeTransfer(
            tokenERC20,
            owner(),
            tokenERC20.balanceOf(address(this))
        );
    }

    function withdrawBnb() external onlyOwner {
        address payable recipient = payable(msg.sender);
        recipient.transfer(address(this).balance);
    }

    function withdrawNFT(uint256 NFTid) external onlyOwner {
        tokenERC721.transferFrom(
            address(this),
            owner(),
            NFTid
        );
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public pure returns (bytes4){
        operator;
        from;
        tokenId;
        data;
        return this.onERC721Received.selector;
    }

    function buy(
        uint256 index,
        uint256 amount,
        bytes32[] memory proof,
        uint nftType
    ) public payable {
        require(get(index) == false, "you have already bought one");
        require(nftType >= 0 && nftType <= 2, "nft type error");
        uint256 NFTid;
        if (nftType == 0) {
            typeNft[0] = typeNft[0] + 1;
            require(typeNft[0] <= 165, "no left of this nft type");
            NFTid = typeNft[0];
        } else if (nftType == 1) {
            typeNft[1] = typeNft[1] + 1;
            require(typeNft[1] <= 165 * 2, "no left of this nft type");
            NFTid = typeNft[1];
        } else if (nftType == 2) {
            typeNft[2] = typeNft[2] + 1;
            require(typeNft[2] <= 165 * 3, "no left of this nft type");
            NFTid = typeNft[2];
        }

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount, index));

        require(MerkleProof.verify(proof, root, leaf), "the item has been sold out");
        if (msg.value > 0) {
            require(msg.value >= price_bnb, "BNB value is not enough");
        } else {
            require(price > 0, "please set price");
            require(tokenERC20.balanceOf(msg.sender) >= price, "token balance is not enough");
            require(tokenERC20.allowance(msg.sender, address(this)) >= price, "token allowance is not enough");
            SafeERC20.safeTransferFrom(tokenERC20, msg.sender, address(this), price);
        }

        require(tokenERC721.ownerOf(NFTid) == address(this), "NFT is not owner of this contract");

        tokenERC721.transferFrom(address(this), msg.sender, NFTid);
        _bitmap.set(index);
        buyAmount ++;
        emit BuyEvent(msg.sender, NFTid, index);
    }
}
