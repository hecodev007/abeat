// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dispatcher is Ownable {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _bitmap;

    bytes32 public root;

    IERC20 public token;

    uint256 public claimAmount;

    event Claim(address owner, uint256 amount, uint256 index);

    receive() external payable {
        revert("R");
    }

    constructor(bytes32 _root, address _token) {
        root = _root;
        token = IERC20(_token);
    }

    function deposit(uint256 _amount) external {
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), _amount);
    }

    function withdraw() external onlyOwner {
        SafeERC20.safeTransfer(
            token,
            owner(),
            IERC20(address(token)).balanceOf(address(this))
        );
    }

    function get(uint256 index) public view returns (bool) {
        return _bitmap.get(index);
    }

    function claim(
        uint256 index,
        uint256 amount,
        bytes32[] memory proof
    ) public {
        require(get(index) == false, "C:0");
        _bitmap.set(index);
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount, index));
        require(MerkleProof.verify(proof, root, leaf), "C:1");
        SafeERC20.safeTransfer(token, msg.sender, amount);
        claimAmount += amount;
        emit Claim(msg.sender, amount, index);
    }
}
