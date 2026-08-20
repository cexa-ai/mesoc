// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PaymentContract is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    struct TokenConfig {
        bool isSupported;
        uint8 decimals;
        string symbol;
        uint256 minAmount;
    }

    mapping(address => TokenConfig) public supportedTokens;

    event TokenAdded(address indexed token, string symbol, uint8 decimals, uint256 minAmount);
    event TokenRemoved(address indexed token, string symbol);
    event MinAmountUpdated(address indexed token, uint256 oldMinAmount, uint256 newMinAmount);

    event PaymentReceived(
        address indexed payer,
        address indexed token,
        uint256 amount,
        string paymentSn
    );

    event Withdraw(address indexed admin, address indexed token, uint256 amount, uint256 timestamp);

    constructor(address initialOwner) Ownable(initialOwner) {
        supportedTokens[address(0)] = TokenConfig({
            isSupported: true,
            decimals: 18,
            symbol: "BNB",
            minAmount: 0.0001 ether
        });

        emit TokenAdded(address(0), "BNB", 18, 0.0001 ether);
    }

    function pay(
        address token,
        uint256 amount,
        string calldata paymentSn
    ) external payable nonReentrant whenNotPaused {
        require(bytes(paymentSn).length > 0, "payment_sn cannot be empty");
        require(supportedTokens[token].isSupported, "Token not supported");

        uint256 paidAmount;

        if (token == address(0)) {
            require(msg.value > 0, "Payment amount must be greater than 0");
            require(msg.value >= supportedTokens[address(0)].minAmount, "Amount below minimum");
            require(amount == 0, "Amount should be 0 for native payment");
            paidAmount = msg.value;
        } else {
            require(msg.value == 0, "Native token not needed for ERC20 payment");
            require(amount > 0, "Payment amount must be greater than 0");
            require(amount >= supportedTokens[token].minAmount, "Amount below minimum");

            uint256 beforeBalance = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            uint256 afterBalance = IERC20(token).balanceOf(address(this));
            paidAmount = afterBalance - beforeBalance;
            require(paidAmount == amount, "Fee-on-transfer token not supported");
        }

        emit PaymentReceived(msg.sender, token, paidAmount, paymentSn);
    }

    function withdraw(address token, uint256 amount) external onlyOwner nonReentrant whenNotPaused {
        require(amount > 0, "Withdraw amount must be greater than 0");

        if (token == address(0)) {
            require(address(this).balance >= amount, "Insufficient contract balance");
            (bool success, ) = payable(owner()).call{ value: amount }("");
            require(success, "Native token transfer failed");
        } else {
            IERC20(token).safeTransfer(owner(), amount);
        }

        emit Withdraw(msg.sender, token, amount, block.timestamp);
    }

    function addSupportedToken(
        address token,
        uint8 decimals,
        string calldata symbol,
        uint256 minAmount
    ) external onlyOwner {
        require(token != address(0), "Cannot modify native token config");
        require(!supportedTokens[token].isSupported, "Token already supported");
        require(bytes(symbol).length > 0, "Symbol cannot be empty");
        require(minAmount > 0, "Min amount must be greater than 0");

        supportedTokens[token] = TokenConfig({
            isSupported: true,
            decimals: decimals,
            symbol: symbol,
            minAmount: minAmount
        });

        emit TokenAdded(token, symbol, decimals, minAmount);
    }

    function removeSupportedToken(address token) external onlyOwner {
        require(token != address(0), "Cannot remove native token");
        require(supportedTokens[token].isSupported, "Token not supported");

        string memory symbol = supportedTokens[token].symbol;
        supportedTokens[token].isSupported = false;

        emit TokenRemoved(token, symbol);
    }

    function updateTokenMinAmount(address token, uint256 newMinAmount) external onlyOwner {
        require(supportedTokens[token].isSupported || token == address(0), "Token not supported");
        require(newMinAmount > 0, "Min amount must be greater than 0");

        uint256 oldMinAmount = supportedTokens[token].minAmount;
        supportedTokens[token].minAmount = newMinAmount;

        emit MinAmountUpdated(token, oldMinAmount, newMinAmount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getContractBalance(address token) external view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    function getTokenConfig(address token) external view returns (TokenConfig memory) {
        return supportedTokens[token];
    }

    function isTokenSupported(address token) external view returns (bool) {
        return supportedTokens[token].isSupported;
    }

    function getTokensConfig(
        address[] calldata tokens
    ) external view returns (TokenConfig[] memory configs) {
        configs = new TokenConfig[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            configs[i] = supportedTokens[tokens[i]];
        }
    }

    receive() external payable {}

    fallback() external payable {
        revert("Function not found");
    }
}
