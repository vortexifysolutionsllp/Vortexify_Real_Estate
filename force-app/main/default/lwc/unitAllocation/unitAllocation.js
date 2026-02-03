import { LightningElement, track } from 'lwc';
import getTowersByProject from '@salesforce/apex/unitAllocationController.getTowersByProject';
import getUnitsByTowerAndFloor from '@salesforce/apex/unitAllocationController.getUnitsByTowerAndFloor';
import createOppsForUnits from '@salesforce/apex/unitAllocationController.createOppsForUnits';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { CloseActionScreenEvent } from 'lightning/actions';


export default class ProjectTowerPicker extends LightningElement {

    selectedProjectId;
    @track towers = [];
    noTowers = false;
    unitsApexResult;
    @track floorOptions = [];
    @track units = [];

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


    handleProjectChange(event) {
        this.selectedProjectId = event.detail.recordId;
        this.fetchTowers();
    }

    fetchTowers() {
        getTowersByProject({ projectId: this.selectedProjectId })
            .then(result => {
                // Add isSelected flag to each tower
                this.towers = result.map(tower => ({
                    ...tower,
                    isSelected: false
                }));
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

    // Clear units when switching tower
    this.units = [];

    this.towers = this.towers.map(tower => {
        if (tower.Id === towerId) {
            this.generateFloorOptions(tower.Total_Floors__c);
            return { ...tower, isSelected: true };
        }
        return { ...tower, isSelected: false };
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
        if (unit.Id === unitId) {

            if (unit.UnitStatus__c !== 'Available') {
                return unit;
            }

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

    if (unit.UnitStatus__c !== 'Available') {
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

    createOppsForUnits({ unitIds: selectedUnitIds })
        .then(() => {
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Success',
            message: 'Opportunities created successfully',
            variant: 'success'
        }) 
    );
    this.dispatchEvent(new CloseActionScreenEvent());

    if (this.unitsApexResult) {
        refreshApex(this.unitsApexResult);
    }

    this.dispatchEvent(new CustomEvent('close'));
})

        .catch(error => {
    console.error('FULL ERROR 👉', JSON.stringify(error));

    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Error',
            message: error.body?.message || JSON.stringify(error),
            variant: 'error'
        })
    );
});

}


    handleCancel() {
        this.units = [];
        this.floorOptions = [];
        this.towers = this.towers.map(t => ({ ...t, isSelected: false }));
    }


}