// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../openzeppelin/contracts/utils/structs/BitMaps.sol";
import "../openzeppelin/contracts/access/Ownable.sol";

contract NFTMarket is Ownable {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _bitmap;

    bytes32 public root;

    IERC20  public tokenERC20;
	
    IERC721 public tokenERC721;
	
    uint256 public price;

    uint256 public buyAmount;
	
    /** Mapping from user to IERC20's balance number */
    mapping(address => uint256) public balanceOfToken;

    /** @dev Emitted when `owner` deposit `amount` to market. */	
    event DepositTokenEvent(address _owner, uint256 _amount);

    /** @dev Emitted when `owner` withdraw `amount` from market. */	
    event WithdrawTokenEvent(address _owner, uint256 _amount);
	
    event BuyEvent(address owner, uint256 NFTid, uint256 index);

    receive() external payable {
        revert("R");
    }

    constructor(address _tokenERC20, address _tokenERC721) {
        tokenERC20  = IERC20(_tokenERC20);
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

    function deposit(uint256 _amount) public {
        require(tokenERC20.balanceOf(msg.sender) >= _amount, "token balance is not enough");
        require(tokenERC20.allowance(msg.sender, address(this)) >= _amount, "token allowance is not enough");

        SafeERC20.safeTransferFrom(tokenERC20, msg.sender, address(this), _amount);
		
        balanceOfToken[msg.sender] = _amount;
        emit DepositTokenEvent(msg.sender, _amount);	
    }

    function withdraw() public {
        SafeERC20.safeTransfer(
            tokenERC20,
            msg.sender,
            balanceOfToken[msg.sender]
        );
        uint256 _amount = balanceOfToken[msg.sender];
        balanceOfToken[msg.sender] = 0;
        emit WithdrawTokenEvent(msg.sender, _amount);
    }

    function get(uint256 index) public view returns (bool) {
        return _bitmap.get(index);
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
    ) public {
        require(get(index) == false, "C:0");
        _bitmap.set(index);
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount, index));
        require(MerkleProof.verify(proof, root, leaf), "C:1");

        require(price > 0, "please set price");
        require(balanceOfToken[msg.sender] >= price, "token deposit balance is not enough");
        require(tokenERC721.ownerOf(NFTid) == address(this), "NFT is not owner of this contract");
		
        balanceOfToken[msg.sender] -= price;
        balanceOfToken[owner()]    += price;		
        tokenERC721.transferFrom(address(this), msg.sender, NFTid);
		
        buyAmount ++;
        emit BuyEvent(msg.sender, NFTid, index);
    }
}
