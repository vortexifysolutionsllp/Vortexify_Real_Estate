import { LightningElement } from 'lwc';

export default class createProjectPolicies extends LightningElement {
    selectedPolicy = 'Payment';
    showPayment = true;
    showCommission = false;
    hasPolicy = true;
    policyOptions = [
        { label: 'Payment', value: 'Payment' },
        { label: 'Commission', value: 'Commission' }
    ];
    handlePolicyChange(event) {
        this.selectedPolicy = event.detail.value;
        if (this.selectedPolicy === 'Payment') {
            this.showPayment = true;
            this.showCommission = false;
        } else {
            this.showPayment = false;
            this.showCommission = true;
        }
    }
}