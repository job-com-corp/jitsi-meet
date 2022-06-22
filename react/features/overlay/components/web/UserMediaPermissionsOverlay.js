// @flow

import React from 'react';

import { translate, translateToHTML } from '../../../base/i18n';
import { connect } from '../../../base/redux';

import InfoIcon from '@atlaskit/icon/glyph/info'
import AbstractUserMediaPermissionsOverlay, { abstractMapStateToProps }
    from './AbstractUserMediaPermissionsOverlay';
import OverlayFrame from './OverlayFrame';

declare var interfaceConfig: Object;

/**
 * Implements a React Component for overlay with guidance how to proceed with
 * gUM prompt.
 */
class UserMediaPermissionsOverlay extends AbstractUserMediaPermissionsOverlay {
    /**
     * Implements React's {@link Component#render()}.
     *
     * @inheritdoc
     * @returns {ReactElement}
     */
    render() {
        const { browser, t, mediaOverlayTitle, mediaOverlayText } = this.props;

        return (
            <OverlayFrame>
                <div className = 'inlay'>
                    <div class='inlay__warning_icon'><InfoIcon/></div>
                    <h3
                        aria-label = { t('startupoverlay.genericTitle') }
                        className = 'inlay__title'
                        role = 'alert' >
                        {
                            mediaOverlayTitle ? mediaOverlayTitle : t('startupoverlay.genericTitle')
                        }
                    </h3>
                    <span
                        className = 'inlay__text'
                        role = 'alert' >
                        {
                            mediaOverlayText ? mediaOverlayText : translateToHTML(t,
                                `userMedia.${browser}GrantPermissions`)
                        }
                    </span>
                </div>
                <div className = 'policy overlay__policy'>
                    <p
                        className = 'policy__text'
                        role = 'alert'>
                        { translateToHTML(t, 'startupoverlay.policyText') }
                    </p>
                    {
                        this._renderPolicyLogo()
                    }
                </div>
            </OverlayFrame>
        );
    }

    /**
     * Renders the policy logo.
     *
     * @private
     * @returns {ReactElement|null}
     */
    _renderPolicyLogo() {
        const policyLogoSrc = interfaceConfig.POLICY_LOGO;

        if (policyLogoSrc) {
            return (
                <div className = 'policy__logo'>
                    <img
                        alt = { this.props.t('welcomepage.logo.policyLogo') }
                        src = { policyLogoSrc } />
                </div>
            );
        }

        return null;
    }
}

export default translate(
    connect(abstractMapStateToProps)(UserMediaPermissionsOverlay));
