# 🎄 Secure Merkle Airdrop Protocol

A highly secure and gas-efficient token distribution system implementing advanced cryptographic verification through Merkle proofs and EIP-712 signatures.

## 🌟 Features

- **Double-Layer Security**: Combines Merkle tree verification with EIP-712 signatures for bulletproof claim validation
- **Gas Optimization**: Merkle tree implementation reduces on-chain storage costs compared to traditional allowlist methods
- **Sybil Attack Prevention**: Robust signature verification prevents unauthorized claims
- **Pre-image Attack Protection**: Double-hashing leaf nodes prevents hash collision vulnerabilities
- **Reentrancy Protection**: State changes before token transfers prevent reentrancy attacks
- **ERC20 Compatibility**: Works with any ERC20 token through OpenZeppelin's safe transfer implementation

## 🔒 Security Measures

### Cryptographic Verification
- Merkle tree verification ensures only whitelisted addresses can claim
- EIP-712 structured signatures provide tamper-proof claim authorization
- Double-hashing mechanism prevents pre-image attacks

### Smart Contract Safety
- Immutable variables prevent post-deployment modifications
- Custom error definitions for gas-efficient reverts
- Comprehensive input validation
- SafeERC20 implementation for secure token transfers

## 🛠 Technical Implementation

### Core Components

1. **MerkleAirdrop.sol**
   - Main contract handling claim verification and token distribution
   - Implements EIP-712 for structured data signing
   - Uses OpenZeppelin's cryptographic libraries

2. **ChristmasToken.sol**
   - Example ERC20 token with controlled minting
   - Inherits from OpenZeppelin's battle-tested implementations

### Supporting Scripts

- **GenerateInput.s.sol**: Generates structured input for Merkle tree creation
- **MakeMerkle.s.sol**: Builds Merkle tree and generates proofs
- **DeployMerkleAirdrop.s.sol**: Handles secure contract deployment
- **interact.s.sol**: Provides claim functionality with signature verification

## 📊 Testing

Comprehensive test suite including:
- Integration tests for full claim flow
- Signature verification tests
- Merkle proof validation
- Error condition handling

## 🚀 Deployment

1. Clone the repository:
```bash
git clone https://github.com/SquilliamX/christmas-merkle-airdrop.git
```

2. Install dependencies
```bash
forge install
```

3. Generate input file:
```bash
forge script script/GenerateInput.s.sol
```

4. Generate output file with Merkle proofs for each address and the Merkle root:
```bash
forge script script/MakeMerkle.s.sol
```

5. Deploy The Airdrop Contract:
```bash
forge script script/DeployMerkleAirdrop.s.sol:DeployMerkleAirdrop $(NETWORK_ARGS)
```

6. Claim Tokens:
```bash
forge script script/interact.s.sol:ClaimAirdrop $(NETWORK_ARGS)
```


## 🔍 Technical Details

### Merkle Tree Structure
- Leaf format: `keccak256(bytes.concat(keccak256(abi.encode(address, amount))))`
- Root: `0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4`
- Supports arbitrary number of claimants

### EIP-712 Implementation
- Domain separator ensures cross-chain safety
- Structured data typing prevents signature replay attacks
- Version control for future upgrades

## 🤝 Contributing

Contributions welcome! Please check our contribution guidelines and coding standards.

## 📜 License

MIT License

---

Built with ❤️ by Squilliam, using Foundry and OpenZeppelin