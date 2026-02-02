import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import fetchPolicyData from '@salesforce/apex/PolicyController.fetchPolicyData';
import savePolicies from '@salesforce/apex/PolicyController.savePolicies';
import saveCommissionPolicy from '@salesforce/apex/CommissionPolicyController.saveCommissionPolicy';
import deleteCommissionPolicies from '@salesforce/apex/CommissionPolicyController.deleteCommissionPolicies';


export default class CreateProjectPolicies extends LightningElement {

    @api recordId;

    selectedPolicy = 'Payment';
    showPayment = true;
    showCommission = false;

    policyData;        
    _loaded = false;
    hasPolicy = true; 

    editMode = false;
    editLabel = 'Edit';

    _loaded = false; // 🔴 KEPT EXACTLY AS YOU HAD IT
    _cachedPolicyData = null; // 🆕 store last loaded policy data


    policyOptions = [
        { label: 'Payment', value: 'Payment' },
        { label: 'Commission', value: 'Commission' }
    ];

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
    }

    renderedCallback() {
        if (this._loaded) return;
        this._loaded = true;

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
                this.policyData = res;          
                this.injectDataIntoChild();     
            })
            .catch(err => {
                console.error(err);
                this.showToast('Error', 'Failed to load policy data', 'error');
            });
    }

    injectDataIntoChild() {
        let child;

        if (this.showPayment) {
            child = this.template.querySelector('c-create-payment-policies');
        } else if (this.showCommission) {
            child = this.template.querySelector('c-create-commission-policies');
        }

        if (child && child.loadData && this.policyData) {
            child.loadData(this.policyData);
        }
    }

    handlePolicyChange(event) {
        this.selectedPolicy = event.target.value;
        this.showPayment = this.selectedPolicy === 'Payment';
        this.showCommission = this.selectedPolicy === 'Commission';

            setTimeout(() => {
            this.injectDataIntoChild();
        }, 0);
    }

    get isPayment() {
        return this.selectedPolicy === 'Payment';
    }

    get isCommission() {
        return this.selectedPolicy === 'Commission';
    }


    handleEditClick() {

    if (this.showPayment) {
        this.savePaymentPolicies();
        return;
    }

    if (this.showCommission) {
        this.saveCommissionPolicies();
    }
    }

    savePaymentPolicies() {
    const child = this.template.querySelector('c-create-payment-policies');
    if (!child) return;

    let data;
    try {
        data = child.getPolicies();
    } catch (e) {
        this.showToast('Validation Error', e.message, 'error');
        return;
    }

    savePolicies({
            policiesJson: JSON.stringify(data.policies),
            deletedPolicyIds: data.deletedPolicyIds,
            projectId: this.recordId
        })
    .then(() => {
        this.showToast('Success', 'Policies saved successfully', 'success');
        this.dispatchEvent(new CloseActionScreenEvent());
    })
    .catch(err => {
        this.showToast(
            'Error',
            err?.body?.message || 'Failed to save policies',
            'error'
        );
    });
    }

 saveCommissionPolicies() {
    const child = this.template.querySelector('c-create-commission-policies');
    if (!child) return;

    let result;
    try {
        result = child.getPolicies(); 
    } catch (e) {
        this.showToast('Validation Error', e.message, 'error');
        return;
    }

    const policies = result.policies;
    const deletedPolicyIds = result.deletedPolicyIds;

    const deletePromise = deletedPolicyIds.length
        ? deleteCommissionPolicies({ policyIds: deletedPolicyIds })
        : Promise.resolve();

    deletePromise
        .then(() =>
            Promise.all(
                policies.map(p =>
                    saveCommissionPolicy({
                        policyJson: JSON.stringify(p.payload),
                        projectId: this.recordId,
                        policyId: p.policyId
                    })
                )
            )
        )
        .then(() => {
            this.showToast(
                'Success',
                'Commission policies saved successfully',
                'success'
            );
            this.dispatchEvent(new CloseActionScreenEvent());
        })*/
        .catch(err => {
            this.showToast(
                'Error',
                err?.body?.message || 'Failed to save commission policies',
                'error'
            );
        });
}




        handleCancel() {
            this.dispatchEvent(new CloseActionScreenEvent());
        }

        showToast(title, message, variant) {
            this.dispatchEvent(
                new ShowToastEvent({ title, message, variant })
            );
        }
    }
        