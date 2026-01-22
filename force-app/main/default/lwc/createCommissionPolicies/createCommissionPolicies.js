import { LightningElement, api, track, wire } from 'lwc';
import getCommissionPolicies from '@salesforce/apex/BookingCommissionPolicyController.getCommissionPolicies';
import saveCommissionPolicy from '@salesforce/apex/BookingCommissionPolicyController.saveCommissionPolicy';
import getProjectAndTowerFromBooking from '@salesforce/apex/BookingController.getProjectAndTowerFromBooking';
import getTowerCountByProject from '@salesforce/apex/BookingController.getTowerCountByProject';
import getUnitCountByProject from '@salesforce/apex/BookingController.getUnitCountByProject';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';


export default class BookingCommissionPolicies extends LightningElement {
    @api recordId;

    project = {};
    tower = {};
    projectId;

    towerCount = 0;
    unitCount = 0;


    @track policyOptions = [];
    @api selectedPolicyId;
    isLoading = false;

    // This is triggered when the Quick Action button is clicked
    @api
    invoke() {
        if (this.recordId) {
            this.loadPolicies();
        } else {
            // Fallback if recordId isn't ready immediately
            setTimeout(() => {
                this.loadPolicies();
            }, 500);
        }
    }

    // Also load on connectedCallback if used as a standard component
    connectedCallback() {
        if (this.recordId) {
            this.loadPolicies();
        }
    }

    loadPolicies() {
        if (!this.recordId) return;

        this.isLoading = true;
        getCommissionPolicies({ opportunityId: this.recordId })
            .then(data => {                
                if (data && data.length > 0) {
                    this.policyOptions = data.map(p => ({
                        label: p.Name,
                        value: p.Id
                    }));
                } else {
                    this.policyOptions = [];
                }
            })
            .catch(error => {
                this.showToast('Error', 'Could not load policies. Check Project configuration.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
        }

        @wire(getProjectAndTowerFromBooking, { oppId: '$recordId' })
        wiredProjectData({ data, error }) {
            if (data) {
                this.project = data.project || {};
                this.tower = data.tower || {};
                this.projectId = this.project.Id;
            } else if (error) {
                console.error('Error fetching project details', error);
            }
        }

        @wire(getTowerCountByProject, { projectId: '$projectId' })
        wiredTowerCount({ data, error }) {
            if (data !== undefined) {
                this.towerCount = data;
            } else if (error) {
                console.error('Error fetching tower count', error);
            }
        }

        @wire(getUnitCountByProject, { projectId: '$projectId' })
        wiredUnitCount({ data, error }) {
            if (data !== undefined) {
                this.unitCount = data;
            } else if (error) {
                console.error('Error fetching unit count', error);
            }
        }
    
        handlePolicyChange(event) {
            this.selectedPolicyId = event.detail.value;
        }
        @api
        handleSave() {
        if (!this.selectedPolicyId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Commission Policy',
                    message: 'Please select a Commission Policy before saving.',
                    variant: 'warning'
                })
            );
            return;
        }

        this.isLoading = true;

        saveCommissionPolicy({
            opportunityId: this.recordId,
            policyId: this.selectedPolicyId
        })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Commission Policy saved successfully.',
                    variant: 'success'
                })
            );

            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error?.body?.message || 'Something went wrong while saving.',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
}

}