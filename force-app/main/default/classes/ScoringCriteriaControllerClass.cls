public with sharing class ScoringCriteriaControllerClass {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getScoringObjects(){

        Scoring_Object__mdt cfg = [Select Object_API_Names__c from Scoring_Object__mdt LIMIT 1];

        Map<String, Schema.SObjectType> globalMap = Schema.getGlobalDescribe();

        Map<String, String> labelToApi = new Map<String, String>();
        List<String> labels = new List<String>();

        // if Metadata blank show all objects
        if(cfg == null || String.isBlank(cfg.Object_API_Names__c)){
            for(String apiName : globalMap.keySet()){
                Schema.DescribeSObjectResult d = globalMap.get(apiName).getDescribe();
                labelToApi.put(d.getLabel(), apiName);
                labels.add(d.getLabel());
            }
        }
        // Metadata has object list
        else{
            for(String apiName : cfg.Object_API_Names__c.split(',')){
                apiName = apiName.trim();
                if(globalMap.containsKey(apiName)){
                    Schema.DescribeSObjectResult d =globalMap.get(apiName).getDescribe();
                    labelToApi.put(d.getLabel(), apiName);
                    labels.add(d.getLabel());
                }
            }
        }
        labels.sort();

        List<Map<String, String>> result = new List<Map<String, String>>();

        for(String label : labels){
            result.add(new Map<String, String>{
                'label' => label,
                'value' => labelToApi.get(label)
            });
        }

        return result;
    }

    //Show fields for selected object
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getObjectFields(String objectName){
        List<Map<String, String>> fields = new List<Map<String, String>>();
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(objectName);

        if (sot != null) {
            for (Schema.SObjectField f : sot.getDescribe().fields.getMap().values()) {
                Schema.DescribeFieldResult d = f.getDescribe();
                fields.add(new Map<String, String>{
                    'label' => d.getLabel(),
                    'value' => d.getName()
                });
            }
       }
       return fields;
    }

    @AuraEnabled(cacheable=true)
    public static String getFieldDataType(String objectApiName, String fieldApiName){
        if(objectApiName == null || fieldApiName == null){
            return null;
        }

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectType = schemaMap.get(objectApiName);

        if(sObjectType != null){
            Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
            Schema.SObjectField sObjectField = fieldMap.get(fieldApiName);

            if(sObjectField != null){
                Schema.DescribeFieldResult fieldResult = sObjectField.getDescribe();
                // return field data type as string
                return fieldResult.getType().name(); 
            }
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPicklistValues(String objectApiName, String fieldApiName){
        List<Map<String, String>> values = new List<Map<String, String>>();

        if(String.isBlank(objectApiName) || String.isBlank(fieldApiName)){
            return values;
        }

        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        if(objType == null) return values;

        Schema.SObjectField field = objType.getDescribe().fields.getMap().get(fieldApiName);
        if(field == null) return values;

        Schema.DescribeFieldResult dfr = field.getDescribe();

        if(dfr.getType() == Schema.DisplayType.Picklist ||
            dfr.getType() == Schema.DisplayType.MultiPicklist){

            for (Schema.PicklistEntry pe : dfr.getPicklistValues()){
                values.add(new Map<String, String>{
                    'label' => pe.getLabel(),
                    'value' => pe.getValue()
                });
            }
        }

        return values;
    }

    @AuraEnabled
    public static void submitScoringData(String objectName, List<CriteriaWrapper> criteriaList, List<Id> deletedCriteriaIds, List<Id> deletedConditionIds) {

        // Delect Condition
        if (deletedConditionIds != null && !deletedConditionIds.isEmpty()) {

            List<Scoring_Condition__c> condsToDelete = [
                SELECT Id
                FROM Scoring_Condition__c
                WHERE Id IN :deletedConditionIds
            ];

            if (!condsToDelete.isEmpty()) {
                delete condsToDelete;
            }
        }

        // Delect Criteria after Condition
        if (deletedCriteriaIds != null && !deletedCriteriaIds.isEmpty()) {

            List<Scoring_Criteria__c> critToDelete = [
                SELECT Id
                FROM Scoring_Criteria__c
                WHERE Id IN :deletedCriteriaIds
            ];

            if (!critToDelete.isEmpty()) {
                delete critToDelete;
            }
        }


        if (String.isBlank(objectName) || criteriaList == null || criteriaList.isEmpty()) {
            throw new AuraHandledException('Invalid scoring data received.');
        }

        /* CHECK EXISTING SCORING RULE */
        Scoring_Rule__c scoringRule;

        List<Scoring_Rule__c> existingRules = [ SELECT Id, Object__c FROM Scoring_Rule__c WHERE Object__c = :objectName LIMIT 1];

        if (!existingRules.isEmpty()) {
            scoringRule = existingRules[0];
        } else {
            scoringRule = new Scoring_Rule__c(
                Name = objectName + ' Scoring Rule',
                Object__c = objectName,
                Active__c = true
            );
            insert scoringRule;
        }

        /*FETCH EXISTING CRITERIA (FOR DUPLICATE CHECK) */
        Map<String, Scoring_Criteria__c> existingCriteriaMap = new Map<String, Scoring_Criteria__c>();

        for (Scoring_Criteria__c sc : [
            SELECT Id, Score_to_be_Awarded__c, Condition_Criteria__c, Condition_Logic__c
            FROM Scoring_Criteria__c
            WHERE Scoring_Rule__c = :scoringRule.Id
        ]) {
            String key =
                sc.Score_to_be_Awarded__c + '|' +
                sc.Condition_Criteria__c + '|' +
                String.valueOf(sc.Condition_Logic__c);
    
            existingCriteriaMap.put(key, sc);
        }

        /* CREATE ONLY NEW SCORING CRITERIA */
        List<Scoring_Criteria__c> criteriaToInsert = new List<Scoring_Criteria__c>();
        List<CriteriaWrapper> newCriteriaWrappers = new List<CriteriaWrapper>();

        System.debug('criteriaList-->'+criteriaList);
        for (CriteriaWrapper crit : criteriaList) {

            // Update Existing Scoring Criteria
            if (crit.isExisting == true) {

                // Find existing criteria record
                Scoring_Criteria__c existingCrit = [
                    SELECT Id
                    FROM Scoring_Criteria__c
                    WHERE Id = :crit.criteriaId
                    LIMIT 1
                ];

                existingCrit.Name = crit.criteriaName;
                existingCrit.Score_to_be_Awarded__c = crit.score;
                existingCrit.Condition_Criteria__c = crit.conditionCriteria;
                existingCrit.Condition_Logic__c = crit.conditionLogic;

                update existingCrit;

                // ✅ Update Conditions also
                List<Scoring_Condition__c> condUpdates = new List<Scoring_Condition__c>();
                List<Scoring_Condition__c> condInserts = new List<Scoring_Condition__c>();

                for (ConditionWrapper cond : crit.conditions) {

                    String finalValue = '';

                    if (String.isNotBlank(cond.fromValue) && String.isNotBlank(cond.toValue)) {
                        finalValue = cond.fromValue + ' AND ' + cond.toValue;
                    } else {
                        finalValue = cond.value;
                    }

                    if(cond.conditionId != null){
                        Scoring_Condition__c existingCond = [
                        SELECT Id
                        FROM Scoring_Condition__c
                        WHERE Id = :cond.conditionId
                        LIMIT 1
                    ];

                    existingCond.Field__c = cond.field;
                    existingCond.Operator__c = cond.operator;
                    existingCond.Value__c = finalValue;
                    existingCond.Index__c = cond.serial;

                    condUpdates.add(existingCond);
                    }
                    else{
                        Scoring_Condition__c newCond = new Scoring_Condition__c(Name = 'Condition for ' + existingCrit.Name,
                        Scoring_Criteria__c = existingCrit.Id, Object__c  = objectName, Field__c = cond.field, Operator__c = cond.operator, 
                        Value__c  = finalValue, Index__c = cond.serial);
                        condInserts.add(newCond);                    
                    }
                }

                if (!condUpdates.isEmpty()) {
                    update condUpdates;
                }
                if(!condInserts.isEmpty()){
                    insert condInserts;
                }

                continue; // Existing handled
            }

            System.debug('crit-->'+crit);
            String key =
                crit.score + '|' +
                crit.conditionCriteria + '|' +
                String.valueOf(crit.conditionLogic);

            if (!existingCriteriaMap.containsKey(key)) {

                Scoring_Criteria__c criteria = new Scoring_Criteria__c(
                    Object__c = objectName,
                    Scoring_Rule__c = scoringRule.Id,
                    Score_to_be_Awarded__c = crit.score,
                    Condition_Criteria__c = crit.conditionCriteria,
                    Name = String.isNotBlank(crit.criteriaName)
                        ? crit.criteriaName
                        : 'Criteria for ' + scoringRule.Name,
                    Condition_Logic__c = String.isNotBlank(crit.conditionLogic)
                        ? crit.conditionLogic
                        : null
                );

                criteriaToInsert.add(criteria);
                newCriteriaWrappers.add(crit);
            }
        }

        if (!criteriaToInsert.isEmpty()) {
            insert criteriaToInsert;
        }

        /* CREATE CONDITIONS ONLY FOR NEW CRITERIA */
        List<Scoring_Condition__c> conditionRecords = new List<Scoring_Condition__c>();

        for (Integer i = 0; i < criteriaToInsert.size(); i++) {

            CriteriaWrapper critWrap = newCriteriaWrappers[i];

            if (critWrap.conditions == null) continue;

            for (ConditionWrapper cond : critWrap.conditions) {

                String finalValue = '';

                if (String.isNotBlank(cond.fromValue) && String.isNotBlank(cond.toValue)) {
                    finalValue = cond.fromValue + ' AND ' + cond.toValue;
                } else if (String.isNotBlank(cond.value)) {
                    finalValue = cond.value;
                }

                Scoring_Condition__c condition = new Scoring_Condition__c(
                    Name = 'Condition for ' + criteriaToInsert[i].Name,
                    Scoring_Criteria__c = criteriaToInsert[i].Id,
                    Object__c = objectName,
                    Field__c = cond.field,
                    Operator__c = cond.operator,
                    Value__c = finalValue,
                    Index__c = cond.serial
                );

                conditionRecords.add(condition);
            }
        }

        if (!conditionRecords.isEmpty()) {
            insert conditionRecords;
        }
    }

    @AuraEnabled
        public static List<ExistingScoringWrapper> getExistingScoringData(String objectName) {

        List<ExistingScoringWrapper> response = new List<ExistingScoringWrapper>();

    Scoring_Rule__c rule = [
        SELECT Id
        FROM Scoring_Rule__c
        WHERE Object__c = :objectName
        LIMIT 1
    ];

    if (rule == null) return response;

    List<Scoring_Criteria__c> criteriaList = [
        SELECT Id, Name, Score_to_be_Awarded__c,
               Condition_Criteria__c, Condition_Logic__c
        FROM Scoring_Criteria__c
        WHERE Scoring_Rule__c = :rule.Id
        ORDER BY CreatedDate
    ];

    Map<Id, List<Scoring_Condition__c>> conditionMap = new Map<Id, List<Scoring_Condition__c>>();

    for (Scoring_Condition__c c : [
        SELECT Scoring_Criteria__c, Field__c, Operator__c, Value__c, Index__c
        FROM Scoring_Condition__c
        WHERE Scoring_Criteria__c IN :criteriaList
        ORDER BY Index__c
    ]) {
        if (!conditionMap.containsKey(c.Scoring_Criteria__c)) {
    conditionMap.put(c.Scoring_Criteria__c, new List<Scoring_Condition__c>());
}
conditionMap.get(c.Scoring_Criteria__c).add(c);

    }

    for (Scoring_Criteria__c sc : criteriaList) {
        ExistingScoringWrapper wrap = new ExistingScoringWrapper();
        wrap.criteriaId = sc.Id;
        wrap.criteriaName = sc.Name;
        wrap.score = sc.Score_to_be_Awarded__c != null ? sc.Score_to_be_Awarded__c.intValue() : null;

        wrap.conditionCriteria = sc.Condition_Criteria__c;
        wrap.conditionLogic = sc.Condition_Logic__c;
        wrap.conditions = new List<ExistingConditionWrapper>();

        for (Scoring_Condition__c cond : conditionMap.get(sc.Id)) {
            ExistingConditionWrapper cw = new ExistingConditionWrapper();
            cw.conditionId = cond.Id;
            cw.field = cond.Field__c;
            cw.operator = cond.Operator__c;
            cw.value = cond.Value__c;
            cw.serial = Integer.valueOf(cond.Index__c);
            wrap.conditions.add(cw);
        }

        response.add(wrap);
    }

    return response;
}


    public class CriteriaWrapper {
        @AuraEnabled public Id criteriaId {get;set;}
        @AuraEnabled public String criteriaName {get;set;}
        @AuraEnabled public Integer score {get;set;}
        @AuraEnabled public String conditionCriteria {get;set;}
        @AuraEnabled public String conditionLogic {get;set;}
        @AuraEnabled public Boolean isExisting  {get;set;}
        @AuraEnabled public List<ConditionWrapper> conditions {get;set;}
    }

    public class ConditionWrapper {
        @AuraEnabled public Id conditionId {get;set;}
        @AuraEnabled public String field {get;set;}
        @AuraEnabled public String operator {get;set;}
        @AuraEnabled public String value {get;set;}
        @AuraEnabled public String fromValue {get;set;}
        @AuraEnabled public String toValue {get;set;}
        @AuraEnabled public String serial {get;set;}
    }

    public class ExistingScoringWrapper {
        @AuraEnabled public Id criteriaId;
        @AuraEnabled public String criteriaName;
        @AuraEnabled public Integer score;
        @AuraEnabled public String conditionCriteria;
        @AuraEnabled public String conditionLogic;
        @AuraEnabled public List<ExistingConditionWrapper> conditions;
    }

    public class ExistingConditionWrapper {
        @AuraEnabled public Id conditionId;
        @AuraEnabled public String field;
        @AuraEnabled public String operator;
        @AuraEnabled public String value;
        @AuraEnabled public Integer serial;
    }
}