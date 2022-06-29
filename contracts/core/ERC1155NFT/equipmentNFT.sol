//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../openzeppelin/contracts/access/Ownable.sol";
import "../openzeppelin/contracts/security/Pausable.sol";
import "../openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Equipment NFT 
 */
contract equipment is Ownable, ERC1155, Pausable {
    using  Strings for uint256;
    string private _name;
    string private _symbol;
    string private _baseURL;

    mapping(address => bool) private minters;
    modifier onlyMinter() {
        require(
            minters[_msgSender()], 
            "Mint: caller is not the minter"
        );
        _;
    }

    struct Equipment {
        uint256  id;
        string   equipName;
        uint256  class;
        uint256  mintNum;
        uint256  burnNum;
        uint256  totalSupply;
    }

    mapping(uint => Equipment) public equipmentMap;

    constructor(string memory url_) ERC1155(url_) {
        _name = "Equipment NFT";
        _symbol = "ENFT";
        _baseURL = url_;
        minters[_msgSender()] = true;
    }

    function newEquipment(
        uint256 equipmentID_, 
        string  memory equipName_, 
        uint256 class_, 
        uint256 totalSupply_
    ) 
        public 
        onlyOwner 
    {
        require(equipmentID_ > 0 && equipmentMap[equipmentID_].id == 0, "Equipment id invalid");
        equipmentMap[equipmentID_] = Equipment({
            id: equipmentID_,
            equipName: equipName_,
            class: class_,
            mintNum: 0,
            burnNum: 0,
            totalSupply: totalSupply_
        });
    }

    function updateEquipment(
        uint256 equipmentID_, 
        string  memory equipName_, 
        uint256 class_, 
        uint256 totalSupply_
    ) 
        public 
        onlyOwner 
    {
        require(equipmentID_ > 0 && equipmentMap[equipmentID_].id == equipmentID_, "id invalid");
        require(totalSupply_ >= equipmentMap[equipmentID_].mintNum, "totalSupply err");

        equipmentMap[equipmentID_] = Equipment({
            id: equipmentID_,
            equipName: equipName_,
            class: class_,
            mintNum: equipmentMap[equipmentID_].mintNum,
            burnNum: equipmentMap[equipmentID_].burnNum,
            totalSupply: totalSupply_
        });
    }
	
    function mint(
        address to_, 
        uint256 equipmentID_, 
        uint256 num_
    ) 
        public 
        onlyMinter 
        whenNotPaused 
        returns (bool) 
    {
        require(num_ > 0, "mint number err");
        require(equipmentMap[equipmentID_].id != 0, "Equipment id err");
        require(equipmentMap[equipmentID_].totalSupply >= equipmentMap[equipmentID_].mintNum + num_, "mint number is insufficient");

        equipmentMap[equipmentID_].mintNum += num_;
        _mint(to_, equipmentID_, num_, "");
        return true;
    }

    function mintBatch(
        address to_, 
        uint256[] memory EquipmentIDs_, 
        uint256[] memory nums_
    ) 
        public 
        onlyMinter 
        whenNotPaused 
        returns (bool) 
    {
        require(EquipmentIDs_.length == nums_.length, "array length unequal");

        for (uint i = 0; i < EquipmentIDs_.length; i++) {
            require(equipmentMap[EquipmentIDs_[i]].id != 0, "Equipment id err");
            require(
                equipmentMap[EquipmentIDs_[i]].totalSupply >= equipmentMap[EquipmentIDs_[i]].mintNum + nums_[i], 
                "mint number is insufficient"
            );
            equipmentMap[EquipmentIDs_[i]].mintNum += nums_[i];
        }

        _mintBatch(to_, EquipmentIDs_, nums_, "");
        return true;
    }

    function burn(
        address from_, 
        uint256 equipmentID_, 
        uint256 num_
    ) 
        public 
        whenNotPaused 
    {
        require(equipmentMap[equipmentID_].id != 0, "Equipment id err");
        require(_msgSender() == from_ || isApprovedForAll(from_, _msgSender()), "burn caller is not owner nor approved");
        equipmentMap[equipmentID_].burnNum += num_;
        _burn(from_, equipmentID_, num_);
    }

    function burnBatch(
        address   from_, 
        uint256[] memory EquipmentIDs_, 
        uint256[] memory nums_
    ) 
        public 
        whenNotPaused 
    {
        require(_msgSender() == from_ || isApprovedForAll(from_, _msgSender()), "burn caller is not owner nor approved");
        require(EquipmentIDs_.length == nums_.length, "array length unequal");
        for (uint i = 0; i < EquipmentIDs_.length; i++) {
            require(equipmentMap[EquipmentIDs_[i]].id != 0, "Equipment id err");
            equipmentMap[EquipmentIDs_[i]].burnNum += nums_[i];
        }
        
        _burnBatch(from_, EquipmentIDs_, nums_);
    }

    /** set minters */
    function setMinter(address newMinter, bool power) public onlyOwner {
        minters[newMinter] = power;
    }

    /** be minter or not */		
    function isMinter(address minter_) public view returns (bool){
        return minters[minter_];
    }

    /** get EquipmentURL */
    function EquipmentURL(uint equipmentID_) public view returns (string memory) {
        require(equipmentMap[equipmentID_].id != 0, "Equipment not exist");
        return string(abi.encodePacked(_baseURL, equipmentID_.toString()));
    }

    /** set baseURL */
    function setURL(string memory newURL_) public onlyOwner {
        _baseURL = newURL_;
    }
	
    /** get baseURL */
    function baseURL() public view returns (string memory){
        return _baseURL;
    }
	
    /** get name */
    function name() public view returns (string memory){
        return _name;
    }
		
    /** get symbol */
    function symbol() public view returns (string memory){
        return _symbol;
    }
	
    /** get Equipment */
    function getEquipment(uint256 equipmentID_) public view returns (Equipment memory){
        return equipmentMap[equipmentID_];
    }

    /** set state */
    function setPause(bool isPause) public onlyOwner {
        if (isPause) {
            _pause();
        } else {
            _unpause();
        }
    }

}
