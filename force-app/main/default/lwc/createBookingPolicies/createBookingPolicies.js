import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import savePaymentPolicy from '@salesforce/apex/BookingController.savePaymentPolicy';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import saveDealCostToSalesPrice from '@salesforce/apex/PolicyController.saveDealCostToSalesPrice';



export default class CreateBookingPolicies extends LightningElement {
    project;
    tower;
    towerCount = 0;
    unitCount = 0;
    projectId;

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
        // ================= PAYMENT =================
        if (this.isPayment) {
            const paymentChild =
                this.template.querySelector('c-booking-payment-policies');

            if (!paymentChild || !paymentChild.selectedPaymentPolicy) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Missing Payment Plan',
                        message: 'Please select a Payment Plan before saving.',
                        variant: 'warning'
                    })
                );
                return;
            }

            savePaymentPolicy({
                bookingId: this.recordId,
                paymentPolicyId: paymentChild.selectedPaymentPolicy,
                totalDealCost: paymentChild.dealCost
            })
                .then(() => {
                    this.showSuccessAndClose('Payment Policy saved successfully');
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

        // ================= COMMISSION =================
        if (this.isCommission) {
            const commissionChild =
                this.template.querySelector('c-booking-commission-policies');

            if (!commissionChild || !commissionChild.selectedPolicyId) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Missing Commission Policy',
                        message: 'Please select a Commission Policy before saving.',
                        variant: 'warning'
                    })
                );
                return;
            }

            commissionChild.handleSave(); // delegate save to child
            this.dispatchEvent(new CloseActionScreenEvent());
        }

        
    }
    showSuccessAndClose(message) {
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Success',
            message,
            variant: 'success'
        })
    );
    this.dispatchEvent(new CloseActionScreenEvent());
}

showError(message = 'Something went wrong while saving.') {
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Error',
            message,
            variant: 'error'
        })
    );
}


}