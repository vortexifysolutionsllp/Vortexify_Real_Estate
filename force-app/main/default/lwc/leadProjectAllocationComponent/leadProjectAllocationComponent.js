import { LightningElement, track, wire, api } from 'lwc';
import saveLeadApex from '@salesforce/apex/LeadLWCController.saveLead';
import getProjectsByLocation from '@salesforce/apex/LeadLWCController.getProjectsByLocation';
import getLeadById111 from '@salesforce/apex/LeadLWCController.getLeadById111';
import getLocationValues from '@salesforce/apex/LeadLWCController.getLocationValues';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import LEAD_OBJECT from '@salesforce/schema/Lead';

import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';

export default class LeadProjectAllocationComponent extends LightningElement {

    _recordId;

    @api
    set recordId(value) {
        this._recordId = value;

        if (value) {
            this.loadLeadData();
        }
    }

    get recordId() {
        return this._recordId;
    }


    @track leadRec = {};
    enteredEmail = '';

    showBasicFields = true;
    showProjectFields = false;

    locationOptions = [];
    location;

    projectOptions = [];
    selectedProjects = [];

    connectedCallback() {
        getLocationValues()
            .then(result => {
                this.locationOptions = result.map(r => ({
                    label: r,
                    value: r
                }));
            })
            .catch(error => console.error(error));
    }

    loadLeadData() {
        getLeadById111({ recordId: this.recordId })
            .then(result => {
                this.leadRec = { ...result };
                this.location = result.Location__c;

                if (this.location) {
                    return getProjectsByLocation({ location: this.location });
                }
            })
            .then(projects => {
                if (projects) {
                    this.projectOptions = projects.map(p => ({
                        label: p.Name,
                        value: p.Id
                    }));
                }
            })
            .catch(error => console.error(error));
    }

    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    leadObjectInfo;

    handleChange(event) {
        const field = event.target.dataset.field;
        this.leadRec[field] = event.target.value;
    }

    handleLocationChange(event) {
        this.location = event.target.value;

        getProjectsByLocation({ location: this.location })
            .then(result => {
                this.projectOptions = result.map(p => ({
                    label: p.Name,
                    value: p.Id
                }));

                this.selectedProjects = [];
            });
    }

    handleProjectChange(event) {
        this.selectedProjects = event.detail.value;

        const selectedNames = this.projectOptions
            .filter(opt => this.selectedProjects.includes(opt.value))
            .map(opt => opt.label);

        this.leadRec.Projects__c = selectedNames.join(';');
    }

    handleBack() {
        this.showBasicFields = false;
        this.showProjectFields = false;
        this.enteredEmail = '';
        this.leadRec = {};
        this.location = null;
        this.projectOptions = [];
        this.selectedProjects = [];
    }

    handleCancel() {
        this.leadRec = {};
        this.location = null;
        this.selectedProjects = [];
        this.projectOptions = [];
        this.dispatchEvent(new CloseActionScreenEvent());
    }


    handleSave() {
        saveLeadApex({
            leadRec: this.leadRec,
            locationValue: this.location,
            selectedProjectNames: this.selectedProjects
        })
            .then(() => {
                alert('Thank you! Your details have been saved.');

                this.dispatchEvent(new RefreshEvent());
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => console.error(error));
    }
}
