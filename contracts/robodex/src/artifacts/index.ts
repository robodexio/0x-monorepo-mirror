import { ContractArtifact } from 'ethereum-types';

import * as RoboDexToken from '../../generated-artifacts/RoboDexToken.json';
import * as RDXToken from '../../generated-artifacts/RDXToken.json';

// tslint:disable:no-unnecessary-type-assertion
export const artifacts = {
    RoboDexToken: RoboDexToken as ContractArtifact,
    // Note(albrow): "as any" hack still required here because RDXToken does not
    // conform to the v2 artifact type.
    RDXToken: (RDXToken as any) as ContractArtifact,
};
