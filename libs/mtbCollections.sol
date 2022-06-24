// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./mtbCommon.sol";

contract MetaInBoxCollection is MetaInBoxCommon{

    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _collectionIds;
    struct Collection{
        uint256 tokenId;
        uint256 collectionId;
        string name;
        address owner;
    }
    mapping(uint256 => Fee) private fees;
    mapping(uint256 => Collection) private Collections;
    mapping(uint256 => string) private metaDatas;
    mapping(uint256 => uint256) private indexes;
/*
    address public marketplace_address = address(0x0);

    modifier isAdmin(bytes32 iRrole) {
        require(hasRole(iRrole, msg.sender), "Administrator Permission denied");
        _;
    }

    function initialize() initializer public {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
*/
    function getCollection(uint256 Id) public view returns(Collection memory){
        return Collections[Id];
    }
    function getFee(uint256 Id)public view returns(Fee memory){
        return fees[Id];
    }
    function getMetadata(uint256 Id)public view returns(string memory){
        return metaDatas[Id];
    }
    function tokenIdbyindex(uint256 index)public view returns(uint256){
        return indexes[index];
    }
    function totalCollections() public view returns(uint256){
        return _collectionIds.current();
    }
    function createCollection(uint256 id,
                                string memory name,
                                address owner,
                                string memory uri,
                                Fee calldata collectionFee) internal returns(uint256){
        
        _collectionIds.increment();
        uint256 curCollectionId = _collectionIds.current();

        Collections[curCollectionId]=Collection({
            tokenId:curCollectionId,
            collectionId:id,
            name:name,
            owner:owner
        });
        metaDatas[curCollectionId]=uri;
        fees[curCollectionId]=collectionFee;
        indexes[id]=curCollectionId;

        return curCollectionId;
    }

    function existsCollection(uint256 id) public view returns(bool){
        return Collections[id].owner != address(0x0);
    }
    function existsCollectionByIndex(uint256 index)public view returns(bool){
        return Collections[indexes[index]].owner !=address(0x0);
    }
    function existsFee(uint256 id)public view returns(bool){
        return fees[id].recipient != address(0x0);
    }
    function existsMeta(uint256 id)public view returns(bool){
        return bytes(metaDatas[id]).length>0;
    }
    function chnageMetadata(uint256 id,string memory uri) internal {
        metaDatas[id]=uri;
    }
/*
    function setMarketPlace(address newMarket) public isAdmin(DEFAULT_ADMIN_ROLE){
        marketplace_address=newMarket;
    }
*/
}