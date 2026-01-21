import { LightningElement, track } from 'lwc';

export default class CreateCommissionPolicies extends LightningElement {
    @track policies = [this.createEmptyPolicy(1)];

    commissionOptions = [
        { label: 'Fixed', value: 'fixed' },
        { label: 'Percentage', value: 'percentage' },
        { label: 'Range', value: 'range' }
    ];

    rangeCommissionOptions = [
        { label: 'Fixed', value: 'fixed' },
        { label: 'Percentage', value: 'percentage' }
    ];

    createEmptyPolicy(index) {
    return {
        id: index,
        selectedCommissionType: '',
        isFixed: false,
        isPercentage: false,
        isRange: false,
        showStandardFields: false,
        active: true,
        isEditMode: true,

        amount: null,
        percent: null,
        upperCap: null,

        ranges: []
    };
}


    createEmptyRange(index) {
    return {
        id: index,
        commissionType: 'percentage',
        isFixed: false,
        isPercentage: true,
        active: true,

        minAmount: null,
        maxAmount: null,
        amount: null,
        percent: null,
        upperCap: null
    };
}


    handleCommissionTypeChange(event) {
        const index = event.target.dataset.index;
        const value = event.detail.value;
        let tempPolicies = [...this.policies];

        tempPolicies[index].selectedCommissionType = value;
        tempPolicies[index].isFixed = value === 'fixed';
        tempPolicies[index].isPercentage = value === 'percentage';
        tempPolicies[index].isRange = value === 'range';
        
        // Hide standard fields if nothing selected OR if Range is selected
        tempPolicies[index].showStandardFields = (value === 'fixed' || value === 'percentage');

        // Initialize first range if range is selected
        if (value === 'range' && tempPolicies[index].ranges.length === 0) {
            tempPolicies[index].ranges = [this.createEmptyRange(1)];
        }

        this.policies = tempPolicies;
    }

    handleAddPolicy() {
        this.policies = [...this.policies, this.createEmptyPolicy(this.policies.length + 1)];
    }

    handleDeletePolicy(event) {
        const index = event.target.dataset.index;
        if (this.policies.length > 1) {
            let temp = [...this.policies];
            temp.splice(index, 1);
            this.policies = temp.map((p, i) => ({ ...p, id: i + 1 }));
        }
    }

    handleAddRange(event) {
        const index = event.target.dataset.index;
        let temp = [...this.policies];
        const nextRangeId = temp[index].ranges.length + 1;
        temp[index].ranges.push(this.createEmptyRange(nextRangeId));
        this.policies = temp;
    }

    handleDeleteRange(event) {
        const pIndex = event.target.dataset.policyIndex;
        const rIndex = event.target.dataset.rangeIndex;
        let temp = [...this.policies];
        temp[pIndex].ranges.splice(rIndex, 1);
        this.policies = temp;
    }

    handleRangeTypeChange(event) {
        const pIndex = event.target.dataset.policyIndex;
        const rIndex = event.target.dataset.rangeIndex;
        const value = event.detail.value;
        let temp = [...this.policies];
        
        temp[pIndex].ranges[rIndex].commissionType = value;
        temp[pIndex].ranges[rIndex].isFixed = value === 'fixed';
        temp[pIndex].ranges[rIndex].isPercentage = value === 'percentage';
        
        this.policies = temp;
    }

    buildPolicyPayload() {
    return this.policies.map(p => {
        let payload = {
            policyType: p.selectedCommissionType,
            active: p.active
        };

        if (p.selectedCommissionType === 'fixed') {
            payload.fixed = {
                amount: p.amount
            };
        }

        if (p.selectedCommissionType === 'percentage') {
            payload.percentage = {
                percent: p.percent,
                upperCap: p.upperCap
            };
        }

        if (p.selectedCommissionType === 'range') {
            payload.ranges = p.ranges.map(r => {
                let rangeObj = {
                    minAmount: r.minAmount,
                    maxAmount: r.maxAmount,
                    commissionType: r.commissionType,
                    active: r.active
                };

                if (r.commissionType === 'fixed') {
                    rangeObj.amount = r.amount;
                }

                if (r.commissionType === 'percentage') {
                    rangeObj.percent = r.percent;
                    rangeObj.upperCap = r.upperCap;
                }

                return rangeObj;
            });
        }

        return payload;
    });
}

handleEditSave(event) {
    const index = event.target.dataset.index;
    let temp = [...this.policies];

    if (temp[index].isEditMode) {
        // SAVE
const json = this.buildPolicyJSON(temp[index]);
        // 🔥 Send payload[index] to Apex
        // Example:
        // savePolicy({ jsonData: JSON.stringify(payload[index]) });

console.log('SAVING POLICY JSON', JSON.stringify(json));

        temp[index].isEditMode = false;
    } else {
        // EDIT
        temp[index].isEditMode = true;
    }

    this.policies = temp;
}
handlePolicyFieldChange(event) {
    const index = event.target.dataset.index;
    const field = event.target.dataset.field;

    let temp = [...this.policies];
    temp[index][field] =
        event.target.type === 'checkbox'
            ? event.target.checked
            : event.target.value;

    this.policies = temp;
}
handleRangeFieldChange(event) {
    const pIndex = event.target.dataset.policyIndex;
    const rIndex = event.target.dataset.rangeIndex;
    const field = event.target.dataset.field;

    let temp = [...this.policies];
    temp[pIndex].ranges[rIndex][field] =
        event.target.type === 'checkbox'
            ? event.target.checked
            : event.target.value;

    this.policies = temp;
}
buildPolicyJSON(policy) {
    let obj = {
        policyType: policy.selectedCommissionType,
        active: policy.active
    };

    if (policy.selectedCommissionType === 'fixed') {
        obj.fixed = { amount: policy.amount };
    }

    if (policy.selectedCommissionType === 'percentage') {
        obj.percentage = {
            percent: policy.percent,
            upperCap: policy.upperCap
        };
    }

    if (policy.selectedCommissionType === 'range') {
        obj.ranges = policy.ranges.map(r => {
            let rangeObj = {
                minAmount: r.minAmount,
                maxAmount: r.maxAmount,
                commissionType: r.commissionType,
                active: r.active
            };

            if (r.commissionType === 'fixed') {
                rangeObj.amount = r.amount;
            }

            if (r.commissionType === 'percentage') {
                rangeObj.percent = r.percent;
                rangeObj.upperCap = r.upperCap;
            }

            return rangeObj;
        });
    }

    return obj;
}
get policiesWithIcons() {
    return this.policies.map(p => ({
        ...p,
        editIcon: p.isEditMode ? 'utility:save' : 'utility:edit'
    }));
}

}