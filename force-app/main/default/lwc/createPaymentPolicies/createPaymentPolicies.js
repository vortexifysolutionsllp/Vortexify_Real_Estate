import { LightningElement, track, api } from 'lwc';

export default class CreatePaymentPolicies extends LightningElement {

    @track project = {};
    @track policies = [];
    projectDisabled = true;

  @api
loadData(data){
    this.project = {
        Name : data.project.Name,
        Location__c : data.project.Location__c,
        RERA_Number__c : data.project.RERA_Number__c,
        towers: data.towerCount,
        units: data.unitCount
    };

    if(data.policies && data.policies.length){
        this.policies = data.policies.map((p,i)=>{

            // 🔴 SAFE TERM PARSING START
            let termsArray = [];

            if (p.Term__c) {
                try {
                    let parsed = JSON.parse(p.Term__c);

                    if (Array.isArray(parsed)) {
                        termsArray = parsed;
                    } else if (typeof parsed === 'object') {
                        termsArray = [parsed];
                    }
                } catch (e) {
                    console.error('Invalid Term__c JSON for policy', p.Id, p.Term__c);
                    termsArray = [];
                }
            }
            // 🔴 SAFE TERM PARSING END

            return {
                id: p.Id,
                serial: i+1,
                name: p.Name,
                abbr: p.Abbreviation__c,
                cost: p.Cost_Sqft__c,
                isConstructionLinked: p.Construction_Linked__c || false,
                isDisabled: true,
                terms: termsArray.map((t,ti)=>({
                    id: Date.now()+ti,
                    serial: ti+1,
                    termName: t.termName,
                    percent: t.percent,
                    paymentWithin: t.paymentWithIn,
                    isDisabled: true
                }))
            };
        });
    }
}

   /* @api
    loadData(data){
        this.project = {
            Name : data.project.Name,
            Location__c : data.project.Location__c,
            RERA_Number__c : data.project.RERA_Number__c,
            towers: data.towerCount,
            units: data.unitCount
        };

        if(data.policies && data.policies.length){
            this.policies = data.policies.map((p,i)=>({
                id: p.Id,
                serial: i+1,
                name: p.Name,
                abbr: p.Abbreviation__c,
                cost: p.Cost_Sqft__c,
                isConstructionLinked: p.Construction_Linked__c || false,
                isDisabled: true,
                terms: p.Term__c ? JSON.parse(p.Term__c).map((t,ti)=>({
                    id: Date.now()+ti,
                    serial: ti+1,
                    termName: t.termName,
                    percent: t.percent,
                    paymentWithin: t.paymentWithIn,
                    isDisabled: true
                })) : []
            }));
        }
    }*/

    // ⭐ ADD THIS
    @api
    toggleEditMode(flag) {

        this.projectDisabled = !flag;
        this.policies = this.policies.map(p => {
            return {
                ...p,
                isDisabled: !flag,
                terms: p.terms.map(t => ({
                    ...t,
                    isDisabled: !flag
                }))
            };
        });
    }

    // ========= POLICY HANDLERS =========

    handleAddPolicy() {
        this.policies = [...this.policies, {
            id: Date.now(),
            serial: this.policies.length + 1,
            name: '',
            abbr: '',
            cost: '',
            isConstructionLinked: false,
            isDisabled: false,
            terms: []
        }];
    }

    handleEditPolicy(event) {
        let index = event.currentTarget.dataset.index;
        this.policies[index].isDisabled = false;
        //this.policies[index].terms.forEach(t => t.isDisabled = false);
        this.policies = [...this.policies];
    }
    handleDeletePolicy(event) {
        let index = Number(event.currentTarget.dataset.index);  // 🔴 FINAL FIX
        this.policies.splice(index, 1);
        this.reindex();
        this.policies = [...this.policies];
    }



    // ========= TERM HANDLERS =========

    handleAddTerm(event){
        let index = event.currentTarget.dataset.index;
        this.policies[index].terms.push({
            id: Date.now(),
            serial: this.policies[index].terms.length + 1,
            termName:'',
            percent:'',
            paymentWithin:'',
            isDisabled:false
        });
        this.policies = [...this.policies];
    }

    handleEditTerm(event){
        let p = event.currentTarget.dataset.pindex;
        let t = event.currentTarget.dataset.tindex;
        this.policies[p].terms[t].isDisabled = false;
        this.policies = [...this.policies];
    }

    handleDeleteTerm(event){
        let p = event.currentTarget.dataset.pindex;
        let t = event.currentTarget.dataset.tindex;
        this.policies[p].terms.splice(t,1);
        this.reindexTerms(p);
        
    }

    // ========= FIELD UPDATES =========

    handleNameChange(e){ this.policies[e.target.dataset.index].name = e.target.value; this.policies=[...this.policies]; }
    handleAbbrChange(e){ this.policies[e.target.dataset.index].abbr = e.target.value; this.policies=[...this.policies]; }
    handleCostChange(e){ this.policies[e.target.dataset.index].cost = e.target.value; this.policies=[...this.policies]; }

    handleTermNameChange(e){ this.policies[e.target.dataset.pindex].terms[e.target.dataset.tindex].termName = e.target.value; this.policies=[...this.policies]; }
    handleTermPercentChange(e){ this.policies[e.target.dataset.pindex].terms[e.target.dataset.tindex].percent = e.target.value; this.policies=[...this.policies]; }
    handleTermPaymentChange(e){ this.policies[e.target.dataset.pindex].terms[e.target.dataset.tindex].paymentWithin = e.target.value; this.policies=[...this.policies]; }

    // ========= SINGLE CHECKBOX =========

    handleConstructionLinkedChange(event){
        let index = event.target.dataset.index;
        this.policies.forEach((p,i)=> p.isConstructionLinked = (i == index));
        this.policies = [...this.policies];
    }

    // ========= SAVE VALIDATION =========

            @api
        getPolicies() {
            let names = this.policies.map(p => p.name?.toLowerCase());
            let set = new Set(names);
            if(names.length !== set.size){
                throw new Error('Duplicate policy names are not allowed.');
            }

            return this.policies.map(p => {
                let finalId = null;

                // ⭐ ONLY SEND REAL SALESFORCE IDS
                if (p.id && (String(p.id).length === 15 || String(p.id).length === 18)) {
                    finalId = p.id;
                }

                return {
                    id: finalId,
                    name: p.name,
                    abbr: p.abbr,
                    cost: p.cost,
                    isConstructionLinked: p.isConstructionLinked,
                    terms: p.terms
                };
            });
        }


  /*  @api
    getPolicies() {
        let names = this.policies.map(p => p.name?.toLowerCase());
        let set = new Set(names);
        if(names.length !== set.size){
         throw new Error('Duplicate policy names are not allowed.');
       
}
        

        return this.policies.map(p => ({
            id: p.id,
            name: p.name,
            abbr: p.abbr,
            cost: p.cost,
            isConstructionLinked: p.isConstructionLinked,
            terms: p.terms
        }));
    }*/

    // ========= UTILS =========

    reindex(){
        this.policies = this.policies.map((p,i)=>({...p, serial:i+1}));
    }

    reindexTerms(pIndex){
        this.policies[pIndex].terms = this.policies[pIndex].terms.map((t,i)=>({...t, serial:i+1}));
        this.policies=[...this.policies];
    }
}

