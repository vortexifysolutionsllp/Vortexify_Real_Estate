import { LightningElement, track, api } from 'lwc';
import saveLeadApex from '@salesforce/apex/LeadLWCController.saveLead';
import getProjectsByLocation from '@salesforce/apex/LeadLWCController.getProjectsByLocation';
import getLeadById111 from '@salesforce/apex/LeadLWCController.getLeadById111';
import getLocationValues from '@salesforce/apex/LeadLWCController.getLocationValues';
import getSelectedProjectInterests from '@salesforce/apex/LeadLWCController.getSelectedProjectInterests';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class LeadProjectAllocationComponent extends LightningElement {

    _recordId;

    @api
    set recordId(value) {
        this._recordId = value;


    }

    get recordId() {
        return this._recordId;
    }


    @track leadRec = {};

    locationOptions = [];
    location;

    projectOptions = [];
    selectedProjects = [];
    dataLoaded = false;

    connectedCallback() {
        getLocationValues()
            .then(result => {
                this.locationOptions = result.map(r => ({
                    label: r,
                    value: r
                }));
            })
            .catch(error => console.error(error));
            //this.loadLeadData();
    }
    renderedCallback() {
        if (!this.dataLoaded && this.recordId) {
            this.dataLoaded = true;
            this.loadLeadData();
        }
    }

    async loadLeadData() {
        try {
            // Load Lead Record
            const result = await getLeadById111({
                recordId: this.recordId
            });

            this.leadRec = { ...result };
            this.location = result.Location__c;

            // Load Project Options Based on Location
            if (this.location) {
                const projects = await getProjectsByLocation({
                    location: this.location
                });

                this.projectOptions = projects.map(p => ({
                    label: p.Name,
                    value: p.Id
                }));
            }

            // Load Existing Project Interests (Selected)
            const selectedIds = await getSelectedProjectInterests({
                leadId: this.recordId
            });

            this.selectedProjects = [...selectedIds];

        } catch (error) {
            console.error("Error in loadLeadData:", error);
        }
    }


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
        .then(async () => {

            alert('Thank you! Your details have been saved.');

            // Reload component data automatically
            // this.dataLoaded = false;
            // await this.loadLeadData();
            //window.location.reload();
            setTimeout(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
            }, 500);

             getLocationValues()
            .then(result => {
                this.locationOptions = result.map(r => ({
                    label: r,
                    value: r
                }));
            })
            .catch(error => console.error(error));

            //await this.loadLeadData();

        })
        .catch(error => console.error(error));
}

}
