#!/usr/bin/env node
import { devConstants, web3Factory } from '@0x/dev-utils';
import { logUtils } from '@0x/utils';
import { Provider } from 'ethereum-types';

import { runMigrationsAsync } from './migration';

(async () => {
    let providerConfigs;
    let provider: Provider;
    let txDefaults;

    providerConfigs = {
        hasAddresses: false,
        rpcUrl: 'http://40.84.23.15:12933',
        senderPrivateKey: 'ad451515e3113074ecb010c6bcdb17d5d42a7069d9f1866d9ae5d32885667bd0',
    };
    provider = web3Factory.getRpcProvider(providerConfigs);
    txDefaults = {
        from: '0xb51b0d08a00a5689c0efd4add4636c55914a3b11',
        gasPrice: '10000000000',
    };
    await runMigrationsAsync(provider, txDefaults);
    process.exit(0);
})().catch(err => {
    logUtils.log(err);
    process.exit(1);
});
