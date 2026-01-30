import { LightningElement, api } from 'lwc';   
import getLeadDetails from '@salesforce/apex/SiteVisitController.getLeadDetails';
import getProjects from '@salesforce/apex/SiteVisitController.getProjects';
import getTowersByProject from '@salesforce/apex/SiteVisitController.getTowersByProject';
import createSiteVisit from '@salesforce/apex/SiteVisitController.createSiteVisit';
import getSiteVisits from '@salesforce/apex/SiteVisitController.getSiteVisits';
import deleteSiteVisit from '@salesforce/apex/SiteVisitController.deleteSiteVisit';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SiteVisitForm extends LightningElement {

    @api recordId;

    today = new Date().toISOString().split('T')[0];

    rows = [];
    projectOptions = [];

    
    isLoading = false;

    visitTypeOptions = [
        { label: 'First Visit', value: 'First Visit' },
        { label: 'Revisit', value: 'Revisit' },
        { label: 'Virtual Visit', value: 'Virtual Visit' }
    ];

    projectFirstVisitMap = {};

   
    connectedCallback() {

        getProjects().then(data => {
            this.projectOptions = data.map(p => ({
                label: p.Name,
                value: p.Id
            }));
        });

        Promise.all([
            getLeadDetails({ leadId: this.recordId }),
            getSiteVisits({ leadId: this.recordId })
        ])
        .then(([lead, visits]) => {

            
            visits.forEach(v => {
                if (v.Project__c && v.VisitType__c === 'First Visit') {
                    this.projectFirstVisitMap[v.Project__c] = true;
                }
            });

            let rows = [];

            if (visits.length > 0) {
                rows = visits.map((v, index) => ({
                    id: v.Id,
                    customerName: v.CustomerName__c,
                    customerEmail: v.CustomerEmail__c,
                    customerPhone: v.Customer_Phone__c,
                    visitDate: v.VisitDate__c,
                    visitTime: this.formatTime(v.Visit_Time__c),
                    visitType: v.VisitType__c,
                    projectId: v.Project__c,
                    towerId: v.Tower__c,
                    towerOptions: [],
                    isTowerDisabled: !v.Project__c,
                    salesRepId: v.Sales_Representative__c,
                    isFirst: index === 0,
                    visitTypeOptions: this.visitTypeOptions
                }));
            }

            
            rows.push({
                id: Date.now(),
                customerName: lead.Name,
                customerEmail: lead.Email,
                customerPhone: lead.Phone,
                visitDate: '',
                visitTime: '',
                visitType: '',
                projectId: null,
                towerId: null,
                towerOptions: [],
                isTowerDisabled: true,
                salesRepId: lead.OwnerId,
                isFirst: rows.length === 0,
                visitTypeOptions: this.visitTypeOptions
            });

            this.rows = rows;
        });
    }

    
    formatTime(milliseconds) {
        if (!milliseconds) return '';
        const totalSeconds = Math.floor(milliseconds / 1000);
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
    }

    
    addRow() {
        const leadRow = this.rows[0];
        this.rows = [...this.rows, {
            id: Date.now(),
            customerName: leadRow.customerName,
            customerEmail: leadRow.customerEmail,
            customerPhone: leadRow.customerPhone,
            visitDate: '',
            visitTime: '',
            visitType: '',
            projectId: null,
            towerId: null,
            towerOptions: [],
            isTowerDisabled: true,
            salesRepId: leadRow.salesRepId,
            isFirst: false,
            visitTypeOptions: this.visitTypeOptions
        }];
    }

   
    removeRow(event) {

        const index = Number(event.currentTarget.dataset.index);

        if (this.rows.length === 1) return;

        const row = this.rows[index];

        if (typeof row.id === 'string') {

            deleteSiteVisit({ visitId: row.id })
                .then(() => {
                    this.rows.splice(index, 1);
                    this.rows = [...this.rows];

                    this.showToast('Deleted','Site Visit deleted','success');
                })
                .catch(error => {
                    this.showError(error.body?.message);
                });

        } else {
            this.rows.splice(index, 1);
            this.rows = [...this.rows];
        }
    }

    
    handleRowChange(event) {
        const { index, field } = event.target.dataset;
        this.rows[index][field] = event.target.value;
        this.rows = [...this.rows];
    }

    
    handleProjectChange(event) {

        const index = event.target.dataset.index;
        const projectId = event.target.value;

        this.rows[index].projectId = projectId;
        this.rows[index].towerId = null;
        this.rows[index].towerOptions = [];
        this.rows[index].isTowerDisabled = true;

        const hasFirstVisit = this.projectFirstVisitMap[projectId] === true;

        this.rows[index].visitTypeOptions = this.visitTypeOptions.map(opt => {

            if (!hasFirstVisit && opt.value === 'Revisit') {
                return { ...opt, disabled: true };
            }
            if (hasFirstVisit && opt.value === 'First Visit') {
                return { ...opt, disabled: true };
            }
            return { ...opt, disabled: false };
        });

        this.rows[index].visitType = hasFirstVisit ? 'Revisit' : 'First Visit';

        getTowersByProject({ projectId })
            .then(data => {
                this.rows[index].towerOptions = data.map(t => ({
                    label: t.Name,
                    value: t.Id
                }));
                this.rows[index].isTowerDisabled = false;
                this.rows = [...this.rows];
            });
    }

    
    handleSalesRepChange(event) {
        const index = event.target.dataset.index;
        this.rows[index].salesRepId = event.detail.recordId;
        this.rows = [...this.rows];
    }

    
    closeQuickAction() {
        this.dispatchEvent(new CustomEvent('closeaction'));
    }

    
    handleSubmit() {

        this.isLoading = true; 

        const newRows = this.rows.filter(row => typeof row.id === 'number');

        for (let row of newRows) {

            if (
                !row.visitDate ||
                !row.visitTime ||
                !row.visitType ||
                !row.projectId ||
                !row.salesRepId
            ) {
                this.isLoading = false;
                this.showError('Please fill all the fields.');
                return;
            }

            if (row.visitDate < this.today) {
                this.isLoading = false;
                this.showError('Past date site visit is not allowed.');
                return;
            }

            const hasFirstVisit = this.projectFirstVisitMap[row.projectId] === true;

            if (!hasFirstVisit && row.visitType === 'Revisit') {
                this.isLoading = false;
                this.showError('Revisit not allowed. Create First Visit first.');
                return;
            }

            if (hasFirstVisit && row.visitType === 'First Visit') {
                this.isLoading = false;
                this.showError('First Visit already exists. Select Revisit.');
                return;
            }
        }

        const row = newRows[newRows.length - 1];

        createSiteVisit({
            leadId: this.recordId,
            customerName: row.customerName,
            visitDate: row.visitDate,
            visitTime: row.visitTime,
            customerEmail: row.customerEmail,
            customerPhone: row.customerPhone,
            visitType: row.visitType,
            salesRepId: row.salesRepId,
            projectId: row.projectId,
            towerId: row.towerId
        })
        .then(() => {

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Site Visit created successfully',
                    variant: 'success'
                })
            );

            this.closeQuickAction(); 
        })
        .catch(error => {
            this.showError(error.body?.message || 'Something went wrong');
        })
        .finally(()=>{
            this.isLoading = false; 
        });
    }

   
    showToast(title,message,variant){
        this.dispatchEvent(
            new ShowToastEvent({title,message,variant})
        );
    }

    showError(message) {
        this.showToast('Validation Error',message,'error');
    }

    
    handleCancel() {
        this.closeQuickAction();
    }
}
