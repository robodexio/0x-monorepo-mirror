import * as wrappers from '@0x/abi-gen-wrappers';
import { ContractAddresses } from '@0x/contract-addresses';
import * as artifacts from '@0x/contract-artifacts';
import { assetDataUtils } from '@0x/order-utils';
import { BigNumber } from '@0x/utils';
import { Web3Wrapper } from '@0x/web3-wrapper';
import { Provider, TxData } from 'ethereum-types';
import * as _ from 'lodash';

import { constants } from './utils/constants';
import { erc20TokenInfo, erc721TokenInfo, roboDexTokenInfo } from './utils/token_info';

/**
 * Creates and deploys all the contracts that are required for the latest
 * version of the 0x protocol.
 * @param provider  Web3 provider instance. Your provider instance should connect to the testnet you want to deploy to.
 * @param txDefaults Default transaction values to use when deploying contracts (e.g., specify the desired contract creator with the `from` parameter).
 * @returns The addresses of the contracts that were deployed.
 */
export async function runMigrationsAsync(provider: Provider, txDefaults: TxData): Promise<ContractAddresses> {
    const web3Wrapper = new Web3Wrapper(provider);

    // Proxies
    const erc20Proxy = await wrappers.ERC20ProxyContract.deployFrom0xArtifactAsync(
        artifacts.ERC20Proxy,
        provider,
        {...txDefaults, ...{ gas: 1250000 }},
    );
    const erc721Proxy = await wrappers.ERC721ProxyContract.deployFrom0xArtifactAsync(
        artifacts.ERC721Proxy,
        provider,
        {...txDefaults, ...{ gas: 1250000 }},
    );
    const roboDexProxy = await wrappers.RoboDexProxyContract.deployFrom0xArtifactAsync(
        artifacts.RoboDexProxy,
        provider,
        {...txDefaults, ...{ gas: 1250000 }},
    );

    // Ether token
    const etherToken = await wrappers.WETH9Contract.deployFrom0xArtifactAsync(
        artifacts.WETH9,
        provider,
        {...txDefaults, ...{ gas: 1250000 }},
    );

    // ZRX
    const zrxToken = await wrappers.ZRXTokenContract.deployFrom0xArtifactAsync(
        artifacts.ZRXToken,
        provider,
        {...txDefaults, ...{ gas: 1000000 }},
    );

    // RDX
    const rdxToken = await wrappers.RDXTokenContract.deployFrom0xArtifactAsync(
        artifacts.RDXToken,
        provider,
        {...txDefaults, ...{ gas: 3000000 }},
    );

    // Exchange
    const zrxAssetData = assetDataUtils.encodeERC20AssetData(zrxToken.address);
    const exchange = await wrappers.ExchangeContract.deployFrom0xArtifactAsync(
        artifacts.Exchange,
        provider,
        {...txDefaults, ...{ gas: 6500000 }},
        zrxAssetData,
    );

    // Dummy ERC20 tokens
    // for (const token of erc20TokenInfo) {
    //     const totalSupply = new BigNumber(1000000000000000000000000000);
    //     // tslint:disable-next-line:no-unused-variable
    //     const dummyErc20Token = await wrappers.DummyERC20TokenContract.deployFrom0xArtifactAsync(
    //         artifacts.DummyERC20Token,
    //         provider,
    //         txDefaults,
    //         token.name,
    //         token.symbol,
    //         token.decimals,
    //         totalSupply,
    //     );
    // }

    // ERC721
    // tslint:disable-next-line:no-unused-variable
    // const cryptoKittieToken = await wrappers.DummyERC721TokenContract.deployFrom0xArtifactAsync(
    //     artifacts.DummyERC721Token,
    //     provider,
    //     txDefaults,
    //     erc721TokenInfo[0].name,
    //     erc721TokenInfo[0].symbol,
    // );

    const multiAssetProxy = await wrappers.MultiAssetProxyContract.deployFrom0xArtifactAsync(
        artifacts.MultiAssetProxy,
        provider,
        {...txDefaults, ...{ gas: 1750000 }},
    );

    await web3Wrapper.awaitTransactionSuccessAsync(
        await erc20Proxy.addAuthorizedAddress.sendTransactionAsync(exchange.address, {
            from: txDefaults.from,
            gas: 100000,
        }),
    );
    await web3Wrapper.awaitTransactionSuccessAsync(
        await erc721Proxy.addAuthorizedAddress.sendTransactionAsync(exchange.address, {
            from: txDefaults.from,
            gas: 100000,
        }),
    );
    await web3Wrapper.awaitTransactionSuccessAsync(
        await roboDexProxy.addAuthorizedAddress.sendTransactionAsync(exchange.address, {
            from: txDefaults.from,
            gas: 100000,
        }),
    );
    await web3Wrapper.awaitTransactionSuccessAsync(
        await multiAssetProxy.addAuthorizedAddress.sendTransactionAsync(exchange.address, {
            from: txDefaults.from,
            gas: 100000,
        }),
    );

    // MultiAssetProxy
    await web3Wrapper.awaitTransactionSuccessAsync(
        await erc20Proxy.addAuthorizedAddress.sendTransactionAsync(multiAssetProxy.address, {
            from: txDefaults.from,
            gas: 100000,
        }),
    );
    await web3Wrapper.awaitTransactionSuccessAsync(
        await erc721Proxy.addAuthorizedAddress.sendTransactionAsync(multiAssetProxy.address, {
            from: txDefaults.from,
            gas: 100000,
        }),
    );
    await web3Wrapper.awaitTransactionSuccessAsync(
        await roboDexProxy.addAuthorizedAddress.sendTransactionAsync(multiAssetProxy.address, {
            from: txDefaults.from,
            gas: 100000,
        }),
    );
    await web3Wrapper.awaitTransactionSuccessAsync(
        await multiAssetProxy.registerAssetProxy.sendTransactionAsync(erc20Proxy.address, {
            gas: 100000,
        }),
    );
    await web3Wrapper.awaitTransactionSuccessAsync(
        await multiAssetProxy.registerAssetProxy.sendTransactionAsync(erc721Proxy.address, {
            gas: 100000,
        }),
    );
    await web3Wrapper.awaitTransactionSuccessAsync(
        await multiAssetProxy.registerAssetProxy.sendTransactionAsync(roboDexProxy.address, {
            gas: 100000,
        }),
    );

    // Register the Asset Proxies to the Exchange
    await web3Wrapper.awaitTransactionSuccessAsync(
        await exchange.registerAssetProxy.sendTransactionAsync(erc20Proxy.address, {
            gas: 100000,
        }),
    );
    await web3Wrapper.awaitTransactionSuccessAsync(
        await exchange.registerAssetProxy.sendTransactionAsync(erc721Proxy.address, {
            gas: 100000,
        }),
    );
    await web3Wrapper.awaitTransactionSuccessAsync(
        await exchange.registerAssetProxy.sendTransactionAsync(roboDexProxy.address, {
            gas: 100000,
        }),
    );
    await web3Wrapper.awaitTransactionSuccessAsync(
        await exchange.registerAssetProxy.sendTransactionAsync(multiAssetProxy.address, {
            gas: 100000,
        }),
    );

    // Forwarder
    const forwarder = await wrappers.ForwarderContract.deployFrom0xArtifactAsync(
        artifacts.Forwarder,
        provider,
        {...txDefaults, ...{ gas: 3500000 }},
        exchange.address,
        assetDataUtils.encodeERC20AssetData(zrxToken.address),
        assetDataUtils.encodeERC20AssetData(etherToken.address),
    );

    // OrderValidator
    const orderValidator = await wrappers.OrderValidatorContract.deployFrom0xArtifactAsync(
        artifacts.OrderValidator,
        provider,
        {...txDefaults, ...{ gas: 2500000 }},
        exchange.address,
        zrxAssetData,
    );

    // DutchAuction
    const dutchAuction = await wrappers.DutchAuctionContract.deployFrom0xArtifactAsync(
        artifacts.DutchAuction,
        provider,
        {...txDefaults, ...{ gas: 1500000 }},
        exchange.address,
    );

    // Multisigs
    const accounts: string[] = constants.ASSET_PROXY_OWNER_OWNERS;
    const owners = [accounts[0], accounts[1], accounts[2]];
    const confirmationsRequired = new BigNumber(2);
    const secondsRequired = new BigNumber(0);

    // AssetProxyOwner
    const assetProxyOwner = await wrappers.AssetProxyOwnerContract.deployFrom0xArtifactAsync(
        artifacts.AssetProxyOwner,
        provider,
        {...txDefaults, ...{ gas: 3000000 }},
        owners,
        [erc20Proxy.address, erc721Proxy.address, roboDexProxy.address, multiAssetProxy.address],
        confirmationsRequired,
        secondsRequired,
    );

    // Transfer Ownership to the Asset Proxy Owner
    await web3Wrapper.awaitTransactionSuccessAsync(
        await erc20Proxy.transferOwnership.sendTransactionAsync(assetProxyOwner.address, {
            from: txDefaults.from,
            gas: 50000,
        }),
    );
    await web3Wrapper.awaitTransactionSuccessAsync(
        await erc721Proxy.transferOwnership.sendTransactionAsync(assetProxyOwner.address, {
            from: txDefaults.from,
            gas: 50000,
        }),
    );
    await web3Wrapper.awaitTransactionSuccessAsync(
        await roboDexProxy.transferOwnership.sendTransactionAsync(assetProxyOwner.address, {
            from: txDefaults.from,
            gas: 50000,
        }),
    );
    await web3Wrapper.awaitTransactionSuccessAsync(
        await multiAssetProxy.transferOwnership.sendTransactionAsync(assetProxyOwner.address, {
            from: txDefaults.from,
            gas: 50000,
        }),
    );

    // Fund the Forwarder with ZRX
    const zrxDecimals = await zrxToken.decimals.callAsync();
    const zrxForwarderAmount = Web3Wrapper.toBaseUnitAmount(new BigNumber(5000), zrxDecimals);
    await web3Wrapper.awaitTransactionSuccessAsync(
        await zrxToken.transfer.sendTransactionAsync(forwarder.address, zrxForwarderAmount, txDefaults),
    );

    const contractAddresses = {
        erc20Proxy: erc20Proxy.address,
        erc721Proxy: erc721Proxy.address,
        roboDexProxy: roboDexProxy.address,
        etherToken: etherToken.address,
        zrxToken: zrxToken.address,
        rdxToken: rdxToken.address,
        exchange: exchange.address,
        assetProxyOwner: assetProxyOwner.address,
        forwarder: forwarder.address,
        orderValidator: orderValidator.address,
        dutchAuction: dutchAuction.address,
    };

    return contractAddresses;
}

let _cachedContractAddresses: ContractAddresses;

/**
 * Exactly like runMigrationsAsync but will only run the migrations the first
 * time it is called. Any subsequent calls will return the cached contract
 * addresses.
 * @param provider  Web3 provider instance. Your provider instance should connect to the testnet you want to deploy to.
 * @param txDefaults Default transaction values to use when deploying contracts (e.g., specify the desired contract creator with the `from` parameter).
 * @returns The addresses of the contracts that were deployed.
 */
export async function runMigrationsOnceAsync(provider: Provider, txDefaults: TxData): Promise<ContractAddresses> {
    if (!_.isUndefined(_cachedContractAddresses)) {
        return _cachedContractAddresses;
    }
    _cachedContractAddresses = await runMigrationsAsync(provider, txDefaults);
    return _cachedContractAddresses;
}
