import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import savePaymentPolicy from '@salesforce/apex/BookingController.savePaymentPolicy';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

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

    // ================= PAYMENT =================
    if (this.isPayment) {
        const paymentChild =
            this.template.querySelector('c-booking-payment-policies');

        if (!paymentChild) {
            return;
        }

        
        paymentChild.handleSave()
            .then(() => {
             
                return savePaymentPolicy({
                    bookingId: this.recordId,
                    paymentPolicyId: paymentChild.selectedPaymentPolicy,
                    totalDealCost: paymentChild.dealCost
                });
            })
            .then(() => {
                return paymentChild.refreshData();
            })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Payment Policy has been saved successfully.',
                        variant: 'success'
                    })
                );
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(() => {
                
            });

        return;
    }


        

       
    // ================= COMMISSION =================
    if (this.isCommission) {
        const commissionChild =
            this.template.querySelector('c-booking-commission-policies');

        if (!commissionChild) {
            return;
        }

        commissionChild.handleSave()
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Commission Policy saved successfully.',
                        variant: 'success'
                    })
                );
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(() => {
                // child already showed toast
            });
    }
}
   
}