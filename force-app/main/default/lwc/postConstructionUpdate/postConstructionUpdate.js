import { LightningElement, api, wire } from 'lwc';
import getTowers from '@salesforce/apex/PostConstructionUpdateController.getTowers';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import CONSTRUCTION_UPDATE_OBJECT from '@salesforce/schema/Construction_update__c';
import CONSTRUCTION_STAGE_FIELD from '@salesforce/schema/Construction_update__c.ConstructionStage__c';

export default class PostConstructionUpdate extends LightningElement {

    @api recordId;

    // Towers
    towers = [];
    searchTowers = [];
    selectedTowers = [];
    showDropdown = false;
    towerError = '';

    // Picklist
    constructionStage;
    constructionStageOptions = [];
    recordTypeId;

    // File Upload
    acceptedFormats = ['.jpg', '.jpeg', '.png'];
    uploadedFiles = [];
    uploadedFileIds = [];
    uploadError = '';

    connectedCallback() {
        this._outsideClickHandler = this.handleOutsideClick.bind(this);
        document.addEventListener('click', this._outsideClickHandler);
    }

    disconnectedCallback() {
        document.removeEventListener('click', this._outsideClickHandler);
    }

    /* ========================
       LDS – Object & Picklist
       ======================== */

    @wire(getObjectInfo, { objectApiName: CONSTRUCTION_UPDATE_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: CONSTRUCTION_STAGE_FIELD
    })
    wiredConstructionStages({ data, error }) {
        if (data) {
            this.constructionStageOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error(error);
        }
    }

    handleStageChange(event) {
        this.constructionStage = event.detail.value;
    }

    /* ========================
       Towers Logic
       ======================== */

    @wire(getTowers, { projectId: '$recordId' })
    wiredTowers({ data, error }) {
        if (data) {
            this.towers = data;
        } else {
            console.error(error);
        }
    }

    handleTowerClick(event) {
        event.stopPropagation();

        const selectedIds = this.selectedTowers.map(t => t.id);
        const availableTowers = this.towers.filter(
            t => !selectedIds.includes(t.Id)
        );

        if (availableTowers.length) {
            this.searchTowers = [
                { Id: 'ALL', Name: 'All' },
                ...availableTowers
            ];
            this.showDropdown = true;
        }
    }

    handleTowers(event) {
        event.stopPropagation();
        const searchKey = event.target.value.toLowerCase();

        this.searchTowers = this.towers.filter(
            t => t.Name.toLowerCase().includes(searchKey)
        );
        this.showDropdown = true;
    }

    handleSelect(event) {
        event.stopPropagation();

        const id = event.currentTarget.dataset.id;
        const name = event.currentTarget.dataset.name;

        if (id === 'ALL') {
            this.selectedTowers = this.towers.map(t => ({
                id: t.Id,
                label: t.Name
            }));
        } else {
            this.selectedTowers = [
                ...this.selectedTowers,
                { id, label: name }
            ];
        }

        this.towerError = '';
        this.template.querySelector('[data-input="tower"]').value = '';
        this.showDropdown = false;
        this.searchTowers = [];
    }

    handleRemove(event) {
        const removedId = event.detail.item.id;
        this.selectedTowers = this.selectedTowers.filter(
            t => t.id !== removedId
        );
    }

    handleOutsideClick(event) {
        const wrapper = this.template.querySelector('.tower-wrapper');
        if (wrapper && !wrapper.contains(event.target)) {
            this.showDropdown = false;
            this.searchTowers = [];
        }
    }

    validateTowers() {
        if (!this.selectedTowers.length) {
            this.towerError = 'Please select at least one Tower.';
            return false;
        }
        this.towerError = '';
        return true;
    }

    /* ========================
       File Upload
       ======================== */

    handleUploadFinished(event) {

        if (!this.validateTowers()) {
            return;
        }

        const newFiles = event.detail.files;
        const totalFiles = this.uploadedFiles.length + newFiles.length;

        this.uploadError = '';

        if (totalFiles > 5) {
            this.uploadError = 'You can upload a maximum of 5 images only.';
            return;
        }

        const mappedFiles = newFiles.map(file => ({
            id: file.documentId,
            name: file.name
        }));

        this.uploadedFiles = [...this.uploadedFiles, ...mappedFiles];
        this.uploadedFileIds = this.uploadedFiles.map(f => f.id);

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Images uploaded successfully',
                variant: 'success'
            })
        );
    }

    /* ========================
       Footer
       ======================== */

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
