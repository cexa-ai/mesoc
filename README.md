# PaymentContract (V2)

Solidity payment contract for on-chain checkout: native coin (BNB on BSC) and ERC-20 (e.g. USDT).

On-chain name: **`PaymentContract`**

## Features

- Native coin payments (`token = address(0)`)
- ERC-20 payments via `addSupportedToken(...)`
- Emits `PaymentReceived(payer, token, amount, paymentSn)`
- Owner withdraw, pause / unpause, per-token minimum amount

## Contract

- [`contracts/PaymentContractV2.sol`](./contracts/PaymentContractV2.sol)

Dependencies (OpenZeppelin): `Ownable`, `ReentrancyGuard`, `Pausable`, `IERC20` / `SafeERC20`

Solidity: `^0.8.19`  
SPDX: `MIT`

## Deployed addresses

| Network | Chain ID | Address |
|---------|----------|---------|
| BSC Mainnet | 56 | [`0x19cb281e4ff3b9941418f0df6f5817abe4ec2a07`](https://bscscan.com/address/0x19cb281e4ff3b9941418f0df6f5817abe4ec2a07) |
| BSC Testnet | 97 | [`0xA67f135E196f1d535d981C69210f5A084520F009`](https://testnet.bscscan.com/address/0xA67f135E196f1d535d981C69210f5A084520F009) |

## API

```solidity
function pay(address token, uint256 amount, string calldata paymentSn) external payable;

function addSupportedToken(address token, uint8 decimals, string calldata symbol, uint256 minAmount) external;
function removeSupportedToken(address token) external;
function updateTokenMinAmount(address token, uint256 newMinAmount) external;

function withdraw(address token, uint256 amount) external;
function pause() external;
function unpause() external;
```

Native: `token = address(0)`, `amount = 0`, send `msg.value`.  
ERC-20: approve this contract, then `pay(token, amount, paymentSn)` with `msg.value = 0`.

## Notes

- Fee-on-transfer tokens are rejected.
- Native token config (`address(0)`) is set in the constructor.
- Only `owner` can withdraw and manage the token allowlist.
