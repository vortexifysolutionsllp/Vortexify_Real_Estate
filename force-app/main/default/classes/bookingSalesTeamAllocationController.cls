public with sharing class bookingSalesTeamAllocationController {

    @AuraEnabled(cacheable=true)
    public static List<Booking_Sales_Team_Allocation__c> getAllocations(Id parentId) {

        return [
            SELECT Id, User__c, Commission_Allocation__c
            FROM Booking_Sales_Team_Allocation__c
            WHERE Booking__c = :parentId
               OR Lead__c = :parentId
        ];
    }

    @AuraEnabled
    public static void createBookingSalesTeamAllocation(
        List<Booking_Sales_Team_Allocation__c> records
    ) {
        if (records == null || records.isEmpty()) return;
        upsert records;
    }

    @AuraEnabled
    public static void deleteBookingSalesTeamAllocation(List<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) return;

        delete [
            SELECT Id
            FROM Booking_Sales_Team_Allocation__c
            WHERE Id IN :recordIds
        ];
    }
}
