import { LightningElement, api, track, wire } from 'lwc';
import saveCommissionPolicy from '@salesforce/apex/BookingCommissionPolicyController.saveCommissionPolicy';
import getProjectAndTowerFromBooking from '@salesforce/apex/BookingController.getProjectAndTowerFromBooking';
import getTowerCountByProject from '@salesforce/apex/BookingController.getTowerCountByProject';
import getUnitCountByProject from '@salesforce/apex/BookingController.getUnitCountByProject';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCommissionPolicies from '@salesforce/apex/BookingCommissionPolicyController.getCommissionPolicies';


export default class BookingCommissionPolicies extends LightningElement {

    @api recordId;

    project = {};
    tower = {};
    projectId;

    towerCount = 0;
    unitCount = 0;

    @track commissionPolicyOptions = [];
    @api selectedCommissionPolicy;

    /* ---------------- Project & Tower ---------------- */

    @wire(getProjectAndTowerFromBooking, { oppId: '$recordId' })
    wiredProjectData({ data, error }) {
        if (data) {
            this.project = data.project || {};
            this.tower = data.tower || {};
            this.projectId = this.project.Id;
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getTowerCountByProject, { projectId: '$projectId' })
    wiredTowerCount({ data }) {
        if (data !== undefined) {
            this.towerCount = data;
        }
    }

    @wire(getUnitCountByProject, { projectId: '$projectId' })
    wiredUnitCount({ data }) {
        if (data !== undefined) {
            this.unitCount = data;
        }
    }


    @wire(getCommissionPolicies, { opportunityId: '$recordId' })
    wiredCommissionPolicies({ data, error }) {
        if (data) {
            this.commissionPolicyOptions = data.map(policy => ({
                label: policy.Name,
                value: policy.Id
            }));
        } else if (error) {
            console.error('Commission Policy Error:', error);
        }
    }



    handleCommissionChange(event) {
        this.selectedCommissionPolicy = event.detail.value;
    }

    /* ---------------- Save ---------------- */

    @api
    handleSave() {
        if (!this.selectedCommissionPolicy) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Commission Policy',
                    message: 'Please select a Commission Policy before saving.',
                    variant: 'warning'
                })
            );
            return Promise.reject();
        }

        return saveCommissionPolicy({
            opportunityId: this.recordId,
            policyId: this.selectedCommissionPolicy
        });
    }
}
