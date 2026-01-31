import { LightningElement, api, wire } from 'lwc';

// Apex
import getLeadData from '@salesforce/apex/CaptureVisitInfoController.getLeadData';
import getAllProjects from '@salesforce/apex/CaptureVisitInfoController.getAllProjects';
import getLeadProjectInterests from '@salesforce/apex/CaptureVisitInfoController.getLeadProjectInterests';
import saveVisitInformation from '@salesforce/apex/CaptureVisitInfoController.saveVisitInformation';

// UI API
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import BUYING_TIMELINE_FIELD from '@salesforce/schema/Lead.Buying_Timeline__c';

// Events
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COMPLETED_STATUS = 'Site Visit Completed';

export default class CaptureVisitInformation extends LightningElement {

    @api recordId; // Site Visit Id

    budget;
    buyingTimeline;
    description;

    projectInterestOptions = [];
    projectInterestValues = [];
    buyingTimelineOptions = [];

    /* ---------- Validation ---------- */
    isCompleted = false;
    validationMessage;

    /* ---------- Lead Data ---------- */
    @wire(getLeadData, { siteVisitId: '$recordId' })
    wiredLead({ data, error }) {
        if (data) {
            this.budget = data.Budget__c;
            this.buyingTimeline = data.Buying_Timeline__c;
            this.description = data.Description;

            /* ---------- Validation for completed visit ---------- */
            if (data.Status && data.Status.trim() === COMPLETED_STATUS) {
                this.isCompleted = true;
                this.validationMessage =
                    'Site visit is already completed. You cannot modify or add project interests.';
            }
        } else if (error) {
            console.error(error);
        }
    }

    /* ---------- All Projects ---------- */
    @wire(getAllProjects)
    wiredProjects({ data, error }) {
        if (data) {
            this.projectInterestOptions = data.map(p => ({
                label: p.Name,
                value: p.Id
            }));
        } else if (error) {
            console.error(error);
        }
    }

    /* ---------- Selected Projects ---------- */
    @wire(getLeadProjectInterests, { siteVisitId: '$recordId' })
    wiredSelected({ data, error }) {
        if (data) {
            this.projectInterestValues = [...data];
        } else if (error) {
            console.error(error);
        }
    }

    /* ---------- Object Info ---------- */
    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    leadInfo;

    /* ---------- Buying Timeline ---------- */
    @wire(getPicklistValues, {
        recordTypeId: '$leadInfo.data.defaultRecordTypeId',
        fieldApiName: BUYING_TIMELINE_FIELD
    })
    wiredBuyingTimeline({ data }) {
        if (data) {
            this.buyingTimelineOptions = data.values.map(v => ({
                label: v.label,
                value: v.value
            }));
        }
    }

    /* ---------- Handlers ---------- */
    handleInputChange(event) {
        const field = event.target.dataset.field;
        if (field === 'Budget__c') this.budget = event.target.value;
        if (field === 'Description') this.description = event.target.value;
    }

    handleBuyingTimelineChange(event) {
        this.buyingTimeline = event.detail.value;
    }

    handleProjectInterestChange(event) {
        this.projectInterestValues = [...event.detail.value];
    }

    /* ---------- Save ---------- */
    handleSave() {
        saveVisitInformation({
            siteVisitId: this.recordId,
            leadData: {
                Budget__c: this.budget,
                Buying_Timeline__c: this.buyingTimeline,
                Description: this.description
            },
            selectedProjectIds: this.projectInterestValues || []
        })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Visit information saved successfully',
                    variant: 'success'
                })
            );
            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Unexpected error',
                    variant: 'error'
                })
            );
        });
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}