// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
abstract contract  MetaInBoxCommon is Initializable{
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant NORMAL_ROLE = keccak256("NORMAL_ROLE");
    struct Fee{
        address payable recipient;
        uint256 value;
    }
    enum ORDERSTATUS{ NONE, SELLING, COMPLETED,CLOSE }

    struct Sig{
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    struct OrderData{
        uint256 orderType;
        uint256 orderId;
        uint256 tokenId;
        string collectionName;
        uint256 collectionId;
        address asker;
        uint256 askprice;
        address bidder;
    }
    struct SellInfo{
        uint256 orderId;
        uint256 index;
        uint256 tokenId;
        uint256 price;
    }
    
    struct CollectionData{
        uint256 collectionId;
        string name;
        string metadata;
        address owner;
        Fee fee;
    }
}