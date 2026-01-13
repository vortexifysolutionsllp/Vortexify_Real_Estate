public with sharing class ObjectScoreIndicatorController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getProgressIndicatorData(Id recordId,String objectApiName ) {
        if (recordId == null || String.isBlank(objectApiName)) {
            return new Map<String, Integer>{
                'currentScore' => 0,
                'totalScore' => 0
            };
        }

        String recordQuery = 'SELECT Score__c FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1';
        SObject recordObj = Database.query(recordQuery);
        Integer currentScore = recordObj.get('Score__c') != null ? Integer.valueOf(recordObj.get('Score__c')) : 0;
        Scoring_Rule__c rule = [ SELECT Total_Score__c FROM Scoring_Rule__c WHERE Active__c = true AND Object__c = :objectApiName LIMIT 1];
        Integer totalScore = rule.Total_Score__c != null ? Integer.valueOf(rule.Total_Score__c): 0;

        return new Map<String, Integer>{
            'currentScore' => currentScore,
            'totalScore' => totalScore
        };
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getScoreDetails( Id recordId, String objectApiName) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
  
        if (recordId == null || String.isBlank(objectApiName)) {
            return result;
        }

        String recordQuery = 'SELECT Awarded_Criteria__c FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1';
        SObject recordObj = Database.query(recordQuery);
        String awardedCriteriaStr = (String) recordObj.get('Awarded_Criteria__c');

        Set<Id> awardedCriteriaIds = new Set<Id>();

        if (!String.isBlank(awardedCriteriaStr)) {
            for (String idStr : awardedCriteriaStr.split(',')) {
                awardedCriteriaIds.add((Id) idStr.trim());
            }
        }
 
        List<Scoring_Criteria__c> criteriaList = [ SELECT Id, Name, Score_to_be_Awarded__c FROM Scoring_Criteria__c WHERE Object__c = :objectApiName];
     
        for (Scoring_Criteria__c c : criteriaList) {
            Integer scoreToShow = awardedCriteriaIds.contains(c.Id) ? (c.Score_to_be_Awarded__c != null ? Integer.valueOf(c.Score_to_be_Awarded__c): 0): 0;

            result.add(new Map<String, Object>{
                'criteriaName' => c.Name,
                'score' => scoreToShow
            });
        }
        return result;
    }

}