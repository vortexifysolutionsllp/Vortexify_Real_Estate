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

    _loaded = false; // 🔴 KEPT EXACTLY AS YOU HAD IT
    _cachedPolicyData = null; // 🆕 store last loaded policy data


    policyOptions = [
        { label: 'Payment', value: 'Payment' },
        { label: 'Commission', value: 'Commission' }
    ];

    // get showPayment() {
    //     return this.selectedPolicy === 'Payment';
    // }

    // get showCommission() {
    //     return this.selectedPolicy === 'Commission';
    // }

    selectPayment() {
        this.selectedPolicy = 'Payment';
        this.showPayment = true;
        this.showCommission = false;
        setTimeout(() => {
            let child = this.template.querySelector('c-create-payment-policies');
            if (child && this._cachedPolicyData) {
                child.loadData(this._cachedPolicyData);
            }
        }, 0);
    }

    selectCommission() {
        this.selectedPolicy = 'Commission';
        this.showPayment = false;
        this.showCommission = true;
        // setTimeout(() => {
        //     let child = this.template.querySelector('c-create-payment-policies');
        //     if (child && this._cachedPolicyData) {
        //         child.loadData(this._cachedPolicyData);
        //     }
        // }, 0);
    }

    // handlePolicyChange(event) {
    //     this.selectedPolicy = event.detail.value;

    //     if (this.selectedPolicy === 'Payment') {
    //         this.showPayment = true;
    //         this.showCommission = false;
    //     } else {
    //         this.showPayment = false;
    //         this.showCommission = true;
    //     }

    //     setTimeout(() => {
    //         let child = this.template.querySelector('c-create-payment-policies');
    //         if (child && this._cachedPolicyData) {
    //             child.loadData(this._cachedPolicyData);
    //         }
    //     }, 0);
    // }

    renderedCallback() {

        if (this._loaded) return;   // guard

        this._loaded = true;

        // wait for child to render
        setTimeout(() => {
            this.loadData();
        }, 0);
    }


    loadData() {
        if (!this.recordId) {
            console.error('recordId not found');
            return;
        }

        fetchPolicyData({ projectId: this.recordId })
            .then(res => {
                this._cachedPolicyData = res;
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

    // handlePolicyChange(event) {
    //     this.selectedPolicy = event.detail.value;

    //     if (this.selectedPolicy === 'Payment') {
    //         this.showPayment = true;
    //         this.showCommission = false;
    //     } else {
    //         this.showPayment = false;
    //         this.showCommission = true;
    //     }

    //     setTimeout(() => {
    //         let child = this.template.querySelector('c-create-payment-policies');
    //         if (child && this._cachedPolicyData) {
    //             child.loadData(this._cachedPolicyData);
    //         }
    //     }, 0);
    // }

    // ❌ CANCEL → CLOSE QUICK ACTION MODAL
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleEditClick() {

        let child = this.template.querySelector('c-create-payment-policies');
        if (!child) return;

        let data;

        try {
            // 🔍 SAME VALIDATION LOGIC
            data = child.getPolicies(); // throws error if validation fails
        } catch (e) {

            // ✅ SHOW TOAST (NO MODAL CLOSE)
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: e.message,
                    variant: 'error',
                    mode: 'sticky' // 👈 IMPORTANT for quick action
                })
            );
            return; // ⛔ STOP HERE
        }

        savePolicies({
            policiesJson: JSON.stringify(data.policies),
            deletedPolicyIds: data.deletedPolicyIds,
            projectId: this.recordId
        })
        .then(() => {
            return fetchPolicyData({ projectId: this.recordId });

        })
        .then(res => {
            this._cachedPolicyData = res;
            let child = this.template.querySelector('c-create-payment-policies');
            if (child) {
                child.loadData(res);
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Policies saved successfully',
                    variant: 'success'
                })
            );
            this.dispatchEvent(new CloseActionScreenEvent());
        })

        /* .then(() => {

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Policies saved successfully',
                    variant: 'success'
                })
            );

            // ✅ CLOSE ONLY AFTER SUCCESS
            this.dispatchEvent(new CloseActionScreenEvent());
        })*/
        .catch(err => {

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: err?.body?.message || 'Failed to save policies',
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        });
    } 
    // ✏️ EDIT


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
