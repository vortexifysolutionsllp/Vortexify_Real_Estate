import { LightningElement, api } from 'lwc';
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

    //_loaded = false; 

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
                    console,log('child not found');
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

    handleEditClick() {
        let child = this.template.querySelector('c-create-payment-policies');

        if (!child) {
            console.error('Child component not found');
            return;
        }

        
        if (this.editMode) {
            let data = child.getPolicies();

            savePolicies({
                policiesJson: JSON.stringify(data),
                projectId: this.recordId
            })
            .then(() => {
                this.editMode = false;
                this.editLabel = 'Edit';
                child.toggleEditMode(false);

                // 🔁 reload fresh data from DB
                this._loaded = false;
                this.loadData();
            })
            .catch(err => {
                console.error('savePolicies error', err);
            });
        } 
        // 🟡 EDIT MODE
        else {
            this.editMode = true;
            this.editLabel = 'Save';
            child.toggleEditMode(true);
        }
    }
}
