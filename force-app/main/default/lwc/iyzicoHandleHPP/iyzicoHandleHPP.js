import { LightningElement, api,wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import handlePostAuthorization from '@salesforce/apex/IyzicoController.handlePostAuthorization';


export default class IyzicoHandleHPP extends LightningElement {
    @api cartId;
    @api availableActions = [];

    get myToken() {
        let params = (new URL(document.location)).searchParams;
        return params.get('token');
    }

    async connectedCallback() {
        try {
            const result = await handlePostAuthorization({token: this.myToken, cartId: this.cartId});
            console.log(result);
            if (result) {
                const gatewayResponse = result.gatewayResponse;
                if (gatewayResponse) {
                    const salesforceResultCode = gatewayResponse.salesforceResultCode;
                    if (salesforceResultCode === 'Success') {
                        const navigateNextEvent = new FlowNavigationNextEvent();
                        this.dispatchEvent(navigateNextEvent);
                    }
                }
            }
        } catch (error) {
            console.error(error);
        }
    }
}