// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MyToken is ERC20, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Item {
        string name;
        uint256 price;
    }

    mapping(uint256 => Item) public shopItems;
    uint256 public nextItemId;

    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public stakingRewards;
    uint256 public rewardRate;

    constructor(address initialOwner) ERC20("Degen", "DGN") Ownable(initialOwner) {
        // Mint initial supply to the contract deployer
        _mint(msg.sender, 10 * 10 ** decimals());
        rewardRate = 100; // Example reward rate
        nextItemId = 1;
        addItem("Rare Sword", 50);
        addItem("Legendary Armor", 100);
        addItem("Epic Potion", 200);
        addItem("Common Scroll", 10);
    }

    modifier onlyWhenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    function mint(address account, uint256 amount) public onlyOwner whenNotPaused {
        _mint(account, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override onlyWhenNotPaused returns (bool) {
        require(amount <= balanceOf(msg.sender), "Insufficient balance");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function redeem(uint256 itemId) public nonReentrant whenNotPaused {
        Item memory item = shopItems[itemId];
        require(item.price > 0, "Item does not exist");
        require(balanceOf(msg.sender) >= item.price, "Insufficient balance to redeem item");
        _burn(msg.sender, item.price);
        // Logic to transfer item to user can be added here
    }

    function burn(uint256 amount) public whenNotPaused {
        require(amount <= balanceOf(msg.sender), "Insufficient balance");
        _burn(msg.sender, amount);
    }

    function stake(uint256 amount) public whenNotPaused {
        require(amount <= balanceOf(msg.sender), "Insufficient balance to stake");
        _transfer(msg.sender, address(this), amount);
        stakedBalances[msg.sender] = stakedBalances[msg.sender].add(amount);
        stakingRewards[msg.sender] = stakingRewards[msg.sender].add(amount.mul(rewardRate).div(10000));
    }

    function unstake(uint256 amount) public nonReentrant whenNotPaused {
        require(stakedBalances[msg.sender] >= amount, "Insufficient staked balance");
        stakedBalances[msg.sender] = stakedBalances[msg.sender].sub(amount);
        _transfer(address(this), msg.sender, amount);
    }

    function claimRewards() public nonReentrant whenNotPaused {
        uint256 reward = stakingRewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        stakingRewards[msg.sender] = 0;
        _mint(msg.sender, reward);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function emergencyWithdraw() public onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        _transfer(address(this), owner(), contractBalance);
    }

    function addItem(string memory name, uint256 price) public onlyOwner {
        shopItems[nextItemId] = Item(name, price);
        nextItemId++;
    }

    function updateItem(uint256 itemId, string memory name, uint256 price) public onlyOwner {
        require(shopItems[itemId].price > 0, "Item does not exist");
        shopItems[itemId] = Item(name, price);
    }

    function removeItem(uint256 itemId) public onlyOwner {
        require(shopItems[itemId].price > 0, "Item does not exist");
        delete shopItems[itemId];
    }

    function getBalance() external view returns (uint256) {
        return balanceOf(msg.sender);
    }
}
