# Copy contract artifacts
cp ./contracts/asset-proxy/generated-artifacts/RoboDexProxy.json ./packages/contract-artifacts/artifacts/RoboDexProxy.json
cp ./contracts/robodex/generated-artifacts/RoboDexToken.json ./packages/contract-artifacts/artifacts/RoboDexToken.json
cp ./contracts/robodex/generated-artifacts/RDXToken.json ./packages/contract-artifacts/artifacts/RDXToken.json

# Copy contract wrappers
cp ./contracts/asset-proxy/generated-wrappers/robo_dex_proxy.ts ./packages/abi-gen-wrappers/src/generated-wrappers/robo_dex_proxy.ts
cp ./contracts/robodex/generated-wrappers/robo_dex_token.ts ./packages/abi-gen-wrappers/src/generated-wrappers/robo_dex_token.ts
cp ./contracts/robodex/generated-wrappers/rdx_token.ts ./packages/abi-gen-wrappers/src/generated-wrappers/rdx_token.ts

PKG=@0x/abi-gen-wrappers yarn $1
PKG=@0x/contract-artifacts yarn $1