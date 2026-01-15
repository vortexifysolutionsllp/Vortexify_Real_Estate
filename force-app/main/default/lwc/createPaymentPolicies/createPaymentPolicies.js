import { LightningElement, track } from 'lwc';

export default class CreatePaymentPolicies extends LightningElement {

    @track policies = [
        {
            id: 1, serial: 1, name: '', abbr: '', cost: '',
            terms: [
                { id: 1, serial: 1, name: '', percent: '', paymentWithIn: '', isDisabled: true}
            ]
        }
    ];

    //this method add the policy
    addPolicy() {
        let newId = this.policies.length + 1;

        let newPolicy = { id: newId, serial: newId, name: '', abbr: '', cost: '', terms: [], isDisabled: true};

        this.policies = [...this.policies, newPolicy];
    }

    //this method deletes the policy
    deletePolicy(event) {
        let index = event.target.dataset.index;
        this.policies.splice(index, 1);

        this.policies = this.policies.map((p, i) => ({
            ...p,
            serial: i + 1
        }));
    }

    // this method add the 'Terms'
    addTerm(event) {
        let index = event.target.dataset.index;
        let temp = JSON.parse(JSON.stringify(this.policies));
        let terms = temp[index].terms;

        terms.push({ id: Date.now(), serial: terms.length + 1, name: '', percent: '', paymentWithIn: '', isDisabled: true });

        this.policies = temp;
    }

    // this method delete the 'Terms'
    deleteTerm(event) {

        let policyIndex = event.target.dataset.index;
        let termIndex = event.target.dataset.termIndex;

        let temp = JSON.parse(JSON.stringify(this.policies));

        temp[policyIndex].terms.splice(termIndex, 1);

        // this will Re-index the 'terms'
        temp[policyIndex].terms = temp[policyIndex].terms.map((t, i) => ({
            ...t,
            serial: i + 1
        }));

        this.policies = temp;
    }

    handlePolicyChange(event) {

        let index = event.target.dataset.index;
        let field = event.target.dataset.field;

        this.policies[index][field] = event.target.value;
        this.policies = [...this.policies];
    }

    handleTermChange(event) {

        let index = event.target.dataset.index;
        let termIndex = event.target.dataset.termIndex;
        let field = event.target.dataset.field;

        this.policies[index].terms[termIndex][field] = event.target.value;
        this.policies = [...this.policies];
    }

    handleEdit(event) {

        let pIndex = event.target.dataset.index;
        let tIndex = event.target.dataset.termIndex;

        this.policies[pIndex].terms[tIndex].isDisabled = false;
        this.policies = [...this.policies];
    }

    handleSave(event) {

        let pIndex = event.target.dataset.index;
        let tIndex = event.target.dataset.termIndex;

        this.policies[pIndex].terms[tIndex].isDisabled = true;
        this.policies = [...this.policies];
    }

}
