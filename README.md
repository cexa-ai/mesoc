# Mesoc Payment Contract

Open-source Solidity payment contract used by [Mesoc](https://github.com/cexa-ai) for on-chain payments (native coin + ERC-20).

> Source of truth in monorepo historically lived at `ai-agent/contracts/contracts/PaymentContractV2.sol`.  
> Contract name on-chain: **`PaymentContract`** (V2 implementation).

## Features

- Native coin payments (`token = address(0)`, default BNB on BSC)
- ERC-20 payments via `addSupportedToken(...)` (e.g. USDT)
- Emits `PaymentReceived(payer, token, amount, paymentSn)` for off-chain indexers
- Owner withdraw, pause / unpause, per-token minimum amount

## Contract

- [`contracts/PaymentContractV2.sol`](./contracts/PaymentContractV2.sol)

Dependencies (OpenZeppelin):

- `Ownable`
- `ReentrancyGuard`
- `Pausable`
- `IERC20` / `SafeERC20`

Solidity: `^0.8.19`  
SPDX: `MIT`

## Deployments (public)

| Network | Chain ID | PaymentContract |
|---------|----------|-----------------|
| BSC Mainnet | 56 | [`0x19cb281e4ff3b9941418f0df6f5817abe4ec2a07`](https://bscscan.com/address/0x19cb281e4ff3b9941418f0df6f5817abe4ec2a07) |
| BSC Testnet | 97 | [`0xA67f135E196f1d535d981C69210f5A084520F009`](https://testnet.bscscan.com/address/0xA67f135E196f1d535d981C69210f5A084520F009) |

## Core API

```solidity
function pay(address token, uint256 amount, string calldata paymentSn) external payable;

function addSupportedToken(address token, uint8 decimals, string calldata symbol, uint256 minAmount) external;
function removeSupportedToken(address token) external;
function updateTokenMinAmount(address token, uint256 newMinAmount) external;

function withdraw(address token, uint256 amount) external;
function pause() external;
function unpause() external;
```

Native payments: pass `token = address(0)`, `amount = 0`, and send `msg.value`.  
ERC-20 payments: approve this contract first, then call `pay(token, amount, paymentSn)` with `msg.value = 0`.

## Security notes

- Fee-on-transfer tokens are rejected (`paidAmount == amount` check).
- Native token config (`address(0)`) is initialized in the constructor and cannot be removed via `removeSupportedToken`.
- Only `owner` can withdraw funds and manage token allowlist.

## Disclaimer

This repository publishes the payment contract for transparency. Always audit and verify bytecode against the deployed address before integrating in production.
