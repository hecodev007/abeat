// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../openzeppelin/contracts/utils/structs/BitMaps.sol";
import "../openzeppelin/contracts/access/Ownable.sol";

contract NFTMarket is Ownable {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _bitmap;

    bytes32 public root;

    IERC721 public tokenERC721;
	
    uint256 public price;

    uint256 public buyAmount;
	
    event BuyEvent(address owner, uint256 NFTid, uint256 index);

    receive() external payable {
        revert("R");
    }

    constructor(address _tokenERC721) {
        tokenERC721 = IERC721(_tokenERC721);
    }

    function setRoot(bytes32 _root) public onlyOwner returns (bool) {
        root = _root;
        return true;
    }

    function setPrice(uint256 _price) public onlyOwner returns (bool) {
        price = _price;
        return true;
    }

    function get(uint256 index) public view returns (bool) {
        return _bitmap.get(index);
    }

    function withdraw() external onlyOwner {
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
        uint256 NFTid
    ) public payable{
        require(get(index) == false, "you have already bought one");
        _bitmap.set(index);
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount, index));
        require(MerkleProof.verify(proof, root, leaf), "the item has been sold out");

        require(price > 0, "please set price");
        require(msg.value >= price, "BNB value is not enough");

        require(tokenERC721.ownerOf(NFTid) == address(this), "NFT is not owner of this contract");
	
        tokenERC721.transferFrom(address(this), msg.sender, NFTid);
		
        buyAmount ++;
        emit BuyEvent(msg.sender, NFTid, index);
    }
}
