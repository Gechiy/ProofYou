# ProofYou Smart Contract

A trustless digital identity authentication and access layer control system built on the Stacks blockchain using Clarity.

## Overview

ProofYou enables decentralized identity verification through a validator network. Users can have their identities verified at different tier levels, with the ability to revoke verification when needed.

## Features

- **Validator Management**: Admin can add/remove trusted validators
- **Tiered Verification**: Three-tier identity verification system (1, 2, 3)
- **Credential Hashing**: Secure storage of credential hashes
- **Revocation System**: Validators, admin, and users can revoke verifications
- **Self-Sovereignty**: Users can self-revoke their verification status

## Contract Structure

### Constants

- `ADMIN`: Contract administrator (deployer)
- Error codes for various failure scenarios

### Data Maps

#### `val-registry`
Tracks authorized validators:
```clarity
principal -> bool
```

#### `id-verifs` 
Stores user verification data:
```clarity
{ usr: principal } -> {
  verified: bool,
  tier: uint,
  verified-at: uint,
  hash: (buff 32),
  verified-by: principal
}
```

## Functions

### Read-Only Functions

#### `check-val (id principal)`
Check if a principal is an authorized validator.

#### `get-val-status (id principal)`
Get validator status from registry.

#### `is-usr-verified (u principal)`
Check if a user has verified identity.

#### `get-usr-record (u principal)`
Retrieve complete user verification record.

#### `get-usr-tier (u principal)`
Get user's verification tier level.

### Public Functions

#### `add-val (v principal)`
**Admin only** - Add a new validator to the registry.

**Parameters:**
- `v`: Principal to authorize as validator

**Errors:**
- `ERR_UNAUTH`: Not called by admin
- `ERR_VAL_EXISTS`: Validator already exists

#### `remove-val (v principal)`
**Admin only** - Remove validator from registry.

**Parameters:**
- `v`: Validator principal to remove

**Errors:**
- `ERR_UNAUTH`: Not called by admin
- `ERR_INVALID_VAL`: Validator doesn't exist

#### `verify-id (u principal) (t uint) (h (buff 32))`
**Validator only** - Verify a user's identity.

**Parameters:**
- `u`: User principal to verify
- `t`: Tier level (1, 2, or 3)
- `h`: Credential hash (32 bytes)

**Errors:**
- `ERR_UNAUTH`: Not called by authorized validator
- `ERR_INVALID_TIER`: Invalid tier level
- `ERR_INVALID_HASH`: Zero/invalid hash

#### `revoke-id (u principal)`
**Validator/Admin only** - Revoke user's verification.

**Parameters:**
- `u`: User principal to revoke

**Authorization:**
- Original verifying validator
- Contract admin

**Errors:**
- `ERR_ID_NOT_VAL`: User not verified
- `ERR_UNAUTH`: Unauthorized caller

#### `self-revoke ()`
**User only** - Self-revoke verification status.

**Errors:**
- `ERR_ID_NOT_VAL`: User not currently verified

## Verification Tiers

1. **Tier 1**: Basic verification
2. **Tier 2**: Enhanced verification  
3. **Tier 3**: Premium verification

Higher tiers may grant access to more sensitive resources or higher privileges in connected applications.

## Usage Examples

### Deploy and Setup
```clarity
;; Deploy contract (admin is tx-sender)
;; Add validators
(contract-call? .proofy add-val 'SP1234...VALIDATOR1)
(contract-call? .proofy add-val 'SP5678...VALIDATOR2)
```

### Verify Identity
```clarity
;; As a validator
(contract-call? .proofy verify-id 'SP9876...USER u2 0x1234...HASH)
```

### Check Status
```clarity
;; Check if user is verified
(contract-call? .proofy is-usr-verified 'SP9876...USER)

;; Get user's tier
(contract-call? .proofy get-usr-tier 'SP9876...USER)
```

### Revoke Verification
```clarity
;; Admin or original validator
(contract-call? .proofy revoke-id 'SP9876...USER)

;; User self-revoke
(contract-call? .proofy self-revoke)
```

## Security Considerations

- Only authorized validators can verify identities
- Credential hashes should be generated securely off-chain
- Admin has ultimate control over validator registry
- Users maintain sovereignty through self-revocation
- Verification state changes are permanently logged on-chain

## Error Handling

All functions return `(response bool uint)`, with descriptive error codes:

- `u100`: Unauthorized access
- `u101`: Validator already exists
- `u102`: Invalid validator
- `u103`: ID already validated
- `u104`: ID not validated
- `u105`: Invalid tier level
- `u106`: Not admin
- `u107`: Invalid hash

## Integration

This contract can be integrated with other Stacks contracts or dApps to provide:

- Gated access to services based on verification tier
- KYC/AML compliance for DeFi protocols
- Reputation systems
- Identity-based governance mechanisms

