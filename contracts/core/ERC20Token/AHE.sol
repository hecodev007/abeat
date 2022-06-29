//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../openzeppelin/contracts/access/Ownable.sol";
import "../openzeppelin/contracts/security/Pausable.sol";

/*
 * @title AHE ERC20 Token
 */
contract AHE is Ownable, Pausable, ERC20 {

    mapping(address => bool) private minters;
    modifier onlyMinter() {
        require(minters[_msgSender()], "Mint: caller is not the minter");
        _;
    }

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        minters[_msgSender()] = true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing the total supply. */
    function mint(address account_, uint256 amount_) public onlyMinter whenNotPaused returns (bool) {
        _mint(account_, amount_);
        return true;
    }

    /** @dev Destroys `amount` tokens from `account`, reducing the total supply. */
    function burn(address account_, uint256 amount_) public whenNotPaused returns (bool) {
        require(balanceOf(account_) >= amount_, "transfer amount exceeds balance");
        require(account_ == _msgSender() || allowance(account_, _msgSender()) >= amount_, "burn caller is not owner nor approved");
        _burn(account_, amount_);
        if (account_ != _msgSender()) {
            uint256 currentAllowance = allowance(account_, _msgSender());
            _approve(account_, _msgSender(), currentAllowance - amount_);
        }
        return true;
    }

    /** set minter */
    function setMinter(address newMinter, bool power) public onlyOwner {
        minters[newMinter] = power;
    }

    /** minter state */		
    function isMinter(address minter_) public view returns (bool){
        return minters[minter_];
    }
	
    /** set contract state */
    function setPause(bool isPause) public onlyOwner {
        if (isPause) {
            _pause();
        } else {
            _unpause();
        }
    }
}
