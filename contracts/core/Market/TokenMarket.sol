// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../openzeppelin/contracts/access/Ownable.sol";
import "../openzeppelin/contracts/utils/math/SafeMath.sol";


contract TokenMarket is Ownable {
    using SafeMath for uint256;

    // bytes32 public root;

    IERC20  public tokenERC20;
    IERC20  public abeatsERC20;
    uint256 public price;
    uint256 public price_bnb;
    uint256 public  total;
    uint256 public limit;
    uint256 public chain;
    mapping(uint => bool) tokenList;

    event BuyEvent(address owner, uint token, uint _lockType, uint256 amount);

    receive() external payable {
        revert("R");
    }

    constructor() {
        //tokenERC20 = IERC20(_tokenERC20);
        tokenList[0] = true;

    }

    //    function setRoot(bytes32 _root) public onlyOwner returns (bool) {
    //        root = _root;
    //        return true;
    //    }

    function setPrice(uint256 _price, uint256 _price_bnb) public onlyOwner returns (bool) {
        price = _price;
        price_bnb = _price_bnb;
        return true;
    }

    function setBuyToken(address _tokenERC20, address _abeats) public onlyOwner {
        tokenERC20 = IERC20(_tokenERC20);
        abeatsERC20 = IERC20(_abeats);
    }

    function setTokenList(uint token, bool b) public onlyOwner {
        tokenList[token] = b;
    }

    function setLimit(uint256 _limit) public onlyOwner {
        limit = _limit;
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


    function buy(
        uint256 amount,
        uint token,
        uint _lockType
    ) public payable {

        require(amount >= limit, "param error");
        require(tokenList[token] == true, "param error");
        if (msg.value > 0) {
            require(price_bnb > 0, "please set price");
            require(msg.value >= price_bnb.mul(amount), "BNB value is not enough");
        } else {
            require(price > 0, "please set price");
            require(tokenERC20.balanceOf(msg.sender) >= price.mul(amount), "token balance is not enough");
            require(tokenERC20.allowance(msg.sender, address(this)) >= price.mul(amount), "token allowance is not enough");
            SafeERC20.safeTransferFrom(tokenERC20, msg.sender, address(this), price.mul(amount));
        }
        if (address(abeatsERC20) != address(0)) {
            SafeERC20.safeTransfer(
                abeatsERC20,
                msg.sender,
                amount.mul(1e18)
            );
        }
        emit BuyEvent(msg.sender, token, _lockType, amount);
    }
}
