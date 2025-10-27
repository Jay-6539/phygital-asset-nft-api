// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title PhygitalAssetNFT
 * @dev NFT合约，用于铸造Phygital Asset Thread
 */
contract PhygitalAssetNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    
    Counters.Counter private _tokenIdCounter;
    
    // Thread元数据结构
    struct ThreadMetadata {
        string threadId;        // Thread唯一标识符
        string username;        // 创建者用户名
        string buildingId;     // 建筑ID
        string description;    // Thread描述
        string imageUrl;       // 图片URL
        uint256 createdAt;     // 创建时间戳
    }
    
    // 存储映射
    mapping(uint256 => ThreadMetadata) public threadMetadata;
    mapping(string => uint256) public threadIdToTokenId;
    mapping(address => uint256[]) public userTokens;
    
    // 事件
    event ThreadMinted(
        uint256 indexed tokenId, 
        string indexed threadId, 
        address indexed owner,
        string username,
        string buildingId
    );
    
    event ThreadTransferred(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        string threadId
    );
    
    // 构造函数
    constructor() ERC721("Phygital Asset Thread", "PAT") {}
    
    /**
     * @dev 铸造新的Thread NFT
     * @param _threadId Thread唯一标识符
     * @param _username 创建者用户名
     * @param _buildingId 建筑ID
     * @param _description Thread描述
     * @param _imageUrl 图片URL
     * @return tokenId 铸造的Token ID
     */
    function mintThread(
        string memory _threadId,
        string memory _username,
        string memory _buildingId,
        string memory _description,
        string memory _imageUrl
    ) public onlyOwner returns (uint256) {
        // 检查Thread是否已铸造
        require(threadIdToTokenId[_threadId] == 0, "Thread already minted");
        require(bytes(_threadId).length > 0, "Thread ID cannot be empty");
        
        // 递增Token ID
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        
        // 铸造NFT
        _safeMint(msg.sender, tokenId);
        
        // 存储元数据
        threadMetadata[tokenId] = ThreadMetadata({
            threadId: _threadId,
            username: _username,
            buildingId: _buildingId,
            description: _description,
            imageUrl: _imageUrl,
            createdAt: block.timestamp
        });
        
        // 建立映射关系
        threadIdToTokenId[_threadId] = tokenId;
        userTokens[msg.sender].push(tokenId);
        
        // 触发事件
        emit ThreadMinted(tokenId, _threadId, msg.sender, _username, _buildingId);
        
        return tokenId;
    }
    
    /**
     * @dev 获取Thread元数据
     * @param tokenId Token ID
     * @return ThreadMetadata 元数据
     */
    function getThreadMetadata(uint256 tokenId) public view returns (ThreadMetadata memory) {
        require(_exists(tokenId), "Token does not exist");
        return threadMetadata[tokenId];
    }
    
    /**
     * @dev 根据Thread ID获取Token ID
     * @param threadId Thread ID
     * @return tokenId Token ID
     */
    function getTokenIdByThreadId(string memory threadId) public view returns (uint256) {
        return threadIdToTokenId[threadId];
    }
    
    /**
     * @dev 获取用户的所有Token
     * @param user 用户地址
     * @return tokens Token ID数组
     */
    function getUserTokens(address user) public view returns (uint256[] memory) {
        return userTokens[user];
    }
    
    /**
     * @dev 获取用户Token数量
     * @param user 用户地址
     * @return count Token数量
     */
    function getUserTokenCount(address user) public view returns (uint256) {
        return userTokens[user].length;
    }
    
    /**
     * @dev 获取总铸造数量
     * @return totalSupply 总数量
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    /**
     * @dev 检查Thread是否已铸造
     * @param threadId Thread ID
     * @return exists 是否存在
     */
    function isThreadMinted(string memory threadId) public view returns (bool) {
        return threadIdToTokenId[threadId] > 0;
    }
    
    /**
     * @dev 重写转移函数，添加自定义逻辑
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        
        // 如果是转移（不是铸造），触发事件
        if (from != address(0) && to != address(0)) {
            ThreadMetadata memory metadata = threadMetadata[tokenId];
            emit ThreadTransferred(tokenId, from, to, metadata.threadId);
        }
    }
    
    /**
     * @dev 获取合约信息
     * @return contractName 合约名称
     * @return contractSymbol 合约符号
     * @return totalSupplyCount 总供应量
     * @return contractOwner 合约拥有者
     */
    function getContractInfo() public view returns (
        string memory contractName,
        string memory contractSymbol,
        uint256 totalSupplyCount,
        address contractOwner
    ) {
        return (
            name(),
            symbol(),
            totalSupply(),
            owner()
        );
    }
}
