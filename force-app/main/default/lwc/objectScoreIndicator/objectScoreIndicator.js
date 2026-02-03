import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getProgressIndicatorData from '@salesforce/apex/ObjectScoreIndicatorController.getProgressIndicatorData';
import getScoreDetails from '@salesforce/apex/ObjectScoreIndicatorController.getScoreDetails';

const SCORE_FIELD = 'Lead.Score__c';

export default class ObjectScoreIndicator extends LightningElement {

    @api recordId;
    @api objectApiName;
    wiredProgressResult;
    @track objectLabel;
    @track isShowModal = false;
    @track criteriaList = [];

    totalScore = 0;
    currentScore = 0;
    targetScore = 0;

    /* -----------------------------
       OBJECT LABEL
    ----------------------------- */
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this.objectLabel = `${data.label} Score`;
        } else if (error) {
            console.error(error);
            this.objectLabel = 'Error occurred';
        }
    }

    /* -----------------------------
       LDS – WATCH SCORE FIELD
       Auto fires when Score__c changes
    ----------------------------- */
    @wire(getRecord, { recordId: '$recordId', fields: [SCORE_FIELD] })
    wiredLead({ data, error }) {
        if (data) {
            const newScore = data.fields.Score__c.value;

            // Refresh Apex only when score actually changes
            if (newScore !== this.targetScore) {
                refreshApex(this.wiredProgressResult);
            }
        } else if (error) {
            console.error(error);
        }
    }

    /* -----------------------------
       MAIN SCORE INDICATOR
    ----------------------------- */
    @wire(
        getProgressIndicatorData,
        { recordId: '$recordId', objectApiName: '$objectApiName' }
    )
    wiredData(result) {
        this.wiredProgressResult = result;

        if (result.data) {
            this.totalScore = result.data.totalScore;
            this.targetScore = result.data.currentScore;
            this.animate();
        } else if (result.error) {
            console.error(result.error);
        }
    }

    /* -----------------------------
       SCORE DETAILS (MODAL)
    ----------------------------- */
    @wire(
        getScoreDetails,
        { recordId: '$recordId', objectApiName: '$objectApiName' }
    )
    wiredCriteria({ data, error }) {
        if (data) {
            this.criteriaList = data;
        } else if (error) {
            console.error(error);
            this.criteriaList = [];
        }
    }

    /* -----------------------------
       ANIMATION
    ----------------------------- */
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

    /* -----------------------------
       UI GETTERS
    ----------------------------- */
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

        const offset =
            circumference -
            (this.currentScore / this.totalScore) * circumference;

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

    /* -----------------------------
       MODAL
    ----------------------------- */
    showModalBox() {
        this.isShowModal = true;
    }

    closeModal() {
        this.isShowModal = false;
    }
}