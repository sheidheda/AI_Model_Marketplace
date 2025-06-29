# AI Model Marketplace – Decentralized ML Trading Hub

This Clarity smart contract implements a decentralized marketplace for publishing, licensing, monetizing, and reviewing AI/ML models on-chain. It aims to address the $42.1B AI token market by enabling transparent AI model trade, usage, and performance tracking within the blockchain ecosystem.

## 🔍 Overview

The marketplace allows:
- Listing AI/ML models with performance metrics
- Licensing models (single-use, subscription, unlimited)
- Performing and tracking inferences
- Submitting performance reviews
- Challenging model accuracy with evidence

## 🚀 Features

- **NFT Ownership**: Each listed model is minted as an NFT tied to the creator.
- **Staking Mechanism**: Minimum stake of 50 STX required to list a model.
- **Revenue Model**: 2.5% platform fee on license purchases; 1 STX reward for each valid review.
- **Performance Integrity**: Models must meet a minimum of 70% accuracy to be listed.
- **Transparent Licensing**: Supports single-use, subscription-based (30-day), or unlimited licenses.
- **Performance Challenges**: Users can challenge inaccurate models with evidence.

## 📦 Key Components

### Constants
- `min-model-stake`: 50 STX required to list
- `platform-fee`: 2.5% of each transaction
- `review-reward`: 1 STX to reviewers
- `performance-threshold`: 70% accuracy minimum

### Data Maps
- `ai-models`: Core registry of listed AI models
- `model-licenses`: Tracks license details per model-user pair
- `model-performance`: Aggregates performance metrics for models
- `inference-requests`: Logs usage requests
- `model-reviews`: Stores review feedback and ratings

### NFT
- `ai-model-nft`: Issued per AI model to ensure creator ownership

## 🔧 Public Functions

| Function | Description |
|----------|-------------|
| `list-model` | Lists a new AI model on the platform |
| `purchase-license` | Allows users to buy usage rights for a model |
| `request-inference` | Records an inference request using a model |
| `review-model` | Enables licensed users to review a model's quality |
| `update-model` | Creator can update the model’s hash and accuracy |
| `challenge-model` | Allows users to challenge a model's performance |

## 📊 Performance Metrics

Each model maintains:
- Total inferences
- Successful predictions
- Average latency
- Compute cost
- User rating (aggregated from reviews)

## 🔒 Access Control

- Only the creator of a model can update it.
- Only licensed users can perform inference or review.
- License validity checks include usage count and expiry block.

## 📎 Licensing Types

- `single`: One-time use
- `subscription`: 30-day period
- `unlimited`: Lifetime access

## 🧮 License Pricing Formula

Defined in `calculate-license-price`:
- `single`: Base price
- `subscription`: Base price × 100
- `unlimited`: Base price × 1000

## 📈 Future Extensions

- Challenge resolution logic (model arbitration)
- Leaderboard and incentive system for top models
- Integration with off-chain verifiers

## 🛡️ Errors

| Code | Description |
|------|-------------|
| `1200` | Model already exists |
| `1201` | Invalid model or ID |
| `1202` | Insufficient payment |
| `1203` | Not authorized |
| `1204` | License expired |
| `1205` | Invalid performance |
| `1206` | Already reviewed |
| `1207` | Stake locked |

---

## 👨‍💻 Tech Stack

- **Clarity Smart Contract Language**
- **Stacks Blockchain**

---

## 🧾 License

This contract is open-source and available for use under the [MIT License](LICENSE).
