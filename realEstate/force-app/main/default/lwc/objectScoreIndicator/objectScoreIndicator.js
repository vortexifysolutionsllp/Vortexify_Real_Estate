import { LightningElement, api, wire, track } from 'lwc';
import getProgressIndicatorData from '@salesforce/apex/ObjectScoreIndicatorController.getProgressIndicatorData';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getScoreDetails from '@salesforce/apex/ObjectScoreIndicatorController.getScoreDetails';

export default class ObjectScoreIndicator extends LightningElement {

    @api recordId;
    @api objectApiName;
    @track objectLabel;
    @track isShowModal = false;

    totalScore = 0;
    currentScore = 0;
    targetScore = 0;
    animated = false;
    @track criteriaList = [];

    @wire(getObjectInfo, {objectApiName: '$objectApiName'})
    wiredObjectInfo({data,error}){
        if(data){
            this.objectLabel = `${data.label} Score`;
        }
        else if(error){
             this.objectLabel = 'error occured';
        }
    }

    @wire(getProgressIndicatorData, {recordId: '$recordId', objectApiName: '$objectApiName'})
    wiredData({ data, error }) {
        if (error) {
            console.error(error);
            return;
        }

        if (data && !this.animated) {
            this.totalScore = data.totalScore;
            this.targetScore = data.currentScore;
            this.animated = true;
            this.animate();
        }
    }

    animate() {
        this.currentScore = 0;

        const timer = setInterval(() => {
            if (this.currentScore >= this.targetScore) {
                clearInterval(timer);
            } else {
                this.currentScore += 1;
            }
        }, 20);
    }

    get percentage() {
        if (this.totalScore === 0) return 0;
        return Math.round((this.currentScore / this.totalScore) * 100);
    }

    get progressStyle() {
        const radius = 90;
        const circumference = Math.PI * radius;

        if (this.totalScore === 0) {
            return `
                stroke-dasharray: ${circumference};
                stroke-dashoffset: ${circumference};
            `;
        }

        const offset = circumference - (this.currentScore / this.totalScore) * circumference;

        return `
            stroke-dasharray: ${circumference};
            stroke-dashoffset: ${offset};
            stroke: ${this.getColor()};
        `;
    }

    getColor() {
        const p = this.percentage;
        if (p < 40) return '#c23934';
        if (p < 70) return '#ff9a3c';
        return '#2e844a';
    }

    showModalBox(){
        this.isShowModal = true;
    }

    @wire(getScoreDetails, {recordId: '$recordId', objectApiName: '$objectApiName'})
    wiredCriteria({ data, error }) {
        if (data) {
            this.criteriaList = data;
        } else if (error) {
            console.error(error);
            this.criteriaList = [];
        }
    }

    closeModal() {
        this.isShowModal = false;
    }
    
}