import { LightningElement, track, wire } from 'lwc';

import checkEmailApex from '@salesforce/apex/LeadLWCController.checkEmail';
import saveLeadApex from '@salesforce/apex/LeadLWCController.saveLead';

import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import getProjectsByLocation from '@salesforce/apex/LeadLWCController.getProjectsByLocation';

import PROJECT_INTEREST from '@salesforce/schema/Lead.Project_Interest__c';

import getLocationValues from '@salesforce/apex/LeadLWCController.getLocationValues';

export default class LeadprojectLWCInserted extends LightningElement {

    @track leadRec = {};
    enteredEmail = '';

    showEmailOnly = true;
    showBasicFields = false;
    showProjectFields = false;

    // ---------------- LOCATION ----------------
    locationOptions = [];
    location;

    // ---------------- PROJECT LIST ----------------
    projectOptions = [];          // available in dual listbox
    selectedProjects = [];        // selected in dual listbox

    connectedCallback() {
        // load locations
        getLocationValues()
            .then(result => {
                this.locationOptions = result.map(r => ({
                    label: r,
                    value: r
                }));
            })
            .catch(error => {
                console.error(error);
            });
    }

    // ---------- PICKLIST WIRES (still kept for Project_Interest field) ----------
    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    leadObjectInfo;

   /* @wire(getPicklistValues, {
        recordTypeId: '$leadObjectInfo.data.defaultRecordTypeId',
        fieldApiName: PROJECT_INTEREST
    })
    wiredProjectInterestValues({ data, error }) {
        if (data) {
            this.projectOptions = data.values.map(v => ({
                label: v.label,
                value: v.value
            }));
        }
    }*/

    // ---------- EMAIL STEP ----------
    handleEmailChange(event) {
        this.enteredEmail = event.target.value;
    }

    handleCheckEmail() {
        checkEmailApex({ email: this.enteredEmail })
            .then(result => {
                this.leadRec = result.leadRec;

                this.showEmailOnly = false;

                if (result.exists) {
                    this.showProjectFields = true;
                    this.showBasicFields = false;
                } else {
                    this.showBasicFields = true;
                    this.showProjectFields = false;
                }
            })
            .catch(error => {
                console.error(error);
            });
    }

    // ---------- BASIC FIELD CHANGE ----------
    handleChange(event) {
        const field = event.target.dataset.field;
        this.leadRec[field] = event.target.value;
    }

    // ---------- LOCATION CHANGE + LOAD PROJECTS ----------
    handleLocationChange(event) {
        this.location = event.target.value;

        getProjectsByLocation({ location: this.location })
            .then(result => {
                this.projectOptions = result.map(p => ({
                    label: p.Name,
                    value: p.Name // important – showing Name
                }));
                this.selectedProjects = [];
            })
            .catch(error => {
                console.error(error);
            });
    }

    // ---------- PROJECT DUAL LISTBOX CHANGE ----------
    handleProjectChange(event) {
        this.selectedProjects = event.detail.value;

        // optional: store in a text field if you still want
        this.leadRec.Projects__c = this.selectedProjects.join(';');
    }

    // ---------- SAVE ----------
    handleSave() {
        saveLeadApex({
            leadRec: this.leadRec,
            locationValue: this.location,
            selectedProjectNames: this.selectedProjects
        })
            .then(() => {
                alert('Thank you! Your details have been saved.');
                location.reload();
            })
            .catch(error => {
                console.error(error);
            });
    }
}