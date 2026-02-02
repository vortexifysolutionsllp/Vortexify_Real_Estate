public with sharing class unitAllocationController {

    @AuraEnabled(cacheable=true)
    public static List<Tower__c> getTowersByProject(Id projectId) {
        if (projectId == null) {
            return new List<Tower__c>();
        }

        return [
            SELECT Id, Name, Total_Floors__c
            FROM Tower__c
            WHERE Project__c = :projectId
            ORDER BY Name
        ];
    }
}