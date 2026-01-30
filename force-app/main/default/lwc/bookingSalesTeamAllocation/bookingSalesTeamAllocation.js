import { LightningElement, api, track, wire } from 'lwc'; 
import createBookingSalesTeamAllocation from '@salesforce/apex/bookingSalesTeamAllocationController.createBookingSalesTeamAllocation';
import deleteBookingSalesTeamAllocation from '@salesforce/apex/bookingSalesTeamAllocationController.deleteBookingSalesTeamAllocation';
import getAllocations from '@salesforce/apex/bookingSalesTeamAllocationController.getAllocations';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { refreshApex } from '@salesforce/apex';

export default class SalesTeamAllocation extends LightningElement {
    @api recordId;
    @track rows = [];
    deletedIds = [];
    wiredResult;

    addBlankRow() {
        this.rows = [
            ...this.rows,
            { id: 'temp_' + Date.now(), userId: null, percent: null }
        ];
    }

    @wire(getAllocations, { parentId: '$recordId' })
    wiredAllocations(result) {
        this.wiredResult = result;
        const { data, error } = result;

        if (data && data.length > 0) {
            this.rows = data.map(rec => ({
                id: rec.Id,
                userId: rec.User__c,
                percent: rec.Commission_Allocation__c
            }));
            this.addBlankRow();
            this.deletedIds = [];
        } else if (data && data.length === 0) {
            this.rows = [];
            this.addBlankRow();
            this.deletedIds = [];
        } else if (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

    addRow() {
        this.addBlankRow();
    }

    removeRow(event) {
        const index = event.target.dataset.index;
        const row = this.rows[index];

        if (this.rows.length === 1) {
            this.showToast('Warning', 'At least one row is required', 'warning');
            return;
        }

        if (row.id && !String(row.id).startsWith('temp_')) {
            this.deletedIds.push(row.id);
        }

        this.rows.splice(index, 1);
        this.rows = [...this.rows];
    }

    // ✅ DUPLICATE USER VALIDATION ADDED HERE
    handleRecordChange(event) {
        const index = Number(event.target.dataset.index);
        const selectedUserId = event.detail.recordId;

        // Check duplicate
        const isDuplicate = this.rows.some((row, i) => {
            return i !== index && row.userId === selectedUserId;
        });

        if (isDuplicate) {
            event.target.setCustomValidity('Duplicate Sales Team Member not allowed');
            event.target.reportValidity();
            event.target.value = null;
            return;
        }

        event.target.setCustomValidity('');
        event.target.reportValidity();

        this.rows[index].userId = selectedUserId;
    }

    handlePercentChange(event) {
        const index = Number(event.target.dataset.index);
        const enteredValue = Number(event.target.value);

        if (enteredValue < 0) {
            event.target.setCustomValidity('Percentage cannot be negative');
            event.target.reportValidity();
            event.target.value = this.rows[index].percent;
            return;
        }

        let totalOther = 0;
        this.rows.forEach((row, i) => {
            if (i !== index && row.percent !== null) {
                totalOther += Number(row.percent);
            }
        });

        const remaining = 100 - totalOther;

        if (enteredValue > remaining) {
            event.target.setCustomValidity(`Value cannot exceed ${remaining}%`);
            event.target.reportValidity();
            event.target.value = this.rows[index].percent;
            return;
        }

        event.target.setCustomValidity('');
        this.rows[index].percent = enteredValue;
    }

    handleSaveClick() {
        let totalPercent = 0;
        const recordsToSave = [];

        for (let row of this.rows) {
            const isEmpty = !row.userId && (row.percent === null || row.percent === '');

            if (isEmpty) continue;

            if (!row.userId || row.percent === null || row.percent === '') {
                this.showToast('Error', 'Please fill all fields in used rows', 'error');
                return;
            }

            totalPercent += Number(row.percent);

            const record = {
                User__c: row.userId,
                Commission_Allocation__c: row.percent
            };

            if (this.recordId.startsWith('00Q')) {
                record.Lead__c = this.recordId;
            } else {
                record.Booking__c = this.recordId;
            }

            if (row.id && !String(row.id).startsWith('temp_')) {
                record.Id = row.id;
            }

            recordsToSave.push(record);
        }

        if (totalPercent !== 100) {
            this.showToast(
                'Error',
                `Total Commission Allocation must be exactly 100%. Current total is ${totalPercent}%`,
                'error'
            );
            return;
        }

        Promise.resolve()
            .then(() => {
                if (this.deletedIds.length > 0) {
                    return deleteBookingSalesTeamAllocation({ recordIds: this.deletedIds });
                }
            })
            .then(() => {
                if (recordsToSave.length > 0) {
                    return createBookingSalesTeamAllocation({ records: recordsToSave });
                }
            })
            .then(() => refreshApex(this.wiredResult))
            .then(() => {
                this.showToast('Success', 'Records saved successfully', 'success');
                this.closeModal();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleCancelClick() {
        this.closeModal();
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
