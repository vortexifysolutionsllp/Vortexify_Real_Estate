import { LightningElement, track, wire } from 'lwc';

import checkEmailApex from '@salesforce/apex/LeadLWCController.checkEmail';
import saveLeadApexRecord from '@salesforce/apex/LeadLWCController.saveLeadRecord';

import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import getProjectsByLocation from '@salesforce/apex/LeadLWCController.getProjectsByLocation';

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

    // handlePhoneChange(event){
    //     let phoneValue = event.target.value;
    //     // remove all non-numeric characters.
    //     phoneValue = phoneValue.replace(/\D/g, '');
    //     //update input value
    //     event.target.value = phoneValue;

    //     // Phone number should not be less than 10
    //     if(phoneValue.length !== 10){
    //         event.target.setCustomValidity("Phone number must be exactly 10 digits");
    //     }
    //     else{
    //         event.target.setCustomValidity("");
    //     }
    //     event.target.reportValidity();

    //     //store phone in lead record
    //     this.leadRec.Phone = phoneValue;
    // }

    handlePhoneChange(event) {

    let phoneValue = event.target.value.trim();

    // Allow +, digits, spaces, -, ()
    const phoneRegex = /^\+?[0-9\s\-()]{10,25}$/;

    // Count digits only (ignore spaces/dashes/brackets)
    let digitsOnly = phoneValue.replace(/\D/g, "");

    // Validation: format + digit length
    if (
        !phoneRegex.test(phoneValue) ||
        digitsOnly.length < 10 ||
        digitsOnly.length > 15
    ) {
        event.target.setCustomValidity(
            "Enter valid phone number (10–15 digits, spaces allowed, country code optional)"
        );
    } else {
        event.target.setCustomValidity("");
    }

    event.target.reportValidity();

    // Store phone WITH spaces and + (as user typed)
    this.leadRec.Phone = phoneValue;
}



    // ---------- LOCATION CHANGE + LOAD PROJECTS ----------
    handleLocationChange(event) {
        this.location = event.target.value;

        getProjectsByLocation({ location: this.location })
            .then(result => {
                this.projectOptions = result.map(p => ({
                    label: p.Name,
                    value: p.Id // important – showing Name
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

    handleBack() {
        // reset UI flags
        this.showEmailOnly = true;
        this.showBasicFields = false;
        this.showProjectFields = false;

        // optional: reset data
        //this.enteredEmail = '';
        this.leadRec = {};
        this.location = null;
        this.projectOptions = [];
        this.selectedProjects = [];
    }


    // ---------- SAVE ----------
    handleSaveRecord() {
        // Validate all inputs before saving
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        // Stop Save if invalid
        if (!allValid) {
            alert("Please enter valid details before saving.");
            return;
        }

        saveLeadApexRecord({
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