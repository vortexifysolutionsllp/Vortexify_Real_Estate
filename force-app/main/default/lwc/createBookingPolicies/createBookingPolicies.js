import { LightningElement, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CreateBookingPolicies extends LightningElement {

    @track selected = 'payment';

    get isPayment() {
        return this.selected === 'payment';
    }

    get isCommission() {
        return this.selected === 'commission';
    }

    selectPayment() {
        this.selected = 'payment';
    }

    selectCommission() {
        this.selected = 'commission';
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
