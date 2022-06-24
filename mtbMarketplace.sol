// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./token/mtbERC721Token.sol";
import "./libs/mtbCollections.sol";
import "./libs/mtbOrders.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
contract MetaInBoxMarketPlace is AccessControlUpgradeable,
                        MetaInBoxCommon,
                        MetaInBoxOrder,
                        MetaInBoxCollection,
                        IERC721ReceiverUpgradeable,ReentrancyGuardUpgradeable{

    MetaInBoxToken private token;
    Fee private payee;
    using SafeMathUpgradeable for uint;
    using AddressUpgradeable for address;
    struct ItemForSale{
        uint256 id;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool isSold;
    }

    ItemForSale[] public itemsForSale;
    
    mapping(uint256 => bool) public activeItems; // tokenId => ativo?

    event loglistforsale(uint256 orderId,
                        uint256 tokenId, 
                        uint256 collectionId, 
                        uint256 price,
                        string collectionName,
                        string metadataCollection,
                        address seller);
    event logtransfer(uint256 tokenId,
                      address from,
                      address to,
                      bytes32 signature);
    event logbought(uint256 orderId,
                  uint256 tokenId,
                  address asker,
                  address bidder,
                  address signer,
                  uint256 price,
                  uint256 sent,
                  bytes32 signature);
    event logcancel(address sender,uint256 tokenId,uint256 orderId);
    event logsign(address signer,string sign0,bytes32 sign1,bytes32 sign2,string sign3);
    event addedSigner(address sender,address signer);
    event deletedSigner(address sender,address signer);
    modifier isAdmin(bytes32 iRrole) {
        require(hasRole(iRrole, msg.sender), "Permission denied");
        _;
    }
    function initialize(MetaInBoxToken _token) initializer public {
      token = _token;
      __AccessControl_init();
      __ReentrancyGuard_init();
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      //collection= _collection;
    }
    /*
    modifier OnlyAssetOwner(uint256 tokenId){
      require(token.ownerOf(tokenId) == msg.sender, "Sender does not own the item");
      _;
    }
    modifier orderExist(uint256 id){
      require(existsOrder(id), "Could not find order");
      _;
    }
    modifier hasOrderKeys(uint256 tokenId){
      require(getOrderKeys(tokenId).length!=uint256(0), "Cound not found order key");
      _;
    }
    modifier IsForSale(uint256 orderId,uint256 tokenId){
      require(getOrderStatus(orderId) != ORDERSTATUS.COMPLETED, "Asset is already sold");
      require(getActiviate(tokenId)==true, "Asset is not ready for sale");
      _;
    }
    */
    modifier HasTransferApproval(address approved,uint256 tokenId){
      require(token.getApproved(tokenId) == approved, "Market is not approved");
      _;
    }
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    /*
    function ListForSell(SellInfo calldata _sellAsset,
                        CollectionData calldata collectionData,
                        Sig calldata _sig)
    OnlyAssetOwner(_sellAsset.tokenId)
    HasTransferApproval(address(this),_sellAsset.tokenId)
      external 
      returns (uint256){
        address signer = ecrecover(
          keccak256(
            abi.encodePacked(
              "\x19Ethereum Signed Message:\n32", 
              keccak256(
                abi.encodePacked(
                  collectionData.collectionId,
                  collectionData.owner,
                  msg.sender,
                  "META IN BOX")))), 
                  _sig.v, 
                  _sig.r, 
                  _sig.s);
        require(hasRole(SIGNER_ROLE,signer),"Unknow Signer");
        uint256 curCollectionId=collectionData.collectionId;
        uint256 curOrder=_sellAsset.orderId;
        
        if(!existsCollectionByIndex(curCollectionId)){
          //判断没有collection
          createCollection(
          collectionData.collectionId,
          collectionData.name,
          collectionData.owner,
          collectionData.metadata,
          collectionData.fee);
        }
        if(!existsOrder(curOrder)){
          //Order不存在
          curOrder = createOrder(payable(msg.sender),
                                _sellAsset.price,
                                _sellAsset.tokenId,
                                curCollectionId, 
                                collectionData.fee,
                                payee);
        }
        emit loglistforsale(curOrder,
        _sellAsset.tokenId,
        curCollectionId,
        _sellAsset.price,
        collectionData.name,
        collectionData.metadata,
        msg.sender);
        return curOrder;
    }
    */
    /*
    function CancelSale(uint256 tokenId,
    uint256 orderId)
    OnlyAssetOwner(tokenId)
    IsForSale(orderId,tokenId)
    orderExist(orderId)
    hasOrderKeys(tokenId)
    external
    {
      
      delete OrderKeys[tokenId];  //删除KEY
      delete Orders[orderId];     //删除订单
      activateSales[tokenId]=false;

      emit logcancel(msg.sender,tokenId,orderId);
    
    }
  
    function transferAsset(
    uint256 tokenId,
    address to,
    Sig calldata _sig)
    OnlyAssetOwner(tokenId)
    external
    {
      address signer = ecrecover(
        keccak256(
          abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", 
            keccak256(
              abi.encodePacked(
                msg.sender,
                to,
                "META IN BOX")))), 
                _sig.v, 
                _sig.r, 
                _sig.s);
      require(hasRole(SIGNER_ROLE,signer),"Unknow Signer");

      uint256 curTokenId=tokenId;
      activateSales[curTokenId]=false;
      delete OrderKeys[curTokenId];  //删除KEY

      uint256[] memory orderId = getOrderKeys(curTokenId);
      if(orderId.length!=0){
        delete Orders[orderId[0]];     //删除订单
      }
      token.changeAssetOwner(curTokenId,to);//修改结构里的owner;
      token.safeTransferFrom(msg.sender,to, curTokenId);//授权给别人

      bytes32 logtransfersign = keccak256(abi.encodePacked(curTokenId,msg.sender,to));
      
      emit logtransfer(curTokenId,msg.sender,to,logtransfersign);//调用event

    }
    */
    function MatchOrder(OrderData calldata order,
    Fee calldata creatorFee,
    Sig calldata _sig) 
      HasTransferApproval(address(this),order.tokenId)
      payable
      nonReentrant
      external 
    {
        address signer = ecrecover(
          keccak256(
            abi.encodePacked(
              "\x19Ethereum Signed Message:\n32", 
              keccak256(
                abi.encodePacked(order.orderId,
                  order.tokenId,
                  order.collectionId,
                  order.asker,
                  creatorFee.recipient,
                  creatorFee.value,
                  msg.sender,
                  "META IN BOX")))),
                   _sig.v, 
                   _sig.r,
                   _sig.s);
        require(hasRole(SIGNER_ROLE,signer),"Unknow Signer");//check signer permission
        require(order.asker != signer, "Unknow seller");//check signer
        require(token.ownerOf(order.tokenId) != msg.sender, "Sender have owned this asset");
        require(msg.sender.isContract()==false,"buyer can not be a contract");
        //require(order.bidder==msg.sender,"You can not buy this asset");
        require(token.ownerOf(order.tokenId) == order.asker, "owner of NFT error");

        require(msg.value >= order.askprice && msg.value>=token.getPrice(order.tokenId), "Not enough funds sent");//no enough
        require(msg.sender != order.asker,"you could not buy asset by youself");//
        
        //token.changeAssetOwner(order.tokenId,msg.sender);//disabled

        //token.safeTransferFrom(address(this), msg.sender, oldOrder.assetId);
        token.safeTransferFrom(order.asker,msg.sender, order.tokenId);//transfer
        uint creatorvalue = msg.value.mul(creatorFee.value).div(1000);
        uint servicevalue = msg.value.mul(payee.value).div(1000);
        uint sellvalue = msg.value-creatorvalue-servicevalue;
        require(creatorvalue>=0&&servicevalue>=0&&sellvalue>0,"Error caused by payment");

        payable(order.asker).transfer(sellvalue);//transfer value to seller
        payee.recipient.transfer(servicevalue);// transfer value to NFTMarketplace
        creatorFee.recipient.transfer(creatorvalue);//transfer value to creator

        createOrder(payable(order.asker),
                                order.askprice,
                                order.tokenId,
                                order.collectionId, 
                                creatorFee,
                                payee); //just created as data query
        bytes32 logsignature = keccak256(abi.encodePacked(order.tokenId,
        order.orderId,
        order.collectionId,
        order.asker,
        msg.sender));

        emit logbought(order.orderId,
        order.tokenId,
        order.asker,
        msg.sender,
        signer,
        order.askprice,
        msg.value,
        logsignature);
    }
    function addNewSigner(address newSigner) public isAdmin(DEFAULT_ADMIN_ROLE){
      grantRole(SIGNER_ROLE,newSigner);
      emit addedSigner(msg.sender,newSigner);
    }
    function deleteSigner(address signer) public isAdmin(DEFAULT_ADMIN_ROLE){
      revokeRole(SIGNER_ROLE,signer);
      emit deletedSigner(msg.sender, signer);
    }
    function setServiceFee(uint256 fee,address payable marketplacePayee) public isAdmin(DEFAULT_ADMIN_ROLE){
      require(fee<100,"Can not set fee over 10%");
      require(marketplacePayee!=address(0x0),"address can not be address(0)");
      payee.recipient=marketplacePayee;
      payee.value=fee;
    }
}