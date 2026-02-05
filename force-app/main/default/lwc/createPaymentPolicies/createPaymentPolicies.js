import { LightningElement, track, api } from 'lwc';

export default class CreatePaymentPolicies extends LightningElement {

    @track project = {};
    @track policies = [];
    projectDisabled = true;
    @track deletedPolicyIds = [];


  @api
    loadData(data){
    this.project = {
        Name : data.project.Name,
        Location__c : data.project.Location__c,
        RERA_Number__c : data.project.RERA_Number__c,
        towers: data.towerCount,
        units: data.unitCount
    };
    const dataFromChild = data.isDataFromChild;
    if(dataFromChild){
        this.policies = data.policies;
    }

    else if(data.policies && data.policies.length){
        this.policies = data.policies.filter(p => p.Type__c && p.Type__c.toLowerCase().includes('payment'))
        .map((p,i)=>{
            

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
                    paymentWithin: t.paymentWithin ?? t.paymentWithIn,
                    //paymentWithin: t.paymentWithin ?? t.paymentWithIn ?? '',
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

    // handleAddPolicy() {
    //     this.policies = [...this.policies, {
    //         id: Date.now(),
    //         serial: this.policies.length + 1,
    //         name: '',
    //         abbr: '',
    //         cost: '',
    //         isConstructionLinked: false,
    //         isDisabled: false,
    //         terms: []
    //     }];
    // }

       handleAddPolicy() {
    const newPolicy = {
        id: Date.now(),
        serial: 1,
        name: '',
        abbr: '',
        cost: '',
        isConstructionLinked: false,
        isDisabled: false,
        terms: []
    };

    // Add new policy at the TOP
    this.policies = [newPolicy, ...this.policies];

    // Fix serial numbers
    this.reindex();
     this.sendPoliciesToParent(this.policies);
}




    handleEditPolicy(event) {
        let index = event.currentTarget.dataset.index;
        this.policies[index].isDisabled = false;
        //this.policies[index].terms.forEach(t => t.isDisabled = false);
        this.policies = [...this.policies];
    }
    handleDeletePolicy(event) {
        /*let index = Number(event.currentTarget.dataset.index);  
        this.policies.splice(index, 1);
        this.reindex();
        this.policies = [...this.policies];*/
        let index = Number(event.currentTarget.dataset.index);  

    let deleted = this.policies[index];

    // ⭐ TRACK ONLY REAL SALESFORCE IDS
    if (deleted.id && (String(deleted.id).length === 15 || String(deleted.id).length === 18)) {
        this.deletedPolicyIds.push(deleted.id);
    }

    this.policies.splice(index, 1);
    this.reindex();
    this.policies = [...this.policies];
     this.sendPoliciesToParent();


    }



    // ========= TERM HANDLERS =========

    // Handle position of terms
    handleAddTerm(event){
    let index = event.currentTarget.dataset.index;

    const newTerm = {
        id: Date.now(),
        serial: 1,
        termName:'',
        percent:'',
        paymentWithin:'',
        isDisabled:false
    };

    this.policies[index].terms = [newTerm, ...this.policies[index].terms];

    this.reindexTerms(index);
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

   /* let names = this.policies.map(p => p.name?.toLowerCase());
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
    });*/

    
    // Duplicate Policy Name Validation
    
    let names = this.policies
        .map(p => p.name?.trim().toLowerCase())
        .filter(n => n);

    let set = new Set(names);
    if (names.length !== set.size) {
        throw new Error('Duplicate policy names are not allowed.');
    }

    
    // Policy & Term Validation
   
    this.policies.forEach((p, pIndex) => {

        let policyName = p.name?.trim();

        // Policy Name required
        if (!policyName) {
            throw new Error(`Policy Name is required for Policy ${pIndex + 1}.`);
        }

        // Policy name must contain at least one alphabet
        if (!/[a-z]/i.test(policyName)) {
            throw new Error(
                `Policy Name "${p.name}" must contain at least one alphabet. Only numbers are not allowed.`
            );
        }

        let rawCost = (p.cost ?? '').toString().trim();
        let costValue = Number(rawCost);

        if (rawCost === '' || isNaN(costValue)) { 
            throw new Error(`Cost / Sqft cannot be null and must be a number in Policy "${p.name || pIndex + 1}".`);
        }

        if (costValue < 0) {
            throw new Error(`Cost / Sqft cannot be negative in Policy "${p.name || pIndex + 1}".`);
        }

        // Policy must have at least one term
        if (!p.terms || p.terms.length === 0) {
            throw new Error(`Policy "${p.name || pIndex + 1}" must have at least one term.`);
        }

        let totalPercent = 0; 
        let termNameSet = new Set(); 
        p.terms.forEach((t, tIndex) => {

            let termName = t.termName?.trim().toLowerCase();
            let percentRaw = (t.percent ?? '').toString().trim();
            let paymentRaw = (t.paymentWithin ?? '').toString().trim();

            let percent = Number(percentRaw);
            let paymentWithin = Number(paymentRaw);

            // Duplicate Term Name Check
            if (termNameSet.has(termName)) {
                throw new Error(
                    `Duplicate term name "${t.termName}" in Policy "${p.name || pIndex + 1}".`
                );
            }
            termNameSet.add(termName);

            // Term Name required
            if (!termName) {
                throw new Error(
                    `Term Name is required in Policy "${p.name || pIndex + 1}" (Term ${tIndex + 1}).`
                );
            }

            // Term name must contain at least one alphabet
            if (!/[a-z]/i.test(t.termName)) {
                throw new Error(
                    `Term Name "${t.termName}" must contain at least one alphabet in Policy "${p.name || pIndex + 1}" (Term ${tIndex + 1}). Only numbers are not allowed.`
                );
            }

            // Percentage required and must be number
            if (percentRaw === '' || isNaN(percent)) {
                throw new Error(
                    `Percentage is required in Policy "${p.name || pIndex + 1}" (Term ${tIndex + 1}).`
                );
            }

            // Prevent negative percentages
            if (percent < 0) {
                throw new Error(
                    `Percentage cannot be negative in Policy "${p.name || pIndex + 1}" (Term ${tIndex + 1}).`
                );
            }

            //  If % entered (>0), Payment Within required and >0
            if (percent > 0) {
                if (paymentRaw === '' || isNaN(paymentWithin) || paymentWithin <= 0) {
                    throw new Error(
                        `Payment Within must be greater than 0 when Percentage is entered in Policy "${p.name || pIndex + 1}" (Term ${tIndex + 1}).`
                    );
                }
            }

            totalPercent += percent;
        });

        // TOTAL % VALIDATION PER POLICY
        if (Math.round(totalPercent * 100) / 100 !== 100) {
            throw new Error(
                `Total percentage for Policy "${p.name || pIndex + 1}" must be exactly 100. Current total: ${totalPercent}.`
            );
        }
    });

    
    // RETURN CLEAN DATA TO PARENT
    
    return {
        policies: this.policies.map(p => {
            let finalId = null;

            // ONLY SEND REAL SALESFORCE IDS
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
        }),
        deletedPolicyIds: this.deletedPolicyIds
    };
}

// getPolicies() {
//    /* let names = this.policies.map(p => p.name?.toLowerCase());
//     let set = new Set(names);
//     if(names.length !== set.size){
//         throw new Error('Duplicate policy names are not allowed.');
//     }

//     return this.policies.map(p => {
//         let finalId = null;

//         // ⭐ ONLY SEND REAL SALESFORCE IDS
//         if (p.id && (String(p.id).length === 15 || String(p.id).length === 18)) {
//             finalId = p.id;
//         }

//         return {
//             id: finalId,
//             name: p.name,
//             abbr: p.abbr,
//             cost: p.cost,
//             isConstructionLinked: p.isConstructionLinked,
//             terms: p.terms
//         };
//     });*/

//     // Duplicate Policy Name Validation 
//     let names = this.policies
//         .map(p => p.name?.trim().toLowerCase())
//         .filter(n => n);

//     let set = new Set(names);
//     if (names.length !== set.size) {
//         throw new Error('Duplicate policy names are not allowed.');
//     }

//     // Term Validation
//     this.policies.forEach((p, pIndex) => {
//         let rawCost = (p.cost ?? '').toString().trim();
//         let costValue = Number(rawCost);

//         if (rawCost === '' || isNaN(costValue)) { 
//         throw new Error(`Cost / Sqft cannot be null and must be a number in Policy "${p.name || pIndex + 1}".`);
//     }

//     if (costValue < 0) {
//         throw new Error(`Cost / Sqft cannot be negative in Policy "${p.name || pIndex + 1}".`);
//     }

//         // Policy must have at least one term
//         if (!p.terms || p.terms.length === 0) {
//             throw new Error(`Policy "${p.name || pIndex + 1}" must have at least one term.`);
//         }

//         let totalPercent = 0; 
//         let termNameSet = new Set();

//         p.terms.forEach((t, tIndex) => {

//             let termName = t.termName?.trim().toLowerCase();
//             let percent = Number(t.percent);
//             let paymentWithin = Number(t.paymentWithin);
//              if (termNameSet.has(termName)) {
//             throw new Error(
//                 `Duplicate term name "${t.termName}" in Policy "${p.name || pIndex + 1}".`
//             );
//         }
//         termNameSet.add(termName);

//             // Individual term field validation
//             if (
//                 !termName ||
//                 isNaN(percent) ||
//                 isNaN(paymentWithin)
//             ) {
//                 throw new Error(
//                     `All term fields are required in Policy "${p.name || pIndex + 1}" (Term ${tIndex + 1}).`
//                 );
//             }

//             // Prevent negative percentages
//             if (percent < 0) {
//                 throw new Error(
//                     `Percentage cannot be negative in Policy "${p.name || pIndex + 1}" (Term ${tIndex + 1}).`
//                 );
//             }

//             totalPercent += percent; // Add each term % to total
//         });

//         // TOTAL % VALIDATION PER POLICY
//        if (Math.round(totalPercent * 100) / 100 !== 100) {
//             throw new Error(
//                 `Total percentage for Policy "${p.name || pIndex + 1}" must be exactly 100. Current total: ${totalPercent}.`
//             );
//         }

//     });
//     //Term validation ends


//     return {
//         policies: this.policies.map(p => {
//             let finalId = null;

//             // ⭐ ONLY SEND REAL SALESFORCE IDS
//             if (p.id && (String(p.id).length === 15 || String(p.id).length === 18)) {
//                 finalId = p.id;
//             }

//             return {
//                 id: finalId,
//                 name: p.name,
//                 abbr: p.abbr,
//                 cost: p.cost,
//                 isConstructionLinked: p.isConstructionLinked,
//                 terms: p.terms
//             };
//         }),
//         deletedPolicyIds: this.deletedPolicyIds
//     };

// }


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

    sendPoliciesToParent() {
    const payload = {
        isPaymentPolicies:true,
        isDataFromChild:true,
        project: this.project,
        policies: this.policies,
        deletedPolicyIds: this.deletedPolicyIds
    };

    // Dispatch the event
    this.dispatchEvent(new CustomEvent('policiesupdate', {
        detail: payload,
        bubbles: true,   // optional, allows event to bubble up
        composed: true   // optional, allows event to cross shadow DOM boundaries
    }));
}

}