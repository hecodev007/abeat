//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../openzeppelin/contracts/access/Ownable.sol";
import "../openzeppelin/contracts/security/Pausable.sol";
import "../openzeppelin/contracts/utils/Strings.sol";

/*
 * @title SR NFT 
 */
contract SRNFT is Ownable, Pausable, ERC721 {
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

    struct SRStruct {
        uint256  id; 
        uint256  class;
        uint8    state; // 0 default value, 1 has been minted, 2 has been burnt
    }

    mapping(uint256 => SRStruct) private SRMap;

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

        SRMap[_mintNum].id = _mintNum;
        SRMap[_mintNum].class = 1;
        SRMap[_mintNum].state = 1;
        _safeMint(to_, _mintNum);
        return true;
    }
	
    function updateClass(uint256 SRID_, uint256 class_) public onlyMinter whenNotPaused returns (bool) {
        require(SRMap[SRID_].id != 0, "SRNFT not exist");
        SRMap[SRID_].class = class_;
        return true;
    }

    function burn(uint256 SRID_) public whenNotPaused {
        require(SRMap[SRID_].id != 0, "SRNFT not exist");
        address owner = ownerOf(SRID_);
        require(
            _msgSender() == owner || 
            _msgSender() == getApproved(SRID_) || 
            isApprovedForAll(owner, _msgSender()), 
            "burn caller is not owner nor approved"
        );
        SRMap[SRID_].state = 2;
        _burnNum ++ ;
        _burn(SRID_);
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

    /** get SRURL */	
    function getSRURL(uint256 SRID_) public view returns (string memory) {
        require(SRMap[SRID_].id != 0, "SRNFT not exist");
        return string(abi.encodePacked(_baseURL, SRID_.toString()));
    }
	
    /** get class */	
    function getClass(uint256 SRID_) public view returns (uint256) {
        return SRMap[SRID_].class;
    }
		
    /** get state */	
    function getState(uint256 SRID_) public view returns (uint8) {
        return SRMap[SRID_].state;
    }

    /** get SRStruct */
    function getSR(uint256 SRID_) public view returns (SRStruct memory){
        return SRMap[SRID_];
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
