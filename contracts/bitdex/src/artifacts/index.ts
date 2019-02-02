import { ContractArtifact } from 'ethereum-types';

import * as IBitDexToken from '../../generated-artifacts/IBitDexToken.json';
import * as BitDexToken from '../../generated-artifacts/BitDexToken.json';
import * as BDTToken from '../../generated-artifacts/BDTToken.json';

// tslint:disable:no-unnecessary-type-assertion
export const artifacts = {
    IBitDexToken: IBitDexToken as ContractArtifact,
    BitDexToken: BitDexToken as ContractArtifact,
    // Note(albrow): "as any" hack still required here because BDTToken does not
    // conform to the v2 artifact type.
    BDTToken: (BDTToken as any) as ContractArtifact,
};
