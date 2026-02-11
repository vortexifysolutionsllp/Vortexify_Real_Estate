import { LightningElement, track, api } from 'lwc';
import createFolder from '@salesforce/apex/RecordDocumentFolderHandler.createFolder';
import uploadFileUnderFolder from '@salesforce/apex/RecordDocumentFolderHandler.uploadFileUnderFolder';
import getFolders from '@salesforce/apex/RecordDocumentFolderHandler.getFolders';
import deleteFile from '@salesforce/apex/RecordDocumentFolderHandler.deleteFile';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class RecordDocumentLibrary extends NavigationMixin(LightningElement) {

    @api recordId;

    @track folderList = [];
    @track showSpinner = false;

    @track isShowModal = false;
    @track isShowModalFolder = false;

    @track selectedFolderId;
    selectedFile;

    @track isUploading = false;
    @track uploadErrorMessage = '';


    /* -------------------- INIT -------------------- */

    connectedCallback() {
        this.fetchFolders();
    }

    /* -------------------- DATA -------------------- */

    fetchFolders() {
        this.showSpinner = true;

        getFolders({ parentRecordId: this.recordId })
            .then(result => {
                this.folderList = result.map(f => ({
                    ...f,
                    ContentDocumentLinks: f.ContentDocumentLinks || [],
                    isExpanded: false,
                    toggleIcon: 'utility:chevronright',
                    emptyKey: f.Id + '_empty',
                    filesKey: f.Id + '_files'   // 👈 ADD THIS
                }));
                this.showSpinner = false;
            })
            .catch(err => {
                console.error(err);
                this.showSpinner = false;
            });
    }

    refreshComp() {
        this.fetchFolders();
        this.selectedFile = null;
    }

    /* -------------------- TOGGLE -------------------- */

    toggleSection(event) {
        const folderId = event.currentTarget.dataset.id;

        this.folderList = this.folderList.map(f => {
            if (f.Id === folderId) {
                const expanded = !f.isExpanded;
                return {
                    ...f,
                    isExpanded: expanded,
                    toggleIcon: expanded
                        ? 'utility:chevrondown'
                        : 'utility:chevronright'
                };
            }
            return f;
        });
    }

    expandAll() {
        this.folderList = this.folderList.map(f => ({
            ...f,
            isExpanded: true,
            toggleIcon: 'utility:chevrondown'
        }));
    }

    collapseAll() {
        this.folderList = this.folderList.map(f => ({
            ...f,
            isExpanded: false,
            toggleIcon: 'utility:chevronright'
        }));
    }

    /* -------------------- FILE UPLOAD -------------------- */

    showUploadModal(event) {
        this.selectedFolderId = event.currentTarget.dataset.id;
        this.isShowModal = true;
    }

    handleFileChange(event) {
        this.selectedFile = event.target.files[0];
    }

    handleUpload() {
        this.uploadErrorMessage = '';

        if (!this.selectedFile || !this.selectedFolderId) {
            this.uploadErrorMessage = 'Please select a file before uploading.';
            return;
        }

        this.isUploading = true;

        const reader = new FileReader();
        reader.onload = () => {
            uploadFileUnderFolder({
                folderId: this.selectedFolderId,
                fileName: this.selectedFile.name,
                base64Data: reader.result.split(',')[1]
            })
                .then(() => {
                    this.toast('Success', 'File uploaded successfully', 'success');
                    this.hideModalBox();
                    this.refreshComp();
                })
                .catch(error => {
                    console.error(error);
                    this.uploadErrorMessage = 'Upload failed. Please try again.';
                    this.toast('Error', 'Upload failed', 'error');
                })
                .finally(() => {
                    this.isUploading = false;
                });
        };

        reader.readAsDataURL(this.selectedFile);
    }

    hideModalBox() {
        // Close modal
        this.isShowModal = false;

        // Reset upload-related state
        this.selectedFile = null;
        this.selectedFolderId = null;
        this.uploadErrorMessage = '';
        this.isUploading = false;

        // Optional: reset file input (defensive)
        const fileInput = this.template.querySelector('lightning-input[type="file"]');
        if (fileInput) {
            fileInput.value = null;
        }
    }

    /* -------------------- FILE ACTIONS -------------------- */

    handlePreview(event) {
        const docId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: { pageName: 'filePreview' },
            state: { selectedRecordId: docId }
        });
    }

    handleDelete(event) {
        deleteFile({ contentDocumentId: event.currentTarget.dataset.id })
            .then(() => this.refreshComp());
    }

    /* -------------------- CREATE FOLDER -------------------- */

    handleCreateFolder(name) {
        createFolder({
            folderName: name,
            parentRecordId: this.recordId
        }).then(() => {
            this.toast('Success', 'Folder created', 'success');
            this.fetchFolders();
        });
    }

    /* -------------------- UTIL -------------------- */

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}