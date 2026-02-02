import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CreateCommissionPolicies extends LightningElement {
    @api recordId; 
    @track project = {};
    @track policies = [this.createEmptyPolicy(1)];
    @track deletedPolicyIds = [];


    @api
    loadData(data) {
    // ---------- Project info ----------
    this.project = {
        Name: data.project.Name,
        Location__c: data.project.Location__c,
        RERA_Number__c: data.project.RERA_Number__c,
        towers: data.towerCount,
        units: data.unitCount
    };

    if (!data.policies || !data.policies.length) {

        this.policies = [this.createEmptyPolicy(1)];
        return;
    }

    // Track active policy per commission type
    const activeTracker = {};

    const commissionPolicies = data.policies
        .filter(p => {
            if (!p.Term__c) return false;
            try {
                const parsed = JSON.parse(p.Term__c);
                return !!parsed.policyType;
            } catch {
                return false;
            }
        })
        .map((p, index) => {
            const parsed = JSON.parse(p.Term__c);

            // ---------- Normalize ACTIVE ----------
            let isActive = parsed.active === true;

            if (isActive) {
                if (activeTracker[parsed.policyType]) {
                    // duplicate active → force inactive
                    isActive = false;
                } else {
                    activeTracker[parsed.policyType] = true;
                }
            }

            const policy = {
                id: index + 1,
                recordId: p.Id,
                selectedCommissionType: parsed.policyType,
                active: isActive,
                isEditMode: false,
                showStandardFields: parsed.policyType !== 'range',
                isFixed: parsed.policyType === 'fixed',
                isPercentage: parsed.policyType === 'percentage',
                isRange: parsed.policyType === 'range',
                amount: parsed.amount ?? null,
                percent: parsed.percent ?? null,
                upperCap: parsed.upperCap ?? null,
                ranges: []
            };

            // ---------- Handle RANGE ----------
            if (parsed.policyType === 'range' && Array.isArray(parsed.ranges)) {
                policy.ranges = parsed.ranges.map((r, ri) => ({
                    id: ri + 1,
                    minAmount: r.minAmount ?? null,
                    maxAmount: r.maxAmount ?? null,
                    commissionType: r.commissionType,
                    isFixed: r.commissionType === 'fixed',
                    isPercentage: r.commissionType === 'percentage',
                    amount: r.amount ?? null,
                    percent: r.percent ?? null,
                    upperCap: r.upperCap ?? null,
                    active: r.active ?? true
                }));
            }

            return policy;
        });

    this.policies = commissionPolicies.length
        ? commissionPolicies
        : [this.createEmptyPolicy(1)];
}



    commissionOptions = [
        { label: 'Fixed', value: 'fixed' },
        { label: 'Percentage', value: 'percentage' },
        { label: 'Range', value: 'range' }
    ];

    rangeCommissionOptions = [
        { label: 'Fixed', value: 'fixed' },
        { label: 'Percentage', value: 'percentage' }
    ];

    /**
     * Helper to get the Project ID with a fallback.
     * If @api recordId is null (common in Quick Actions), it pulls from the URL.
     */
    get effectiveRecordId() {
        if (this.recordId) return this.recordId;

        // Fallback for Quick Actions: Extract ID from URL parameters
        const urlParams = new URLSearchParams(window.location.search);
        const contextId = urlParams.get('recordId') || urlParams.get('id');
        
        // If still not found, check the state/context path (specific to some modals)
        if (!contextId) {
            const pathParts = window.location.pathname.split('/');
            const recordIdx = pathParts.indexOf('Project__c');
            if (recordIdx !== -1 && pathParts[recordIdx + 1]) {
                return pathParts[recordIdx + 1];
            }
        }
        return contextId;
    }

    get policiesWithIcons() {
        return this.policies.map(p => {
            const isViewMode = !p.isEditMode;
            return {
                ...p,
                editIcon: p.isEditMode ? 'utility:save' : 'utility:edit',
                buttonLabel: p.isEditMode ? 'Save' : 'Edit',
                buttonVariant: p.isEditMode ? 'brand' : 'neutral',
                isViewMode: isViewMode,
                isAmountDisabled: isViewMode || p.isPercentage,
                isPercentDisabled: isViewMode || p.isFixed,
                ranges: (p.ranges || []).map(r => ({
                    ...r,
                    isAmountDisabled: isViewMode || r.isPercentage,
                    isPercentDisabled: isViewMode || r.isFixed
                }))
            };
        });
    }

    createEmptyPolicy(index) {
        return {
            id: index, recordId: null, selectedCommissionType: '',
            isFixed: false, isPercentage: false, isRange: false,
            showStandardFields: false, active: false, isEditMode: true,
            amount: null, percent: null, upperCap: null, ranges: []
        };
    }

    createEmptyRange(index) {
        return {
            id: index, commissionType: 'percentage', isFixed: false,
            isPercentage: true, active: true, minAmount: null,
            maxAmount: null, amount: null, percent: null, upperCap: null
        };
    }

    handleEditSave(event) {
    const index = event.target.dataset.index;
    let temp = [...this.policies];

    temp[index].isEditMode = !temp[index].isEditMode;
    this.policies = temp;
}


    buildPolicyJSON(policy) {
    const clean = (v) => (v === '' || v === undefined) ? null : v;

    let obj = {
        policyType: policy.selectedCommissionType,
        active: policy.active === true
    };

    if (policy.selectedCommissionType === 'fixed') {
        obj.amount = clean(policy.amount);
    } else if (policy.selectedCommissionType === 'percentage') {
        obj.percent = clean(policy.percent);
        obj.upperCap = clean(policy.upperCap);
    } else if (policy.selectedCommissionType === 'range') {
        obj.ranges = policy.ranges.map(r => ({
            minAmount: clean(r.minAmount),
            maxAmount: clean(r.maxAmount),
            commissionType: r.commissionType,
            active: r.active === true,
            amount: r.commissionType === 'fixed' ? clean(r.amount) : null,
            percent: r.commissionType === 'percentage' ? clean(r.percent) : null,
            upperCap: r.commissionType === 'percentage' ? clean(r.upperCap) : null
        }));
    }

    return obj;
}


   handleCommissionTypeChange(event) {
    const index = Number(event.target.dataset.index);
    const value = event.detail.value;

    const policies = [...this.policies];

    policies[index] = {
        ...policies[index],
        selectedCommissionType: value,
        isFixed: value === 'fixed',
        isPercentage: value === 'percentage',
        isRange: value === 'range',
        showStandardFields: value === 'fixed' || value === 'percentage',
        active: false, 
        ranges:
            value === 'range' && policies[index].ranges.length === 0
                ? [this.createEmptyRange(1)]
                : policies[index].ranges
    };

    this.policies = policies;
}
handlePolicyFieldChange(event) {
    const index = Number(event.target.dataset.index);
    const field = event.target.dataset.field;

    const value =
        event.target.type === 'checkbox' ||
        event.target.type === 'toggle'
            ? event.target.checked
            : event.detail.value;

    const policies = [...this.policies];
    policies[index] = {
        ...policies[index],
        [field]: value
    };

    this.policies = policies;
}


handleRangeFieldChange(event) {
    const policyIndex = Number(event.target.dataset.policyIndex);
    const rangeIndex = Number(event.target.dataset.rangeIndex);
    const field = event.target.dataset.field;

    const value =
    event.target.type === 'checkbox' ||
    event.target.type === 'toggle'
        ? event.target.checked
        : event.detail.value === ''
            ? null
            : Number(event.detail.value);


    const policies = [...this.policies];
    const policy = policies[policyIndex];
    const ranges = [...policy.ranges];
    const current = { ...ranges[rangeIndex] };

    

    current[field] = value;
    ranges[rangeIndex] = current;

    policies[policyIndex] = {
        ...policy,
        ranges
    };

    this.policies = policies;
}

handleRangeTypeChange(event) {
    const policyIndex = Number(event.target.dataset.policyIndex);
    const rangeIndex = Number(event.target.dataset.rangeIndex);
    const value = event.detail.value;

    const policies = [...this.policies];
    const policy = policies[policyIndex];
    const ranges = [...policy.ranges];
    const range = { ...ranges[rangeIndex] };

    range.commissionType = value;
    range.isFixed = value === 'fixed';
    range.isPercentage = value === 'percentage';

    ranges[rangeIndex] = range;

    policies[policyIndex] = {
        ...policy,
        ranges
    };

    this.policies = policies;
}

    handleAddPolicy() { 
        this.policies = [...this.policies, this.createEmptyPolicy(this.policies.length + 1)]; 
    }
    
    handleDeletePolicy(event) {
    const idx = Number(event.target.dataset.index);
    const policy = this.policies[idx];

    if (policy?.recordId) {
        this.deletedPolicyIds = [
            ...this.deletedPolicyIds,
            policy.recordId
        ];
    }

    this.policies = this.policies
        .filter((_, i) => i !== idx)
        .map((p, i) => ({ ...p, id: i + 1 }));
    }


handleAddRange(event) {
    const idx = Number(event.target.dataset.index);
    const policy = this.policies[idx];

    if (!policy.ranges.length) {
        this.policies = this.policies.map((p, i) =>
            i === idx
                ? { ...p, ranges: [this.createEmptyRange(1)] }
                : p
        );
        return;
    }

    const last = policy.ranges[policy.ranges.length - 1];

    if (last.minAmount == null || last.maxAmount == null) {
        this.showToast(
            'Validation Error',
            'Complete the previous range first',
            'error'
        );
        return;
    }

    const newRange = {
        ...this.createEmptyRange(policy.ranges.length + 1),
        minAmount: Number(last.maxAmount) + 1
    };

    this.policies = this.policies.map((p, i) =>
        i === idx
            ? { ...p, ranges: [...p.ranges, newRange] }
            : p
    );
}


    handleDeleteRange(event) {
    const policyIndex = Number(event.target.dataset.policyIndex);
    const rangeIndex = Number(event.target.dataset.rangeIndex);

    const policies = [...this.policies];
    const ranges = [...policies[policyIndex].ranges];

    ranges.splice(rangeIndex, 1);

    policies[policyIndex] = {
        ...policies[policyIndex],
        ranges
    };

    this.policies = policies;
}


@api
getPolicies() {
    const projectId = this.effectiveRecordId;
    if (!projectId) {
        throw new Error('Project ID not found');
    }

    const activeByType = {};

    this.policies.forEach((p, pIndex) => {

        // ---------- Basic validation ----------
        if (p.active && !p.selectedCommissionType) {
            throw new Error(`Select Commission Type before activating policy ${pIndex + 1}`);
        }

        // ---------- Only one active per type ----------
        if (p.active) {
            if (activeByType[p.selectedCommissionType]) {
                throw new Error(
                    `Only one ${p.selectedCommissionType} commission policy can be active`
                );
            }
            activeByType[p.selectedCommissionType] = true;
        }

        if (p.selectedCommissionType === 'range') {
            p.ranges.forEach((r, rIndex) => {

                if (r.commissionType === 'fixed') {
                    if (r.amount === null || r.amount === '') {
                        throw new Error(
                            `Policy ${pIndex + 1}, Range ${rIndex + 1}: Amount is required for Fixed commission`
                        );
                    }
                }

                if (r.commissionType === 'percentage') {
                    if (r.percent === null || r.percent === '') {
                        throw new Error(
                            `Policy ${pIndex + 1}, Range ${rIndex + 1}: Percentage is required for Percentage commission`
                        );
                    }

                    if (r.upperCap === null || r.upperCap === '') {
                        throw new Error(
                            `Policy ${pIndex + 1}, Range ${rIndex + 1}: Upper Cap is required for Percentage commission`
                        );
                    }
                }

                const percentValue = Number(r.percent);
                    if (isNaN(percentValue) || percentValue < 0.1 || percentValue > 100) {
                        throw new Error(
                            `Policy ${pIndex + 1}, Range ${rIndex + 1}: Percentage must be between 0.1 and 100`
                        );
                    }

                if (r.minAmount == null || r.maxAmount == null) {
                    throw new Error(
                        `Policy ${pIndex + 1}, Range ${rIndex + 1}: Min and Max are required`
                    );
                }

                if (r.maxAmount <= r.minAmount) {
                    throw new Error(
                        `Policy ${pIndex + 1}, Range ${rIndex + 1}: Max must be greater than Min`
                    );
                }

                if (rIndex > 0) {
                    const prevMax = p.ranges[rIndex - 1].maxAmount;
                    if (r.minAmount <= prevMax) {
                        throw new Error(
                            `Policy ${pIndex + 1}, Range ${rIndex + 1}: Min must be greater than ${prevMax}`
                        );
                    }
                }
            });
        }
    });

    return {
        policies: this.policies.map(p => ({
            policyId: p.recordId,
            payload: this.buildPolicyJSON(p)
        })),
        deletedPolicyIds: this.deletedPolicyIds || []
    };
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