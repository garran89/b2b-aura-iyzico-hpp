import { LightningElement, api } from 'lwc';
import iyzicoCheckoutFormInit from '@salesforce/apex/IyzicoController.iyzicoCheckoutFormInit';

export default class PayWithIyzico extends LightningElement {
    @api cartId;
    isError;
    async onClickHandler(event) {
        event.preventDefault();

        try {
            const result = await iyzicoCheckoutFormInit({cartId: this.cartId});
            console.log(result);
            if (!result || !result.success) {
                this.isError = true;
            } else {
                window.location = result.paymentPageUrl;
            }
        } catch (error) {
            console.error(error);
        }
    }
}