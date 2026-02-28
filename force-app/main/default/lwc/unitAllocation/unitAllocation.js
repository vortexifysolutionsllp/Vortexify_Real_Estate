import { LightningElement, track, api, wire } from 'lwc';
import getTowersByProject from '@salesforce/apex/unitAllocationController.getTowersByProject';
import getUnitsByTowerAndFloor from '@salesforce/apex/unitAllocationController.getUnitsByTowerAndFloor';
import createOppsForUnits from '@salesforce/apex/unitAllocationController.createOppsForUnits';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord } from 'lightning/uiRecordApi';
import towerImage from '@salesforce/resourceUrl/towerImage';
import getAllocatedUnit from '@salesforce/apex/unitAllocationController.getAllocatedUnit';
const OPP_FIELDS = ['Opportunity.Project__c'];


export default class ProjectTowerPicker extends LightningElement {
    @api recordId;
    selectedProjectId;
    @track towers = [];
    noTowers = false;
    unitsApexResult;
    @track floorOptions = [];
    @track units = [];
    projectAutoTagged = false;
    @track selectedFloor;
    existingUnitId;
    existingTowerId;
    existingFloor;


    get hasUnits() {
        return this.units && this.units.length > 0;
    }

    get selectedUnits() {
        return this.units.filter(unit => unit.isSelected);
    }

    get disableAllocate() {
       return this.selectedUnits.length === 0;
    }

    isUnitSelectable(status) {
        return status === 'Available';
    }

    get isOpportunityContext() {
        return this.recordId && this.recordId.startsWith('006');
    }

    get isLeadContext() {
        return this.recordId && this.recordId.startsWith('00Q');
    }

    getStatusClass(status) {
    switch (status) {
        case 'Available':
            return 'slds-badge slds-theme_success';
        case 'Blocked':
            return 'slds-badge slds-theme_warning';
        case 'Booked':
            return 'slds-badge slds-theme_error';
        case 'Sold':
            return 'slds-badge slds-theme_dark';
        case 'Cancelled':
            return 'slds-badge slds-theme_light';
        default:
            return 'slds-badge';
        }
    }

    get showProjectPicker() {
    if (this.isLeadContext) {
        return true;
    }
    

    
    return this.isOpportunityContext && !this.projectAutoTagged;
    }

    loadUnitsForExistingSelection() {
    if (!this.existingTowerId || !this.existingFloor) {
        return;
    }

    getUnitsByTowerAndFloor({
        towerId: this.existingTowerId,
        floorNumber: this.existingFloor
    })
        .then(result => {
            this.units = result.map(unit => {
                const isSelected = unit.Id === this.existingUnitId;

                return {
                    ...unit,
                    isSelected,
                    cssClass: this.getUnitClass(unit, isSelected),
                    statusClass: this.getStatusClass(unit.UnitStatus__c)
                };
            });
        })
        .catch(error => {
            console.error('Auto load units error', error);
            this.units = [];
        });
    }


  @wire(getRecord, { recordId: '$recordId', fields: OPP_FIELDS })
wiredOpportunity({ data, error }) {
    if (error) {
        console.error('getRecord error', error);
        return;
    }

    if (data && this.isOpportunityContext) {
        const projectId = data.fields.Project__c.value;

        if (!projectId) {
            this.projectAutoTagged = false;
            return;
        }

        this.selectedProjectId = projectId;
        this.projectAutoTagged = true;

        getAllocatedUnit({ opportunityId: this.recordId })
            .then(unit => {
                if (unit) {
                    this.existingUnitId = unit.Id;
                    this.existingTowerId = unit.Tower__c;
                    this.existingFloor = unit.FloorNumber__c;
                    this.selectedFloor = unit.FloorNumber__c?.toString();
                }

                this.fetchTowers();
            })
            .catch(err => {
                console.error('getAllocatedUnit error', err);
                this.fetchTowers();
            });
    }
}



  handleProjectChange(event) {
    this.selectedProjectId = event.detail.recordId;

    this.selectedFloor = null;
    this.units = [];
    this.floorOptions = [];

    this.fetchTowers();
}


    fetchTowers() {
        getTowersByProject({ projectId: this.selectedProjectId })
            .then(result => {
                // Add isSelected flag to each tower
                this.towers = result.map(tower => {
    const isSelected = tower.Id === this.existingTowerId;

    return {
    ...tower,
    isSelected,
    towerStyle: `background-image:url(${towerImage});`,
    towerClass:
        'slds-box slds-theme_default slds-text-align_center slds-p-around_medium tower-card' +
        (isSelected ? ' selected' : '')
};

});

                const selectedTower = this.towers.find(t => t.isSelected);
                if (selectedTower) {
                    this.generateFloorOptions(selectedTower.Total_Floors__c);

                    if (this.existingFloor) {
                        this.selectedFloor = this.existingFloor.toString();

                        this.loadUnitsForExistingSelection();
                    }
                }


                this.noTowers = this.towers.length === 0;
                
                        })
            .catch(error => {
                console.error(error);
                this.towers = [];
                this.noTowers = true;
            });
    }

  handleTowerClick(event) {
    const towerId = event.currentTarget.dataset.id;

    this.selectedFloor = null;
    this.units = [];

    this.towers = this.towers.map(tower => {
        const isSelected = tower.Id === towerId;

        if (isSelected) {
            this.generateFloorOptions(tower.Total_Floors__c);
        }

        return {
            ...tower,
            isSelected,
            towerClass:
                'slds-box slds-theme_default slds-text-align_center slds-p-around_medium tower-card' +
                (isSelected ? ' selected' : '')
        };
    });
}



    generateFloorOptions(totalFloors) {
        this.floorOptions = [];

        if (!totalFloors || totalFloors <= 0) return;

        for (let i = 1; i <= totalFloors; i++) {
            this.floorOptions.push({
                label: i.toString(),
                value: i.toString()
            });
        }
    }


   handleUnitClick(event) {
    const unitId = event.currentTarget.dataset.id;

    this.units = this.units.map(unit => {

        if (unit.UnitStatus__c !== 'Available' && unit.Id !== this.existingUnitId) {
            return unit;
        }

        if (this.isOpportunityContext) {
            const isSelected = unit.Id === unitId;
            return {
                ...unit,
                isSelected,
                cssClass: this.getUnitClass(unit, isSelected)
            };
        }

        if (unit.Id === unitId) {
            const isSelected = !unit.isSelected;
            return {
                ...unit,
                isSelected,
                cssClass: this.getUnitClass(unit, isSelected)
            };
        }

        return unit;
    });
}




    getUnitClass(unit, isSelected) {
    let cls = 'slds-box slds-text-align_center unit-card';

    if (
        unit.UnitStatus__c !== 'Available' &&
        unit.Id !== this.existingUnitId
    ) {
        cls += ' disabled-unit';
    } else if (isSelected) {
        cls += ' selected-unit';
    }


    return cls;
    }

handleFloorChange(event) {
    const floor = Number(event.detail.value);
    const towerId = event.currentTarget.dataset.towerId;

    getUnitsByTowerAndFloor({ towerId, floorNumber: floor })
        .then(result => {
            this.unitsApexResult = result;

            this.units = result.map(unit => ({
                
                ...unit,
                isSelected: false,
                cssClass: this.getUnitClass(unit, false),
                statusClass: this.getStatusClass(unit.UnitStatus__c)
            }));
        })
        .catch(error => {
            console.error(error);
            this.units = [];
        });
}

   handleAllocate() {
    const selectedUnitIds = this.selectedUnits.map(u => u.Id);

    if (selectedUnitIds.length === 0) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'No Units Selected',
                message: 'Please select at least one unit',
                variant: 'warning'
            })
        );
        return;
    }

    console.log('Quick Action Lead Id:', this.recordId);

    createOppsForUnits({
        unitIds: selectedUnitIds,
        leadId: this.isLeadContext ? this.recordId : null,
        opportunityId: this.isOpportunityContext ? this.recordId : null
    })
    .then(() => {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Opportunities created successfully',
                variant: 'success'
            })
        );
        this.dispatchEvent(new CloseActionScreenEvent());
        //window.location.reload();
        //this.dispatchEvent(new CloseActionScreenEvent());
        setTimeout(() => {
            window.location.reload();
        }, 600); 

    })
    .catch(error => {
        console.error('FULL ERROR 👉', JSON.stringify(error));
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'One product already exists',
                variant: 'error'
            })
        );
    });
}



    handleCancel() {
        this.units = [];
        this.floorOptions = [];
        this.towers = this.towers.map(t => ({ ...t, isSelected: false }));
        this.dispatchEvent(new CloseActionScreenEvent());
    }


}