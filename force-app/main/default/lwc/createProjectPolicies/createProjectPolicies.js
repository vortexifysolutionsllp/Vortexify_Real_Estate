import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import fetchPolicyData from '@salesforce/apex/PolicyController.fetchPolicyData';
import savePolicies from '@salesforce/apex/PolicyController.savePolicies';

export default class CreateProjectPolicies extends LightningElement {

    @api recordId;

    selectedPolicy = 'Payment';
    showPayment = true;
    showCommission = false;

    hasPolicy = true; 

    editMode = false;
    editLabel = 'Edit';

    //_loaded = false; // 🔴 KEPT EXACTLY AS YOU HAD IT

    policyOptions = [
        { label: 'Payment', value: 'Payment' },
        { label: 'Commission', value: 'Commission' }
    ];

    renderedCallback() {
        // if (this._loaded) return;
        this._loaded = true;
        this.loadData();
    }

    loadData() {
        if (!this.recordId) {
            console.error('recordId not found');
            return;
        }

        fetchPolicyData({ projectId: this.recordId })
            .then(res => {

                let tryFindChild = () => {
                    let child = this.template.querySelector('c-create-payment-policies');
                    if (child) {
                        console.log('child found', child);
                        child.loadData(res);
                    } else {
                        console.log('child not found');
                        // wait and try again
                        setTimeout(() => {
                            tryFindChild();
                        }, 100);
                    }
                };

                tryFindChild();

            })
            .catch(err => {
                console.error('fetchPolicyData error', err);
                this.showToast(
                    'Error',
                    'Failed to load policy data',
                    'error'
                );
            });
    }

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

    // ❌ CANCEL → CLOSE QUICK ACTION MODAL
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleEditClick() {
        let child = this.template.querySelector('c-create-payment-policies');

        if (!child) {
            console.error('Child component not found');
            return;
        }

        // 💾 SAVE
        if (this.editMode) {
            let data = child.getPolicies();

            savePolicies({
                policiesJson: JSON.stringify(data),
                projectId: this.recordId
            })
            .then(() => {
                this.showToast(
                    'Success',
                    'Policies saved successfully',
                    'success'
                );

                // ✅ CLOSE QUICK ACTION MODAL
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(err => {
                console.error('savePolicies error', err);
                this.showToast(
                    'Error',
                    err?.body?.message || 'Failed to save policies',
                    'error'
                );
            });
        } 
        // ✏️ EDIT MODE
        else {
            this.editMode = true;
            this.editLabel = 'Save';
            child.toggleEditMode(true);
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
