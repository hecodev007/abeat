// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../openzeppelin/contracts/utils/structs/BitMaps.sol";
import "../openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Dispatcher is Ownable {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _bitmap;

    bytes32 public root;

    IERC20 public token;

    uint256 public claimAmount;

    struct Record {
        uint256 claimTime;
        uint256 amount;
    }

    mapping(address => Record) public claimRecord;

    bool public pause = false;
    address  public admin;

    event Claim(address owner, uint256 amount, uint256 index);

    receive() external payable {
        revert("R");
    }

    modifier onlyAmin() {
        require(admin == _msgSender(), "Ownable: caller is not the admin");
        _;
    }
    constructor(address _token, address _admin) {
        token = IERC20(_token);
        admin = _admin;
    }

    function deposit(uint256 _amount) external {
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), _amount);
    }

    function setRoot(bytes32 _root) public onlyOwner returns (bool) {
        root = _root;
        return true;
    }

    function setPause() public onlyOwner {
        pause = !pause;
    }

    function withdraw() external onlyAmin {
        SafeERC20.safeTransfer(
            token,
            owner(),
            IERC20(address(token)).balanceOf(address(this))
        );
    }

    function get(uint256 index) public view returns (bool) {
        return _bitmap.get(index);
    }

    function getCurTime() public view returns (uint256) {
        return block.timestamp;
    }

    function claimed(address _account) public view returns (bool) {
        return block.timestamp - claimRecord[_account].claimTime < 12 hours;
    }

    function claim(
        uint256 index,
        uint256 amount,
        bytes32[] memory proof
    ) public {
        require(pause == false, "C:2");
        require(claimed(msg.sender) == false, "C:3");
        require(get(index) == false, "C:0");
        _bitmap.set(index);
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount, index));
        //bytes32 leaf = keccak256(abi.encodePacked(amount,index));
        require(MerkleProof.verify(proof, root, leaf), "C:1");
        SafeERC20.safeTransfer(token, msg.sender, amount);
        claimAmount += amount;
        claimRecord[msg.sender] = Record(block.timestamp, amount);
        emit Claim(msg.sender, amount, index);
    }
}
