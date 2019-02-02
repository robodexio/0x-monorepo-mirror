# Copy contract artifacts
cp ./contracts/asset-proxy/generated-artifacts/BitDexProxy.json ./packages/contract-artifacts/artifacts/BitDexProxy.json
cp ./contracts/bitdex/generated-artifacts/BDTToken.json ./packages/contract-artifacts/artifacts/BDTToken.json
cp ./contracts/bitdex/generated-artifacts/BitDexToken.json ./packages/contract-artifacts/artifacts/BitDexToken.json

# Copy contract wrappers
cp ./contracts/asset-proxy/generated-wrappers/bit_dex_proxy.ts ./packages/abi-gen-wrappers/src/generated-wrappers/bit_dex_proxy.ts
cp ./contracts/bitdex/generated-wrappers/bdt_token.ts ./packages/abi-gen-wrappers/src/generated-wrappers/bdt_token.ts
cp ./contracts/bitdex/generated-wrappers/bit_dex_token.ts ./packages/abi-gen-wrappers/src/generated-wrappers/bit_dex_token.ts

PKG=@0x/abi-gen-wrappers yarn $1
PKG=@0x/contract-artifacts yarn $1