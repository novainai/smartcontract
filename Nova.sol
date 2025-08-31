// SPDX-License-Identifier: MIT
pragma solidity >0.4.0 <= 0.9.0;

interface ITokenStandard {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address receiver, uint256 value) external returns (bool);
    function allowance(address owner, address delegate) external view returns (uint256);
    function approve(address delegate, uint256 value) external returns (bool);
    function transferFrom(address sender, address receiver, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed delegate, uint256 value);
    event Burn(address indexed burner, uint256 value);
}

contract Nova is ITokenStandard {
    string public name = "Nova";
    string public symbol = "NOVA";
    uint8 public decimals = 18;
    uint256 public tokenTotalSupply = 210000;
    address private tokenOwner;

    mapping(address => uint256) private accountBalances;
    mapping(address => mapping(address => uint256)) private spendingAllowances;

    constructor() {
        tokenTotalSupply = tokenTotalSupply * 10**uint256(decimals);
        accountBalances[msg.sender] = tokenTotalSupply;
        tokenOwner = msg.sender;
        emit Transfer(address(0), msg.sender, tokenTotalSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return tokenTotalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return accountBalances[account];
    }

    function transfer(address receiver, uint256 value) external override returns (bool) {
        executeTransfer(msg.sender, receiver, value);
        return true;
    }

    function allowance(address owner, address delegate) external view override returns (uint256) {
        return spendingAllowances[owner][delegate];
    }

    function approve(address delegate, uint256 value) external override returns (bool) {
        grantApproval(msg.sender, delegate, value);
        return true;
    }

    function transferFrom(address sender, address receiver, uint256 value) external override returns (bool) {
        executeTransfer(sender, receiver, value);
        grantApproval(sender, msg.sender, spendingAllowances[sender][msg.sender] - value);
        return true;
    }

    function executeTransfer(address sender, address receiver, uint256 value) private {
        require(sender != address(0), "Cannot transfer from zero address");
        require(receiver != address(0), "Cannot transfer to zero address");
        require(accountBalances[sender] >= value, "Not enough balance");

        accountBalances[sender] -= value;
        accountBalances[receiver] += value;
        emit Transfer(sender, receiver, value);
    }

    function grantApproval(address owner, address delegate, uint256 value) private {
        require(owner != address(0), "Cannot approve from zero address");
        require(delegate != address(0), "Cannot approve to zero address");

        spendingAllowances[owner][delegate] = value;
        emit Approval(owner, delegate, value);
    }

    function getOwner() external view override returns (address) {
        return tokenOwner;
    }

    function burn(uint256 value) external {
        require(accountBalances[msg.sender] >= value, "Cannot burn more than balance");
        
        accountBalances[msg.sender] -= value;
        tokenTotalSupply -= value;
        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
    }

    function renounceOwnership() external {
        require(msg.sender == tokenOwner, "Only owner can renounce");
        tokenOwner = address(0);
    }
}