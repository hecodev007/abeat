//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../openzeppelin/contracts/access/Ownable.sol";
import "../openzeppelin/contracts/security/Pausable.sol";
import "../openzeppelin/contracts/utils/Strings.sol";

/*
 * @title SSR NFT 
 */
contract SSRNFT is Ownable, Pausable, ERC721 {
    using Strings for uint256;
    uint256 public _mintNum;
    uint256 private _burnNum;
    uint256 private _totalSupply;
    string  private _baseURL;
    mapping(uint256 => uint256) public  idNft;
    mapping(address => bool) private minters;
    modifier onlyMinter() {
        require(minters[_msgSender()], "Mint: caller is not the minter");
        _;
    }

    struct SSRStruct {
        uint256 id;
        uint256 class;
        uint8 state; // 0 default value, 1 has been minted, 2 has been burnt
    }

    mapping(uint256 => SSRStruct) private SSRMap;

    event Mint(address to, uint256 nftId, uint256 class_, uint256 inId);
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

    function mint(address to_, uint256 class_, uint256 id_) public onlyMinter whenNotPaused returns (bool) {
        _mintNum ++;
        require(_totalSupply >= _mintNum, "mint number is insufficient");
        require(idNft[id_] == 0, "not minted");
        SSRMap[_mintNum].id = _mintNum;
        SSRMap[_mintNum].class = class_;
        SSRMap[_mintNum].state = 1;
        _safeMint(to_, _mintNum);
        emit Mint(to_, _mintNum, class_, id_);
        idNft[id_] = _mintNum;
        return true;
    }

    function batchMint(address to_, uint256[] calldata amount_, uint256 class_) public onlyMinter whenNotPaused returns (bool) {
        for (uint256 i = 0; i < amount_.length; i++) {
            mint(to_, class_, amount_[i]);
        }

        return true;
    }

    function updateClass(uint256 SSRID_, uint256 class_) public onlyMinter whenNotPaused returns (bool) {
        require(SSRMap[SSRID_].id != 0, "SSRNFT not exist");
        SSRMap[SSRID_].class = class_;
        return true;
    }


    function burn(uint256 SSRID_) public whenNotPaused {
        require(SSRMap[SSRID_].id != 0, "SSRNFT not exist");
        address owner = ownerOf(SSRID_);
        require(
            _msgSender() == owner ||
            _msgSender() == getApproved(SSRID_) ||
            isApprovedForAll(owner, _msgSender()) ||
            minters[_msgSender()] == true,
            "burn caller is not owner nor approved"
        );
        SSRMap[SSRID_].state = 2;
        _burnNum ++;
        _burn(SSRID_);
    }

    /** set totalSupply */
    function setTotalSupply(uint256 totalSupply_) public onlyOwner {
        require(totalSupply_ >= _mintNum, "mint number is insufficient");
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

    /** get SSRURL */
    function getSSRURL(uint256 SSRID_) public view returns (string memory) {
        require(SSRMap[SSRID_].id != 0, "SSRNFT not exist");
        return string(abi.encodePacked(_baseURL, SSRID_.toString()));
    }

    /** get class */
    function getClass(uint256 SSRID_) public view returns (uint256) {
        return SSRMap[SSRID_].class;
    }

    /** get state */
    function getState(uint256 SSRID_) public view returns (uint8) {
        return SSRMap[SSRID_].state;
    }

    /** get SSRStruct */
    function getSSR(uint256 SSRID_) public view returns (SSRStruct memory){
        return SSRMap[SSRID_];
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
