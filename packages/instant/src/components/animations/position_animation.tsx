import { Keyframes } from 'styled-components';

import { media, MediaChoice, OptionallyScreenSpecific, ScreenSpecification, stylesForMedia } from '../../style/media';
import { css, keyframes, styled } from '../../style/theme';

export interface TransitionInfo {
    from: string;
    to: string;
}

const generateTransitionInfoCss = (
    key: keyof TransitionInfo,
    top?: TransitionInfo,
    bottom?: TransitionInfo,
    left?: TransitionInfo,
    right?: TransitionInfo,
): string => {
    const topStringIfExists = top ? `top: ${top[key]};` : '';
    const bottomStringIfExists = bottom ? `bottom: ${bottom[key]};` : '';
    const leftStringIfExists = left ? `left: ${left[key]};` : '';
    const rightStringIfExists = right ? `right: ${right[key]};` : '';
    return `
    ${topStringIfExists}
    ${bottomStringIfExists}
    ${leftStringIfExists}
    ${rightStringIfExists}
    `;
};

const slideKeyframeGenerator = (
    position: string,
    top?: TransitionInfo,
    bottom?: TransitionInfo,
    left?: TransitionInfo,
    right?: TransitionInfo,
) => keyframes`
    from {
        position: ${position};
        ${generateTransitionInfoCss('from', top, bottom, left, right)}
    }

    to {
        position: ${position};
        ${generateTransitionInfoCss('to', top, bottom, left, right)}
    }
`;

export interface PositionAnimationSettings {
    top?: TransitionInfo;
    bottom?: TransitionInfo;
    left?: TransitionInfo;
    right?: TransitionInfo;
    timingFunction: string;
    duration?: string;
    position?: string;
}

const generatePositionAnimationCss = (positionSettings: PositionAnimationSettings) => {
    return css`
        animation-name: ${slideKeyframeGenerator(
            positionSettings.position || 'relative',
            positionSettings.top,
            positionSettings.bottom,
            positionSettings.left,
            positionSettings.right,
        )};
        animation-duration: ${positionSettings.duration || '0.3s'};
        animation-timing-function: ${positionSettings.timingFunction};
        animation-delay: 0s;
        animation-iteration-count: 1;
        animation-fill-mode: forwards;
        position: ${positionSettings.position || 'relative'};
        width: 100%;
    `;
};

// TODO: clean up position settings
export interface PositionAnimationProps {
    positionSettings: OptionallyScreenSpecific<PositionAnimationSettings>;
    zIndex?: MediaChoice;
}

// TODO: use media helper instead
const smallMediaCss = (generated: any) => {
    return css`
        @media (max-width: 40em) {
            ${generated};
        }
    `;
};

// TODO: z-index default value
export const PositionAnimation =
    styled.div <
    PositionAnimationProps >
    `
    ${props => props.zIndex && stylesForMedia('z-index', props.zIndex)}
    ${props =>
        generatePositionAnimationCss(
            'default' in props.positionSettings ? props.positionSettings.default : props.positionSettings,
        )}
    ${props =>
        'default' in props.positionSettings &&
        props.positionSettings.sm &&
        smallMediaCss(generatePositionAnimationCss(props.positionSettings.sm))}
`;
