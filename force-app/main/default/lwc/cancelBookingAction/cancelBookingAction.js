import { LightningElement, api } from 'lwc';
import cancelBooking from '@salesforce/apex/BookingCancellationController.cancelBooking';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CancelBookingModal extends LightningElement {
    @api recordId;

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleCancelBooking() {
        try {
            await cancelBooking({ opportunityId: this.recordId });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Booking Cancelled',
                    message: 'The booking has been cancelled and the unit is now available.',
                    variant: 'success'
                })
            );

        } catch (error) {
            let message = error?.body?.message || 'Unexpected error occurred';

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Cannot Cancel Booking',
                    message: message,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        }

        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
