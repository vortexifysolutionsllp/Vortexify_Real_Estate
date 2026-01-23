import { LightningElement, api, wire } from 'lwc';
import getTowers from '@salesforce/apex/PostConstructionUpdateController.getTowers';
import getConstructionPolicy from '@salesforce/apex/PostConstructionUpdateController.getConstructionPolicy';
import getUsedMilestoneTermIds from '@salesforce/apex/PostConstructionUpdateController.getUsedMilestoneTermIds';

import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import CONSTRUCTION_UPDATE_OBJECT from '@salesforce/schema/Construction_update__c';
import CONSTRUCTION_STAGE_FIELD from '@salesforce/schema/Construction_update__c.ConstructionStage__c';
import createConstructionUpdate from '@salesforce/apex/PostConstructionUpdateController.createConstructionUpdate';


export default class PostConstructionUpdate extends LightningElement {

    @api recordId;

    /* ========================
       Towers
       ======================== */
    towers = [];
    searchTowers = [];
    selectedTowers = [];
    showDropdown = false;
    towerError = '';

    /* ========================
       Construction Stage
       ======================== */
    constructionStage;
    constructionStageOptions = [];
    recordTypeId;

    /* ========================
       Policy & Milestones
       ======================== */
    policyId;
    milestoneOptions = [];
    selectedMilestone;
    selectedMilestoneName;
    milestoneError = '';

    usedMilestoneTermIds = new Set(); // ⭐ NEW

    /* ========================
       File Upload
       ======================== */
    acceptedFormats = ['.jpg', '.jpeg', '.png'];
    uploadedFiles = [];
    uploadedFileIds = [];
    uploadError = '';

    /* ========================
       Lifecycle
       ======================== */
    connectedCallback() {
        this._outsideClickHandler = this.handleOutsideClick.bind(this);
        document.addEventListener('click', this._outsideClickHandler);
    }

    disconnectedCallback() {
        document.removeEventListener('click', this._outsideClickHandler);
    }

    /* ========================
       Object & Picklist
       ======================== */
    @wire(getObjectInfo, { objectApiName: CONSTRUCTION_UPDATE_OBJECT })
    objectInfo({ data }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: CONSTRUCTION_STAGE_FIELD
    })
    wiredConstructionStages({ data }) {
        if (data) {
            this.constructionStageOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        }
    }

    handleStageChange(event) {
        this.constructionStage = event.detail.value;
    }

    /* ========================
       Towers Logic
       ======================== */
    @wire(getTowers, { projectId: '$recordId' })
    wiredTowers({ data }) {
        if (data) {
            this.towers = data;
        }
    }

    handleTowerClick(event) {
        event.stopPropagation();

        const selectedIds = this.selectedTowers.map(t => t.id);
        const availableTowers = this.towers.filter(
            t => !selectedIds.includes(t.Id)
        );

        if (availableTowers.length) {
            this.searchTowers = [{ Id: 'ALL', Name: 'All' }, ...availableTowers];
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
            this.selectedTowers = [...this.selectedTowers, { id, label: name }];
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
       Used Milestones (NEW)
       ======================== */

    @wire(getUsedMilestoneTermIds, { projectId: '$recordId' })
    wiredUsedMilestones({ data }) {
        if (data) {
            this.usedMilestoneTermIds = new Set(data);
        }
    }



    /* ========================
       Policy & Milestones Logic
       ======================== */
    @wire(getConstructionPolicy, { projectId: '$recordId' })
    wiredPolicy({ data }) {
        if (data && data.Term__c) {
            this.policyId = data.Id;

            const terms = JSON.parse(data.Term__c);
            terms.sort((a, b) => a.serial - b.serial);

            this.milestoneOptions = terms.map(term => ({
                label: term.termName,
                value: String(term.id),
                disabled: this.usedMilestoneTermIds.has(String(term.id)) // ⭐ KEY
            }));
        }
    }

    handleMilestoneChange(event) {
        this.selectedMilestone = event.detail.value;

        const selected = this.milestoneOptions.find(
            opt => opt.value === this.selectedMilestone
        );

        this.selectedMilestoneName = selected?.label;
        this.milestoneError = '';
    }

    /* ========================
       File Upload
       ======================== */
    handleUploadFinished(event) {
        const newFiles = event.detail.files;

        if (this.uploadedFiles.length + newFiles.length > 5) {
            this.uploadError = 'You can upload a maximum of 5 images only.';
            return;
        }

        this.uploadError = '';

        const mappedFiles = newFiles.map(f => ({
            id: f.documentId,
            name: f.name
        }));

        this.uploadedFiles = [...this.uploadedFiles, ...mappedFiles];
        this.uploadedFileIds = this.uploadedFiles.map(f => f.id);
    }

    /* ========================
       Footer
       ======================== */
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleSave() {
        let isValid = true;

        if (!this.validateTowers()) isValid = false;

        if (!this.selectedMilestone) {
            this.milestoneError = 'Please select a milestone.';
            isValid = false;
        }

        if (!isValid) return;

        try {
            await createConstructionUpdate({
                projectId: this.recordId,
                policyId: this.policyId,
                milestoneName: this.selectedMilestoneName,
                termId: this.selectedMilestone,
                constructionStage: this.constructionStage, // ✅ FIXED
                towerIds: this.selectedTowers.map(t => t.id),
                fileIds: this.uploadedFileIds
            });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Construction Update created successfully',
                    variant: 'success'
                })
            );

            this.dispatchEvent(new CloseActionScreenEvent());

        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Duplicate milestone detected',
                    variant: 'error'
                })
            );
        }
    }
}
