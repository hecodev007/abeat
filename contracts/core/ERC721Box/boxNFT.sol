//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../openzeppelin/contracts/access/Ownable.sol";
import "../openzeppelin/contracts/security/Pausable.sol";
import "../openzeppelin/contracts/utils/Strings.sol";

/*
 * @title Box NFT 
 */
contract BoxNFT is Ownable, Pausable, ERC721 {
    using Strings for uint256;
    uint256 private _mintNum;
    uint256 private _burnNum;
    uint256 private _totalSupply;
    uint256 private _price;
    string  private _baseURL;

    mapping(address => bool) private minters;
    modifier onlyMinter() {
        require(minters[_msgSender()], "Mint: caller is not the minter");
        _;
    }

    struct Box {
        uint256  id; 
        string   fingerprint; 
        uint8    heroSSR;
        uint8    heroSR;
        uint8    heroR;
        uint256  equipExperience;
        uint256  equipStar;
        uint256  equipClass;
        uint256  gold;
        uint256  cardFragment;
        uint8    state; // 0 default value, 1 has been minted, 2 has been burnt
    }

    mapping(uint256 => Box) private BoxMap;

    constructor(
        string memory name_, 
        string memory symbol_, 
        uint256 totalSupply_, 
        string memory url_
    ) 
        ERC721(name_, symbol_) 
    {
        _mintNum = 0;
        _burnNum = 0;
        _totalSupply = totalSupply_;
        _baseURL = url_;
        minters[_msgSender()] = true;
    }

    function mint(address to_, string memory fingerprint_) public onlyMinter whenNotPaused returns (bool) {
        _mintNum ++ ;
        require(_totalSupply >= _mintNum , "mint number is insufficient");

        BoxMap[_mintNum].id = _mintNum;
        BoxMap[_mintNum].fingerprint = fingerprint_;
        BoxMap[_mintNum].state = 1;
        _safeMint(to_, _mintNum);
        return true;
    }
	
    function buy(address to_, string memory fingerprint_) public payable whenNotPaused returns (bool) {
        _mintNum ++ ;
        require(_totalSupply >= _mintNum , "mint number is insufficient");
        require(_price > 0 && msg.value >= _price);

        BoxMap[_mintNum].id = _mintNum;
        BoxMap[_mintNum].fingerprint = fingerprint_;
        BoxMap[_mintNum].state = 1;
        _safeMint(to_, _mintNum);
        return true;
    }

    function updateFingerprint(uint256 BoxID_, string memory fingerprint_) public onlyMinter whenNotPaused returns (bool) {
        require(BoxMap[BoxID_].id != 0, "box not exist");
        BoxMap[BoxID_].fingerprint = fingerprint_;
        return true;
    }

    function burn(uint256 BoxID_) public whenNotPaused {
        require(BoxMap[BoxID_].id != 0, "box not exist");
        address owner = ownerOf(BoxID_);
        require(
            _msgSender() == owner || 
            _msgSender() == getApproved(BoxID_) || 
            isApprovedForAll(owner, _msgSender()), 
            "burn caller is not owner nor approved"
        );
        BoxMap[BoxID_].state = 2;
        _burnNum ++ ;
        _burn(BoxID_);
    }
	
	function open(
        uint256  BoxID_,
        uint8    heroSSR_,
        uint8    heroSR_,
        uint8    heroR_,
        uint256  equipExperience_,
        uint256  equipStar_,
        uint256  equipClass_,
        uint256  gold_,
        uint256  cardFragment_
    ) 
        public 
        onlyMinter 
        whenNotPaused 
    {
        require(BoxMap[BoxID_].id != 0, "box not exist");
        BoxMap[BoxID_].heroSSR = heroSSR_;
        BoxMap[BoxID_].heroSR = heroSR_;
        BoxMap[BoxID_].heroR = heroR_;
        BoxMap[BoxID_].equipExperience = equipExperience_;
        BoxMap[BoxID_].equipStar = equipStar_;
        BoxMap[BoxID_].equipClass = equipClass_;
        BoxMap[BoxID_].gold = gold_;
        BoxMap[BoxID_].cardFragment = cardFragment_;
        BoxMap[BoxID_].state = 2;
        _burnNum ++ ;
        _burn(BoxID_);
    }

    /** get balance of this contract */     
    function getBalancetOfETH() public view returns (uint256) {
        return address(this).balance;
    }

    /** withdraw eth from this contract */    
    function withdraw(address payable to_, uint256 amount_) public whenNotPaused onlyOwner {
        require(amount_ <= address(this).balance);
        to_.transfer(amount_);
    }

    /** set price */	
    function setPrice(uint256 price_) public onlyOwner {
        _price = price_;
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

    /** get price */	
    function price() public view returns (uint256){
        return _price;
    }

    /** get baseURL */    	
    function baseURL() public view returns (string memory){
        return _baseURL;
    }

    /** get boxURL */	
    function getBoxURL(uint256 BoxID_) public view returns (string memory) {
        require(BoxMap[BoxID_].id != 0, "box not exist");
        return string(abi.encodePacked(_baseURL, BoxID_.toString()));
    }

    /** get fingerprint */	
    function getFingerprint(uint256 BoxID_) public view returns (string memory) {
        require(BoxMap[BoxID_].id != 0, "box not exist");
        return BoxMap[BoxID_].fingerprint;
    }

    /** get Box */
    function getBox(uint256 BoxID_) public view returns (Box memory){
        return BoxMap[BoxID_];
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
