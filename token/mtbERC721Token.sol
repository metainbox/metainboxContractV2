// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../libs/mtbCommon.sol";

contract MetaInBoxToken is ERC721EnumerableUpgradeable,AccessControlUpgradeable,MetaInBoxCommon,OwnableUpgradeable{

    using CountersUpgradeable for CountersUpgradeable.Counter;
    
    CountersUpgradeable.Counter private _tokenIds;

    address public marketplace_address;

    struct Asset{
        uint256 tokenId;
        uint256 index;
        address creator;
        address owner;
    }

    mapping(uint256 => Asset) private Assets;
    mapping(uint256 => string) private Uris;
    mapping(uint256 => uint256) private indexes;
    mapping(uint256 => uint256) public lastPrices;

    event addedSigner(address sender,address signer);
    event deletedSigner(address sender,address signer);
    event burnAsset(address owner, uint256 tokenId);
    event minted(address creator,address owner,uint256 tokenId,string uri);
    event approvalMarket(address from,address to,uint256 tokenId,uint256 price,string myevent);
    event mytransferFrom(address from,address to,uint256 tokenId);

    using AddressUpgradeable for address;

    modifier isExists(uint256 tokenId){
        require(_exists(tokenId),"ERC721: operator query for nonexistent token");
        _;
    }
    modifier isAdmin(bytes32 iRrole) {
        require(hasRole(iRrole, msg.sender), "Administrator Permission denied");
        _;
    }
    modifier isApprovedOrOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender,tokenId),"You do not own or approved this asset");
        _;
    }
    modifier OnlyMarketplace() {
        require(marketplace_address !=address(0x0),"please set marketplace first");
        require(marketplace_address==msg.sender,"marketplace Permission denied");
        _;
    }
    modifier isOnwer(address user,uint256 tokenId){
        require(ownerOf(tokenId)==user,"you do not own this asset");
        _;
    }
    function getPrice(uint256 tokenId)public view returns(uint256){
        return lastPrices[tokenId];
    }
    function tokenExists(uint256 tokenId) public view returns(bool){
        return _exists(tokenId);
    }
    function initialize() initializer public {
        __ERC721_init("METAINBOX Marketplace","MTBT");
        __ERC721Enumerable_init();
        __AccessControl_init();
        __Ownable_init();
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);/*Only publisher set admin role*/

    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721EnumerableUpgradeable,AccessControlUpgradeable) returns (bool) {
        
        return super.supportsInterface(interfaceId);

    }
    /* Every Body can mint */
    function getAssetByTokenId(uint256 tokenId) public view returns(Asset memory){

        return Assets[tokenId];

    }
    function getAssetByindex(uint256 index) public view returns(Asset memory){

        return Assets[indexes[index]];

    }
    function getTokenIdByindex(uint256 index) public view returns(uint256){

        return indexes[index];

    }
    function mint(uint256 index,
    string memory uri,
    Sig calldata _sig,
    uint256 price) public returns(uint256){
        
        address signer = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32", 
                    keccak256(
                        abi.encodePacked(
                            index,
                            msg.sender,
                            "META IN BOX")))), 
                            _sig.v, 
                            _sig.r, 
                            _sig.s);
        require(hasRole(SIGNER_ROLE,signer),"Unknow Signer");
        require(marketplace_address !=address(0x0),"please set marketplace first");
        require(price>0,"price must be more than 0 wei");
        _tokenIds.increment();
        uint256 curTokenId = _tokenIds.current();
        _safeMint(msg.sender, curTokenId);        
        //approve(marketplace_address, curTokenId);

        Assets[curTokenId]= Asset({
            tokenId: curTokenId,
            creator: msg.sender,
            index:index,
            owner:msg.sender
        });

        Uris[curTokenId]=uri;
        indexes[index]=curTokenId;
        lastPrices[curTokenId]=price;
        emit minted(msg.sender,msg.sender,curTokenId,uri);
        return curTokenId;

    }
    function approvedMarket(address to,uint256 tokenId,uint256 price,string memory myevent) public{
        require(price>0,"price must be more than 0 wei");
        approve(to, tokenId);
        if(to==address(0x0) || to != marketplace_address){
        //if approve to address(0) or other marketplace means the user cancel sale so we set max 100000000 ETH to the price nobody can buy this nft in this marketplace
            lastPrices[tokenId]=uint256(100000000000000000000000000);
        }
        lastPrices[tokenId]=price;
        emit approvalMarket(msg.sender,to,tokenId,price,myevent);
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory){

        require(_exists(tokenId),"ERC721URIStorage: URI query for nonexistent token");
        return Uris[tokenId];

    }
    /*
    //disabled
    function changeAssetOwner(uint256 tokenId,address newOwner) public 
    isExists(tokenId) 
    OnlyMarketplace {
        Asset memory oldAsset = Assets[tokenId];
        oldAsset.owner=newOwner;
        Assets[tokenId]=oldAsset;
    }
    */
    function changeURI(uint256 tokenId,string memory uri) public 
    isExists(tokenId) 
    OnlyMarketplace{
        Uris[tokenId]=uri;
    }

    function BurnToken(address user,uint256 tokenId) public 
    isExists(tokenId) 
    isOnwer(msg.sender,tokenId){//owner of Token can burn this NFT
        require(msg.sender==user,"error sender");
        require(getApproved(tokenId)==address(this),"User Permission denied");
        _burn(tokenId);
        delete Assets[tokenId];
        delete Uris[tokenId];

        emit burnAsset(user,tokenId);
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable)
    {
        super.safeTransferFrom(from,to,tokenId);
        emit mytransferFrom(from,to,tokenId);
    }
    function addNewSigner(address newSigner) public isAdmin(DEFAULT_ADMIN_ROLE){
      grantRole(SIGNER_ROLE,newSigner);
      emit addedSigner(msg.sender,newSigner);
    }
    function deleteSigner(address signer) public isAdmin(DEFAULT_ADMIN_ROLE){
      revokeRole(SIGNER_ROLE,signer);
      emit deletedSigner(msg.sender, signer);
    }
    function setMarketPlace(address newMarket) public isAdmin(DEFAULT_ADMIN_ROLE){
        require(newMarket!=address(0x0),"Marketplace can not be address(0)");
        require(newMarket.isContract(),"Marketplace address must be a contract");
        marketplace_address=newMarket;
    }
}