import { LightningElement, track, wire } from 'lwc';
import getObjectFields from '@salesforce/apex/ScoringCriteriaControllerClass.getObjectFields';
import getScoringObjects from '@salesforce/apex/ScoringCriteriaControllerClass.getScoringObjects';
import getFieldDataType from '@salesforce/apex/ScoringCriteriaControllerClass.getFieldDataType';
import getPicklistValues from '@salesforce/apex/ScoringCriteriaControllerClass.getPicklistValues';
import submitScoringData from '@salesforce/apex/ScoringCriteriaControllerClass.submitScoringData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getExistingScoringData from '@salesforce/apex/ScoringCriteriaControllerClass.getExistingScoringData';


export default class ScoringCriteria extends LightningElement {

    @track selectedObject = '';
    @track error;
    @track criteriaList = [];
    showCriteriaSection = false;
    @track isCancelled = false;
    @track isSubmitted = false;

    @track objectOptions = [];
    @track fieldOptions = [];
    @track selectedOperator;
    @track operatorOptions = [];
    @track deletedCriteriaIds = [];
    @track deletedConditionIds = [];

    conditionCriteriaOptions = [
        { label: 'ALL', value: 'ALL' },
        { label: 'ANY', value: 'ANY' },
        { label: 'Custom', value: 'Custom' }
    ];

    OPERATOR_MAP = {

        'STRING': [
            { label: 'Equals', value: '=' },
            { label: 'Not Equals', value: '!=' },
            { label: 'Contains', value: 'LIKE' },
            { label: 'Does Not Contain', value: 'NOT LIKE' },
            { label: 'Starts With', value: 'STARTS_WITH' },
            { label: 'Ends With', value: 'ENDS_WITH' },
            { label: 'Is Blank', value: 'IS_NULL' },
            { label: 'Is Not Blank', value: 'IS_NOT_NULL' }
        ],

        'TEXTAREA': [
            { label: 'Contains', value: 'LIKE' },
            { label: 'Does Not Contain', value: 'NOT LIKE' },
            { label: 'Is Blank', value: 'IS_NULL' },
            { label: 'Is Not Blank', value: 'IS_NOT_NULL' }
        ],

        'EMAIL': [
            { label: 'Equals', value: '=' },
            { label: 'Contains', value: 'LIKE' },
            { label: 'Ends With', value: 'ENDS_WITH' },
            { label: 'Is Blank', value: 'IS_NULL' }
        ],

        'PHONE': [
            { label: 'Equals', value: '=' },
            { label: 'Contains', value: 'LIKE' },
            { label: 'Is Blank', value: 'IS_NULL' }
        ],

        'BOOLEAN': [
            { label: 'Equals', value: '=' }
        ],

        'INTEGER': [
            { label: 'Equals', value: '=' },
            { label: 'Not Equals', value: '!=' },
            { label: 'Less Than', value: '<' },
            { label: 'Less Than or Equal', value: '<=' },
            { label: 'Greater Than', value: '>' },
            { label: 'Greater Than or Equal', value: '>=' },
            { label: 'Is Blank', value: 'IS_NULL' }
        ],

        'DOUBLE': [
            { label: 'Equals', value: '=' },
            { label: 'Not Equals', value: '!=' },
            { label: 'Less Than', value: '<' },
            { label: 'Less Than or Equal', value: '<=' },
            { label: 'Greater Than', value: '>' },
            { label: 'Greater Than or Equal', value: '>=' }
        ],

        'CURRENCY': [
            { label: 'Equals', value: '=' },
            { label: 'Greater Than', value: '>' },
            { label: 'Less Than', value: '<' },
            { label: 'Between', value: 'BETWEEN' }
        ],

        'PERCENT': [
            { label: 'Equals', value: '=' },
            { label: 'Greater Than', value: '>' },
            { label: 'Less Than', value: '<' }
        ],

        'DATE': [
            { label: 'Equals', value: '=' },
            { label: 'Not Equals', value: '!=' },
            { label: 'Before', value: '<' },
            { label: 'After', value: '>' },
            { label: 'Between', value: 'between' },
            { label: 'On or Before', value: '<=' },
            { label: 'On or After', value: '>=' },
            { label: 'Is Blank', value: 'IS_NULL' }
        ],

        'DATETIME': [
            { label: 'Equals', value: '=' },
            { label: 'Before', value: '<' },
            { label: 'After', value: '>' },
            { label: 'Between', value: 'between' }
        ],

        'PICKLIST': [
            { label: 'Equals', value: '=' },
            { label: 'Not Equals', value: '!=' },
            { label: 'Is Blank', value: 'IS_NULL' }
        ],

        'MULTIPICKLIST': [
            { label: 'Includes', value: 'INCLUDES' },
            { label: 'Excludes', value: 'EXCLUDES' }
        ],

        'REFERENCE': [
            { label: 'Equals', value: '=' },
            { label: 'Not Equals', value: '!=' },
            { label: 'Is Blank', value: 'IS_NULL' },
            { label: 'Is Not Blank', value: 'IS_NOT_NULL' }
        ],

        'URL': [
            { label: 'Equals', value: '=' },
            { label: 'Contains', value: 'LIKE' }
        ],

        'ID': [
            { label: 'Equals', value: '=' },
            { label: 'In', value: 'IN' }
        ]
    };

    @wire(getScoringObjects)
    wiredObjects({ data, error }) {
        if (data) {
            this.objectOptions = data;
        } else if (error) {
            console.error(error);
            this.objectOptions = [];
        }
    }

    handleObjectChange(event) {
        this.isCancelled = false;
        this.isSubmitted = false;
        this.selectedObject = [];
        this.criteriaList = [];
        this.deletedCriteriaIds = [];
        this.deletedConditionIds = [];
        this.selectedObject = event.detail.value;
        this.showCriteriaSection = true;

        if (this.criteriaList.length === 0) {
            this.handleAddCriteria();
            this.reindexConditionsForCriteria(0);
        }
        this.fetchFields();
        this.loadExistingCriteria();
    }

    fetchFields() {
        getObjectFields({ objectName: this.selectedObject })
            .then(result => {
                this.fieldOptions = result;
            })
            .catch(error => {
                console.error(error);
                this.fieldOptions = [];
            });
    }

    loadExistingCriteria() {
        getExistingScoringData({ objectName: this.selectedObject })
            .then(result => {

                if (!result || result.length === 0) {
                    this.criteriaList = [];
                    this.deletedCriteriaIds = [];
                    this.deletedConditionIds = [];
                    this.handleAddCriteria();
                    return;
                }

                this.criteriaList = result.map((crit, critIndex) => ({
                    id: critIndex + 1,
                    recordId: crit.criteriaId,
                    serial: critIndex + 1,
                    isFirst: critIndex === 0,

                    criteriaName: crit.criteriaName,
                    score: crit.score,
                    conditionCriteria: crit.conditionCriteria,
                    conditionLogic: crit.conditionLogic,
                    showConditionLogic: crit.conditionCriteria === 'Custom',

                    isExisting: true,

                    conditions: crit.conditions.map((cond, condIndex) => ({
                        id: condIndex + 1,
                        recordId: cond.conditionId,
                        serial: cond.serial,
                        field: cond.field,
                        operator: cond.operator,
                        value: cond.value,
                        fromValue: '',
                        toValue: '',
                        operatorOptions: [],
                        valueInputType: 'text',
                        showRange: false,
                        isPicklist: false,
                        picklistOptions: []
                    }))
                }));


                this.criteriaList = [...this.criteriaList];

                // THIS IS THE MISSING LINE
                this.initializeLoadedConditions();
            })
            .catch(error => {
                console.error(error);
            });
    }



    initializeLoadedConditions() {

        this.criteriaList.forEach((crit, critIndex) => {

            crit.conditions.forEach((cond, condIndex) => {

                // fetch datatype for field
                getFieldDataType({
                    objectApiName: this.selectedObject,
                    fieldApiName: cond.field
                })
                    .then(dataType => {

                        cond.fieldDataType = dataType;

                        // operator options
                        cond.operatorOptions = this.OPERATOR_MAP[dataType] || [];
                        this.criteriaList = [...this.criteriaList];

                        // input type mapping
                        if (dataType === 'DATE') {
                            cond.valueInputType = 'date';
                        } else if (dataType === 'DATETIME') {
                            cond.valueInputType = 'datetime-local';
                        } else if (
                            dataType === 'INTEGER' ||
                            dataType === 'DOUBLE' ||
                            dataType === 'CURRENCY' ||
                            dataType === 'PERCENT'
                        ) {
                            cond.valueInputType = 'number';
                        } else if (dataType === 'EMAIL') {
                            cond.valueInputType = 'email';
                        } else if (dataType === 'BOOLEAN') {
                            cond.valueInputType = 'checkbox';
                        } else {
                            cond.valueInputType = 'text';
                        }

                        // reset flags
                        cond.showRange = false;
                        cond.isPicklist = false;
                        cond.picklistOptions = [];

                        // BETWEEN handling (Date / Datetime)
                        if (
                            cond.operator &&
                            cond.operator.toLowerCase() === 'between' &&
                            (dataType === 'DATE' || dataType === 'DATETIME')
                        ) {
                            cond.showRange = true;

                            if (cond.value && cond.value.includes(' AND ')) {
                                const parts = cond.value.split(' AND ');
                                cond.fromValue = parts[0];
                                cond.toValue = parts[1];
                            }
                        }

                        // PICKLIST handling
                        if (dataType === 'PICKLIST' || dataType === 'MULTIPICKLIST') {
                            cond.isPicklist = true;

                            getPicklistValues({
                                objectApiName: this.selectedObject,
                                fieldApiName: cond.field
                            })
                                .then(values => {
                                    cond.picklistOptions = values;
                                    this.criteriaList = [...this.criteriaList];
                                })
                                .catch(err => {
                                    console.error(err);
                                });
                        }

                        // 🔥 force UI refresh so operator & value show
                        this.criteriaList = [...this.criteriaList];
                    })
                    .catch(error => {
                        console.error(error);
                    });
            });
        });
    }
    
    handleAddCriteria() {
        const next = this.criteriaList.length + 1;
        // First mark all existing as NOT last
        this.criteriaList = this.criteriaList.map(crit => ({
            ...crit,
            isLast: false
        }));

        const isFirst = this.criteriaList.length === 0;

        this.criteriaList = [
            ...this.criteriaList,
            {
                id: next, serial: next, isFirst: isFirst, isLast: true, isExisting: false, criteriaName: '', score: '', conditionCriteria: 'ALL', showConditionLogic: false,
                conditions: [
                    {
                        id: 1, serial: 1, field: '', operator: '', value: '', fromValue: '', toValue: '', operatorOptions: [], valueInputType: 'text', showRange: false, isPicklist: false, picklistOptions: []
                    }
                ]
            }
        ];
    }

    handleDeleteCriteria(event) {
        const index = event.target.dataset.index;
        const crit = this.criteriaList[index];

        // If existing record, store Id for deletion
        if (crit.isExisting && crit.recordId) {
            this.deletedCriteriaIds.push(crit.recordId);
        }

        this.criteriaList.splice(index, 1);

        this.criteriaList = this.criteriaList.map((crit, critIndex) => {
            const newSerial = critIndex + 1;

            return {
                ...crit,
                id: newSerial,
                serial: newSerial,

                isFirst: critIndex === 0,

                conditions: crit.conditions.map((cond, condIndex) => ({
                    ...cond,
                    id: condIndex + 1,
                    serial: condIndex + 1
                }))
            };
        });
    }

    handleCriteriaInput(event) {
        debugger;
        const index = event.target.dataset.index;
        const name = event.target.name;

        this.criteriaList[index][name] = event.target.value;
        this.criteriaList = [...this.criteriaList];
        console.log(this.criteriaList);
    }

    handleConditionCriteriaChange(event) {
        const index = event.target.dataset.index;
        const value = event.detail.value;

        this.criteriaList[index].conditionCriteria = value;
        this.criteriaList[index].showConditionLogic = value === 'Custom';

        this.criteriaList = [...this.criteriaList];
    }
    
    handleAddCondition(event) {
        const critIndex = event.target.dataset.index;

        this.criteriaList[critIndex].conditions.push({
            id: Date.now(),
            serial: 1,
            field: '',
            operator: '',
            value: '',
            fromValue: '',
            toValue: '',
            operatorOptions: [],
            valueInputType: 'text',
            showRange: false,
            isPicklist: false,
            picklistOptions: []
        });

        this.reindexConditionsForCriteria(critIndex);
        this.criteriaList = [...this.criteriaList];
    }
    
    handleDeleteCondition(event) {
        const critIndex = event.target.dataset.critIndex;
        const condIndex = event.target.dataset.condIndex;
        
        const cond = this.criteriaList[critIndex].conditions[condIndex];
        // If existing condition, store Id for deletion
        if (cond.recordId) {
            this.deletedConditionIds.push(cond.recordId);
        }

        this.criteriaList[critIndex].conditions.splice(condIndex, 1);

        this.reindexConditionsForCriteria(critIndex);
        this.criteriaList = [...this.criteriaList];
    }


    handleConditionInputChange(event) {
        if (!event || !event.target) {
            return;
        }

        const critIndex = event.target.dataset.critIndex;
        const condIndex = event.target.dataset.condIndex;
        const name = event.target.name;
        const value = event.target.value;

        const condition = this.criteriaList[critIndex].conditions[condIndex];

        condition[name] = value;

        // FIELD CHANGE
        if (name === 'field') {
            getFieldDataType({
                objectApiName: this.selectedObject,
                fieldApiName: value
            })
                .then(dataType => {

                    condition.operatorOptions = this.OPERATOR_MAP[dataType] || [];
                    condition.operator = '';
                    condition.value = '';
                    condition.fromValue = '';
                    condition.toValue = '';
                    condition.showRange = false;

                    // store data type
                    condition.fieldDataType = dataType;

                    // reset picklist flags
                    condition.isPicklist = false;
                    condition.picklistOptions = [];

                    // input type mapping
                    if (dataType === 'DATE') {
                        condition.valueInputType = 'date';
                    } else if (dataType === 'DATETIME') {
                        condition.valueInputType = 'datetime-local';
                    } else if (
                        dataType === 'INTEGER' || dataType === 'DOUBLE' || dataType === 'CURRENCY' || dataType === 'PERCENT'
                    ) {
                        condition.valueInputType = 'number';
                    } else if (dataType === 'EMAIL') {
                        condition.valueInputType = 'email';
                    } else if (dataType === 'BOOLEAN') {
                        condition.valueInputType = 'checkbox';
                    } else {
                        condition.valueInputType = 'text';
                    }

                    if (dataType === 'PICKLIST' || dataType === 'MULTIPICKLIST') {
                        condition.isPicklist = true;
                        condition.valueInputType = 'text';

                        getPicklistValues({
                            objectApiName: this.selectedObject,
                            fieldApiName: value
                        })
                            .then(result => {
                                condition.picklistOptions = result;
                                condition.value = '';
                                this.criteriaList = [...this.criteriaList];
                            })
                            .catch(error => {
                                console.error(error);
                                condition.picklistOptions = [];
                            });
                    }

                    this.criteriaList = [...this.criteriaList];
                })
                .catch(error => {
                    console.error(error);
                });
        }

        // Operator Change
        if (name === 'operator') {
            condition.operator = value;

            // show range ONLY for Date / DateTime + BETWEEN
            if (
                value &&
                value.toLowerCase() === 'between' &&
                (condition.fieldDataType === 'DATE' ||
                    condition.fieldDataType === 'DATETIME')
            ) {
                condition.showRange = true;
                condition.value = '';
            } else {
                condition.showRange = false;
                condition.fromValue = '';
                condition.toValue = '';
            }

            this.criteriaList = [...this.criteriaList];
        }
    }

    get showAddCriteriaButton() {
        return this.criteriaList.length > 0;
    }

    handleCancel(){
        this.showCriteriaSection = false;
        this.isCancelled = true;
        this.selectedObject = '';
    }

    handleSubmit() {

        for (let crit of this.criteriaList) {

            // Only validate CUSTOM condition logic
            if (crit.conditionCriteria === 'Custom') {

                const totalConditions = crit.conditions.length;
                const logic = crit.conditionLogic;

                if (!logic) {
                    this.showError('Condition Logic is required for Custom criteria');
                    return;
                }

                // Extract numbers from logic (1 AND 2 OR 3 → [1,2,3])
                const numbersUsed = logic.match(/\d+/g);

                if (!numbersUsed) {
                    this.showError('Invalid Condition Logic format');
                    return;
                }

                for (let num of numbersUsed) {
                    if (parseInt(num, 10) > totalConditions) {
                        this.showError(
                            `Invalid Condition Logic: Condition ${num} does not exist`
                        );
                        return;
                    }
                }
            }
        }

        const payload = this.criteriaList.map(crit => ({
            criteriaId: crit.recordId,
            isExisting: crit.isExisting,
            criteriaName: crit.criteriaName,
            score: crit.score,
            conditionCriteria: crit.conditionCriteria,
            conditionLogic: crit.showConditionLogic ? crit.conditionLogic : '',
            conditions: (crit.conditions || []).map(cond => ({
                conditionId: cond.recordId,
                field: cond.field,
                operator: cond.operator,
                value: cond.value,
                fromValue: cond.fromValue,
                toValue: cond.toValue,
                serial: cond.serial
            }))
        }));

        submitScoringData({
            objectName: this.selectedObject,
            criteriaList: payload,
            deletedCriteriaIds: this.deletedCriteriaIds,
            deletedConditionIds: this.deletedConditionIds
        })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Scoring Rule created successfully',
                        variant: 'success'
                    })
                );
                
                this.showCriteriaSection = false;
                this.isSubmitted = true;
                this.selectedObject = '';
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body?.message || 'Something went wrong',
                        variant: 'error'
                    })
                );
            });

    }

    reindexConditionsForCriteria(critIndex) {
        const conditions = this.criteriaList[critIndex].conditions;

        conditions.forEach((cond, index) => {
            cond.serial = index + 1;
        });
    }

    showError(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Validation Error',
                message: message,
                variant: 'error'
            })
        );
    }

    get showFooterButtons(){
        return !this.isSubmitted && !this.isCancelled;
    }
}