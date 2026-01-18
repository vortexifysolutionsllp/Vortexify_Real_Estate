import { LightningElement } from 'lwc';

export default class BookingPaymentPolicies extends LightningElement {

    paymentPlanOptions = [
        { label: 'Construction Linked Plan', value: 'clp' },
        { label: 'Down Payment Plan', value: 'dp' },
        { label: 'Flexi Payment Plan', value: 'flexi' },
        { label: 'Time Linked Plan', value: 'tlp' }
    ];
}
