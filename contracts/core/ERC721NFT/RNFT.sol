//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../openzeppelin/contracts/access/Ownable.sol";
import "../openzeppelin/contracts/security/Pausable.sol";
import "../openzeppelin/contracts/utils/Strings.sol";

/*
 * @title R NFT 
 */
contract RNFT is Ownable, Pausable, ERC721 {
    using Strings for uint256;
    uint256 private _mintNum;
    uint256 private _burnNum;
    uint256 private _totalSupply;
    string  private _baseURL;

    mapping(address => bool) private minters;
    modifier onlyMinter() {
        require(minters[_msgSender()], "Mint: caller is not the minter");
        _;
    }

    struct RStruct {
        uint256  id; 
        uint256  class;
        uint8    state; // 0 default value, 1 has been minted, 2 has been burnt
    }

    mapping(uint256 => RStruct) private RMap;

    constructor(
        string  memory name_, 
        string  memory symbol_, 
        uint256 totalSupply_, 
        string  memory url_
    ) 
        ERC721(name_, symbol_) 
    {
        _totalSupply = totalSupply_;
        _baseURL = url_;
        minters[_msgSender()] = true;
    }

    function mint(address to_) public onlyMinter whenNotPaused returns (bool) {
        _mintNum ++ ;
        require(_totalSupply >= _mintNum , "mint number is insufficient");

        RMap[_mintNum].id = _mintNum;
        RMap[_mintNum].class = 1;
        RMap[_mintNum].state = 1;
        _safeMint(to_, _mintNum);
        return true;
    }
	
    function updateClass(uint256 RID_, uint256 class_) public onlyMinter whenNotPaused returns (bool) {
        require(RMap[RID_].id != 0, "RNFT not exist");
        RMap[RID_].class = class_;
        return true;
    }

    function burn(uint256 RID_) public whenNotPaused {
        require(RMap[RID_].id != 0, "RNFT not exist");
        address owner = ownerOf(RID_);
        require(
            _msgSender() == owner || 
            _msgSender() == getApproved(RID_) || 
            isApprovedForAll(owner, _msgSender()), 
            "burn caller is not owner nor approved"
        );
        RMap[RID_].state = 2;
        _burnNum ++ ;
        _burn(RID_);
    }

    /** set totalSupply */	
    function setTotalSupply(uint256 totalSupply_) public onlyOwner {
        require(totalSupply_ >= _mintNum , "mint number is insufficient");
        _totalSupply = totalSupply_;
    }

    /** set minter */
    function setMinter(address newMinter, bool power) public onlyOwner {
        minters[newMinter] = power;
    }

    /** minter state */	
    function isMinter(address minter_) public view returns (bool){
        return minters[minter_];
    }

    /** set baseURL */
    function setURL(string memory newURL_) public onlyOwner {
        _baseURL = newURL_;
    }

    /** get mintNum */	
    function mintNum() public view returns (uint256){
        return _mintNum;
    }
    
    /** get burnNum */	
    function burnNum() public view returns (uint256){
        return _burnNum;
    }

    /** get totalSupply */	
    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }

    /** get baseURL */    	
    function baseURL() public view returns (string memory){
        return _baseURL;
    }

    /** get RURL */	
    function getRURL(uint256 RID_) public view returns (string memory) {
        require(RMap[RID_].id != 0, "RNFT not exist");
        return string(abi.encodePacked(_baseURL, RID_.toString()));
    }
	
    /** get class */	
    function getClass(uint256 RID_) public view returns (uint256) {
        return RMap[RID_].class;
    }
		
    /** get state */	
    function getState(uint256 RID_) public view returns (uint8) {
        return RMap[RID_].state;
    }

    /** get RStruct */
    function getR(uint256 RID_) public view returns (RStruct memory){
        return RMap[RID_];
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
