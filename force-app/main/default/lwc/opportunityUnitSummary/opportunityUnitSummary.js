import { LightningElement, api, track } from 'lwc';
import getUnitSummary from '@salesforce/apex/OpportunityUnitSummaryController.getUnitSummary';
import saveUnitSummary from '@salesforce/apex/OpportunityUnitSummaryController.saveUnitSummary';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OpportunityUnitSummary extends LightningElement {

    @api recordId;

    @track unitName;
    @track unitType;
    @track area;
    @track basePrice = 0;
    @track plcAmount = 0;
    @track otherCharges = 0;
    @track discount = 0;
    @track specialDiscount = 0;
    @track parkingList = [];

    parkingOptions = [
        { label: 'Covered', value: 'Covered' },
        { label: 'Open', value: 'Open' },
        { label: 'Free', value: 'Free' }
    ];

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        getUnitSummary({ opportunityId: this.recordId })
            .then(result => {
                this.unitName = result.unitName;
                this.unitType = result.unitType;
                this.area = result.area;
                this.basePrice = result.basePrice;
            });
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this[field] = Number(event.target.value) || 0;
    }

    addParking() {
        const newItem = {
            id: Date.now().toString(),
            parkingType: '',
            amount: 0
        };
        this.parkingList = [...this.parkingList, newItem];
    }

    removeParking(event) {
        const id = event.currentTarget.dataset.id;
        this.parkingList = this.parkingList.filter(p => p.id !== id);
    }

    handleParkingType(event) {
        const id = event.target.dataset.id;
        this.parkingList = this.parkingList.map(p =>
            p.id === id ? { ...p, parkingType: event.detail.value } : p
        );
    }

    handleParkingAmount(event) {
        const id = event.target.dataset.id;
        this.parkingList = this.parkingList.map(p =>
            p.id === id ? { ...p, amount: Number(event.target.value) || 0 } : p
        );
    }

    get parkingTotal() {
        return this.parkingList.reduce((sum, p) => sum + (p.amount || 0), 0);
    }

    get totalCost() {
        return this.basePrice + this.plcAmount + this.otherCharges + this.parkingTotal;
    }

    get totalDiscount() {
        return this.discount + this.specialDiscount;
    }

    get finalPrice() {
        return this.totalCost - this.totalDiscount;
    }

    handleSubmit() {
        const payload = {
            unitName: this.unitName,
            unitType: this.unitType,
            area: this.area,
            basePrice: this.basePrice,
            plcAmount: this.plcAmount,
            otherCharges: this.otherCharges,
            discount: this.discount,
            specialDiscount: this.specialDiscount,
            parkingList: this.parkingList.map(p => ({
                parkingType: p.parkingType,
                amount: p.amount
            }))
        };

        saveUnitSummary({
            opportunityId: this.recordId,
            dto: payload
        })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Unit Summary Saved Successfully',
                    variant: 'success'
                })
            );
        });
    }
}