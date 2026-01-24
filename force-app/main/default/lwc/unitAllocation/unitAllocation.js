import { LightningElement, track } from 'lwc';
import getTowersByProject from '@salesforce/apex/unitAllocationController.getTowersByProject';

export default class ProjectTowerPicker extends LightningElement {

    selectedProjectId;
    @track towers = [];
    noTowers = false;

    @track floorOptions = [];

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
}