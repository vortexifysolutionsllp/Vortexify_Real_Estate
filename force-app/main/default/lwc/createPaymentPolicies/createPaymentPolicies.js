import { LightningElement, track, api } from 'lwc';

export default class CreatePaymentPolicies extends LightningElement {
    //parent_data = this.recordId;

    @track isViewMode = true;

    @track project = {};

    @track policies = [
        {
            id: 1,
            serial: 1,
            name: '',
            abbr: '',
            cost: '',
            isDisabled: true,
            terms: [
                {
                    id: 1,
                    serial: 1,
                    termName: '',
                    percent: '',
                    paymentWithIn: '',
                    isDisabled: true
                }
            ]
        }
    ];
    @api
    loadData(data){
        console.log('CHILD RECEIVED DATA = ', JSON.stringify(data));

        this.project = {
            name : data.project.Name,
            location : data.project.Location__c,
            rera : data.project.RERA_Number__c,
            towers : data.towerCount,
            units : data.project.Number_of_Units__c
        };

        if(data.policies && data.policies.length){

            this.policies = data.policies.map((p,i)=>{

                let terms = [];

                if(p.Term__c){
                    terms = JSON.parse(p.Term__c).map((t,idx)=>({
                        id: Date.now()+idx,
                        serial: idx+1,
                        termName: t.termName,
                        percent: t.percent,
                        paymentWithIn: t.paymentWithIn,
                        isDisabled: true
                    }));
                }

                return{
                    id: p.Id,
                    serial: i+1,
                    name: p.Name,
                    abbr: p.Abbreviation__c,
                    cost: p.Cost_Sqft__c,
                    isDisabled: true,
                    terms: terms
                }
            });
        }
    }

    @api
    toggleEditMode(isEdit) {

        this.isViewMode = !isEdit;

        let temp = JSON.parse(JSON.stringify(this.policies));

        temp.forEach(policy => {
            policy.isDisabled = !isEdit;

            policy.terms.forEach(term => {
                term.isDisabled = !isEdit;
            });
        });

        this.policies = temp;
    }

    @api
    getPolicies(){
        return this.policies;
    }

    addPolicy() {
        let newId = this.policies.length + 1;

        let newPolicy = { 
            id: newId, 
            serial: newId, 
            name: '', 
            abbr: '', 
            cost: '', 
            isDisabled: true,
            terms: []
        };

        this.policies = [...this.policies, newPolicy];
    }

    deletePolicy(event) {
        let index = event.currentTarget.dataset.index;
        this.policies.splice(index, 1);

        this.policies = this.policies.map((p, i) => ({
            ...p,
            serial: i + 1
        }));
    }

    editPolicy(event) {
        let index = event.currentTarget.dataset.index;
        this.policies[index].isDisabled = false;
        this.policies = [...this.policies];
    }

    savePolicy(event) {
        let index = event.currentTarget.dataset.index;
        this.policies[index].isDisabled = true;
        this.policies = [...this.policies];
    }

    addTerm(event) {
        let index = event.currentTarget.dataset.index;
        let temp = JSON.parse(JSON.stringify(this.policies));

        temp[index].terms.push({ 
            id: Date.now(), 
            serial: temp[index].terms.length + 1, 
            termName: '', 
            percent: '', 
            paymentWithIn: '', 
            isDisabled: true 
        });

        this.policies = temp;
    }

    deleteTerm(event) {
        let policyIndex = event.currentTarget.dataset.index;
        let termIndex = event.currentTarget.dataset.termIndex;

        let temp = JSON.parse(JSON.stringify(this.policies));
        temp[policyIndex].terms.splice(termIndex, 1);

        temp[policyIndex].terms = temp[policyIndex].terms.map((t, i) => ({
            ...t,
            serial: i + 1
        }));

        this.policies = temp;
    }

    handlePolicyChange(event) {
        let index = event.currentTarget.dataset.index;
        let field = event.currentTarget.dataset.field;

        this.policies[index][field] = event.target.value;
        this.policies = [...this.policies];
    }

    handleTermChange(event) {
        let index = event.currentTarget.dataset.index;
        let termIndex = event.currentTarget.dataset.termIndex;
        let field = event.currentTarget.dataset.field;

        this.policies[index].terms[termIndex][field] = event.target.value;
        this.policies = [...this.policies];
    }

    handleEdit(event) {
        let pIndex = event.currentTarget.dataset.index;
        let tIndex = event.currentTarget.dataset.termIndex;

        this.policies[pIndex].terms[tIndex].isDisabled = false;
        this.policies = [...this.policies];
    }

    handleSave(event) {
        let pIndex = event.currentTarget.dataset.index;
        let tIndex = event.currentTarget.dataset.termIndex;

        this.policies[pIndex].terms[tIndex].isDisabled = true;
        this.policies = [...this.policies];
    }
}
