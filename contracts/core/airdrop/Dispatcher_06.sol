// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../openzeppelin/contracts/utils/structs/BitMaps.sol";
import "../openzeppelin/contracts/access/Ownable.sol";

contract Dispatcher is Ownable {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _bitmap;

    bytes32 public root;

    IERC20 public token;

    uint256 public MaxAmount;
	
    uint256 public claimAmount;
	
    uint256 public grandNUM;

    event Claim(address owner, uint256 amount, uint256 index);

    receive() external payable {
        revert("R");
    }

    constructor(address _token) {
        token = IERC20(_token);
        MaxAmount = 30000000;
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
    
    function setRoot(bytes32 _root) public onlyOwner returns (bool) {
        root = _root;
        return true;
    }	


    function get(uint256 index) public view returns (bool) {
        return _bitmap.get(index);
    }

    function claim(
        uint256 index,
        uint256 check,
        bytes32[] memory proof
    ) public {
        require(get(index) == false, "C:0");
        _bitmap.set(index);
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, check, index));
        require(MerkleProof.verify(proof, root, leaf), "C:1");
		
        uint256 transferAmount = randomAmount();
        if (grandNUM == 0 && MaxAmount < 1000000 + claimAmount + transferAmount){
            transferAmount = 1000000;
        }
        if (transferAmount + claimAmount >= MaxAmount){
            transferAmount = MaxAmount - claimAmount;
        }
        if (transferAmount == 1000000){
            grandNUM ++;
        }		

        SafeERC20.safeTransfer(token, msg.sender, transferAmount * 10 ** 18);
        claimAmount += transferAmount;		
        
        emit Claim(msg.sender, transferAmount, index);
    }

    // keccak256 hash 
    function randomNumber(uint256 limit_) private view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, claimAmount))) % limit_;
        return  rand;
    }

    function randomAmount() public view returns (uint256) {	
        uint256 randNum = randomNumber(100000); 
        if (claimAmount == MaxAmount){
            return 0;
        }
        if (randNum < 50){
            if (grandNUM < 5){
                return 1000000;
            } else {
                return 1000 + randomNumber(2000);
            }            
        } else if (randNum < 10000){
            return 1000 + randomNumber(2000);
        } else {
            return 20 + randomNumber(40);
        }
    }
}
