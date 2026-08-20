# PaymentContract (V2)

Open-source Solidity payment contract for on-chain checkout (BNB native coin + ERC-20 such as USDT).

> On-chain contract name: **`PaymentContract`**  
> Source in monorepo: `ai-agent/contracts/contracts/PaymentContractV2.sol`

## Where it is used

This contract is **not** the Mesoc red-packet / wallet transfer path.

In the current codebase it is wired for:

- **Vision / Luflux membership** on-chain pay (`vision/luflux` → `getPaymentContractAddress` / `membership-onchain-pay`)
- **Claw billing** (`claw/api` billing → payment contract address)
- **CoreService** payment indexer (`PaymentReceived(paymentSn)` via `payment-contracts.json`)

Mesoc server code does **not** reference this contract.

## Features

- Native coin payments (`token = address(0)`, symbol `BNB` on BSC)
- ERC-20 payments via `addSupportedToken(...)` (e.g. USDT)
- Emits `PaymentReceived(payer, token, amount, paymentSn)` for off-chain indexers
- Owner withdraw, pause / unpause, per-token minimum amount

## Contract

- [`contracts/PaymentContractV2.sol`](./contracts/PaymentContractV2.sol)

Dependencies (OpenZeppelin): `Ownable`, `ReentrancyGuard`, `Pausable`, `IERC20` / `SafeERC20`

Solidity: `^0.8.19`  
SPDX: `MIT`

## Deployed addresses (public)

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

Native: `token = address(0)`, `amount = 0`, send `msg.value`.  
ERC-20: approve this contract, then `pay(token, amount, paymentSn)` with `msg.value = 0`.

## Security notes

- Fee-on-transfer tokens are rejected (`paidAmount == amount`).
- Native token config (`address(0)`) is set in the constructor and cannot be removed via `removeSupportedToken`.
- Only `owner` can withdraw and manage the token allowlist.

## Disclaimer

Published for transparency. Verify on-chain bytecode against the deployed address before production use.
