import { LightningElement, api, wire, track } from 'lwc';
import getProjectAndTowerFromBooking from '@salesforce/apex/BookingController.getProjectAndTowerFromBooking';
import getTowerCountByProject from '@salesforce/apex/BookingController.getTowerCountByProject';
import getUnitCountByProject from '@salesforce/apex/BookingController.getUnitCountByProject';
import getPaymentPoliciesByProject from '@salesforce/apex/BookingController.getPaymentPoliciesByProject';
import getUnitBookingDetails from '@salesforce/apex/BookingController.getUnitBookingDetails';
import getCostPerSqftByPolicy from '@salesforce/apex/BookingController.getCostPerSqftByPolicy';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class BookingPaymentPolicies extends LightningElement {

    @api recordId;
    @track projectId;

    @track project = {};
    @track tower = {};

    towerCount = 0;
    unitCount = 0;
@track wiredBookingDataResult;
@track wiredPaymentPoliciesResult;
    @track wiredUnitDetailsResult;

    @track paymentPlanOptions = [];
    @api selectedPaymentPolicy;

    @track unitDetails = {
        Product2: {}
    };

    @track pricePerSqft = null;
    @track totalDealCost = null;

    @track showNoUnitError = false;
    @track disableAllFields = false;


    hasValidatedUnit = false;

    // Fetch Project & Tower
    @wire(getProjectAndTowerFromBooking, { oppId: '$recordId' })
    wiredBookingData(result) {
      this.wiredBookingDataResult = result; // store full wire result
    const { data, error } = result;
        if (data) {
            this.project = data.project || {};
            this.tower = data.tower || {};
           // this.projectId = this.project.Id;
             this.projectId = data.projectId;
             this.selectedPaymentPolicy = data.paymentPolicyId;
              
        } else if (error) {
            console.error('Error fetching project data', error);
        }
    }

    // Fetch Tower Count
    @wire(getTowerCountByProject, { projectId: '$project.Id' })
    wiredTowerCount({ data, error }) {
        // console.log('ProjectId for policies:', this.projectId);

        if (data !== undefined) {
            this.towerCount = data;
        } else if (error) {
            console.error('Error fetching tower count', error);
        }
    }

    // Fetch Unit Count
    @wire(getUnitCountByProject, { projectId: '$project.Id' })
    wiredUnitCount({ data, error }) {
        if (data !== undefined) {
            this.unitCount = data;
        } else if (error) {
            console.error('Error fetching unit count', error);
        }
    }

    // Fetch Payment Policies
   @wire(getPaymentPoliciesByProject, { projectId: '$projectId' })
    //wiredPaymentPolicies({ data, error }) {
    wiredPaymentPolicies(result) {
        this.wiredPaymentPoliciesResult = result;
        const{data, error} = result;// store full wire result
        console.log('ProjectId for policies:', this.projectId);

        if (data) {
            console.log('ProjectId for policies:', this.projectId);

            this.paymentPlanOptions = data.map(policy => ({
                label: policy.Name,
                value: policy.Id
            }));
        } else if (error) {
            console.error('Error fetching payment policies', error);
        }
    }

    // Fetch Unit Details
    // @wire(getUnitBookingDetails, { oppId: '$recordId' })
    // wiredUnitDetails({ data, error }) {
    //     if (data) {
    //         this.unitDetails = data;
    //     } else if (!data && !this.hasValidatedUnit) {
    //         this.hasValidatedUnit = true;
    //         this.showUnitMissingToast();
    //     } else if (error) {
    //         console.error('Error fetching unit details', error);
    //     }
    // }

    @wire(getUnitBookingDetails, { oppId: '$recordId' })
//wiredUnitDetails({ data, error }) {
    wiredUnitDetails(result) {
    this.wiredUnitDetailsResult = result; 

    const { data, error } = result;
    if (data) {
        this.unitDetails = data;
        this.showNoUnitError = false;
        this.disableAllFields = false;
    } 
    else if (!data) {
        // No Unit product found
        this.showNoUnitError = true;
        this.disableAllFields = true;
        this.unitDetails = { Product2: {} };
        this.pricePerSqft = null;
        this.totalDealCost = null;
    } 
    else if (error) {
        console.error('Error fetching unit details', error);
    }
}


    showUnitMissingToast() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Invalid Product',
                message: 'Please select a product with Family = Unit',
                variant: 'error'
            })
        );
    }
    @api
get dealCost(){
    return this.totalDealCost;
}


    // Handle Payment Plan Change
    handlePaymentChange(event) {
        this.selectedPaymentPolicy = event.detail.value;

        getCostPerSqftByPolicy({ policyId: this.selectedPaymentPolicy })
            .then(cost => {
                this.pricePerSqft = cost;

                const superArea = parseFloat(this.unitDetails.Product2.SaleableArea__c);
                const rate = parseFloat(cost);
                if (superArea && cost) {
                    this.totalDealCost = superArea * cost;
                } else {
                    this.totalDealCost = null;
                }
            })
            .catch(error => {
                console.error('Error fetching cost per sqft', error);
            });
    }
        @api
    refreshData() {
        const promises = [];

        if (this.wiredBookingDataResult) {
            promises.push(refreshApex(this.wiredBookingDataResult));
        }

        if (this.wiredPaymentPoliciesResult) {
            promises.push(refreshApex(this.wiredPaymentPoliciesResult));
        }

        if (this.wiredUnitDetailsResult) {
            promises.push(refreshApex(this.wiredUnitDetailsResult));
        }

        return Promise.all(promises);
    }
        @api
    handleSave() {
        //Block if booking has no Unit product
        if (this.showNoUnitError) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Invalid Booking',
                    message: 'Booking must contain a Unit product before selecting a Payment Plan.',
                    variant: 'error'
                })
            );
            return Promise.reject();
        }

        // Block if no Payment Plan selected
        if (!this.selectedPaymentPolicy) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Payment Plan',
                    message: 'Please select a Payment Plan before saving.',
                    variant: 'warning'
                })
            );
            return Promise.reject();
        }

        // Allow parent save to continue
        return Promise.resolve();
    }

}