import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import savePaymentPolicy from '@salesforce/apex/BookingController.savePaymentPolicy';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import saveDealCostToSalesPrice from '@salesforce/apex/PolicyController.saveDealCostToSalesPrice';


export default class CreateBookingPolicies extends LightningElement {

    @api recordId; // Opportunity Id from Quick Action
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

    handleSave() {
        const child = this.template.querySelector('c-booking-payment-policies');

        if (!child || !child.selectedPaymentPolicy) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Payment Plan',
                    message: 'Please select a Payment Plan before saving.',
                    variant: 'warning'
                })
            );
            return;
        }

        const dealCost = child.dealCost;

        savePaymentPolicy({
            bookingId: this.recordId,
            paymentPolicyId: child.selectedPaymentPolicy,
            totalDealCost: dealCost
        })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Payment Policy has been saved successfully.',
                    variant: 'success'
                })
            );
            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error => {
            console.error('Error saving Payment Policy', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Something went wrong while saving.',
                    variant: 'error'
                })
            );
        });
    }
}
