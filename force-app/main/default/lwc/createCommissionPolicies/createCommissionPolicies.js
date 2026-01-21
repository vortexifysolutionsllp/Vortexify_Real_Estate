import { LightningElement, track } from 'lwc';

export default class CreateCommissionPolicies extends LightningElement {
    
    @track selectedCommissionType = '';
    showFixedCommission=false;
    showPercentageCommission=false;
    showRangeCommission=false;

    @track commissionOptions = [ 
        {label: 'Fixed', value: 'fixed'},
        {label:'Percentage', value: 'percentage'},
        {label:'Range', value: 'range'}
    ];


    handleCommissionTypeChange(event){
        this.selectedCommissionType = event.detail.value;
        this.showFixedCommission=true;
        this.showPercentageCommission=true;
        this.showRangeCommission=true;
    }

}