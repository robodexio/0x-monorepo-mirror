#!/usr/bin/env node
import { devConstants, web3Factory } from '@0x/dev-utils';
import { logUtils } from '@0x/utils';
import { Provider, TxData } from 'ethereum-types';

import { runMigrationsAsync } from './migration';

(async () => {
    let providerConfigs;
    let provider: Provider;
    let txDefaults;

    providerConfigs = {
        hasAddresses: true,
        rpcUrl: 'http://127.0.0.1:7545',
    };
    provider = web3Factory.getRpcProvider(providerConfigs);
    txDefaults = {
        from: devConstants.TESTRPC_FIRST_ADDRESS,
        gasPrice: '10000000000',
    };
    await runMigrationsAsync(provider, txDefaults);
    process.exit(0);
})().catch(err => {
    logUtils.log(err);
    process.exit(1);
});
