## BitDEX Tokens

This package contains implementations of various BitDEX tokens, including BDT token. Addresses of the deployed contracts can be found in the [DEPLOYS](./DEPLOYS.json) file within this package.

## Installation

**Install**

```bash
npm install @0x/contracts-bitdex --save
```

### Install Dependencies

If you don't have yarn workspaces enabled (Yarn < v1.0) - enable them:

```bash
yarn config set workspaces-experimental true
```

Then install dependencies

```bash
yarn install
```

### Build

To build this package and all other monorepo packages that it depends on, run the following from the monorepo root directory:

```bash
PKG=@0x/contracts-bitdex yarn build
```

Or continuously rebuild on change:

```bash
PKG=@0x/contracts-bitdex yarn watch
```

### Clean

```bash
yarn clean
```

### Lint

```bash
yarn lint
```

### Run Tests

```bash
yarn test
```

#### Testing options

Contracts testing options like coverage, profiling, revert traces or backing node choosing - are described [here](../TESTING.md).
