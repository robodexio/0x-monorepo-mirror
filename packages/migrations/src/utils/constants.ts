import { BigNumber } from '@0x/utils';

export const constants = {
    ASSET_PROXY_OWNER_OWNERS: [
        '0xb51b0d08a00a5689c0efd4add4636c55914a3b11',
        '0x091fde48c9cedd5e85ecc6b62569411b8ade6f7f',
        '0xaef6d87d151c803c1c2c40d0270c95e0280c3f48',
    ],
    ASSET_PROXY_OWNER_TIMELOCK: new BigNumber(0),
    ASSET_PROXY_OWNER_CONFIRMATIONS: new BigNumber(1),
    ERC20_PROXY_ID: '0xf47261b0',
    ERC721_PROXY_ID: '0x02571792',
    ROBODEX_PROXY_ID: '0x0e2042d8',
    NULL_ADDRESS: '0x0000000000000000000000000000000000000000',
    KOVAN_RPC_URL: 'https://kovan.infura.io/',
    KOVAN_NETWORK_ID: 42,
    MAINNET_RPC_URL: 'https://mainnet.infura.io/',
    MAINNET_NETWORK_ID: 1,
};
