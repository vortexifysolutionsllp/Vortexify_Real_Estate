//payment boooking apex

public with sharing class BookingController {

    // Fetch Project and Tower from Booking (Opportunity)
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getProjectAndTowerFromBooking(Id oppId) {

        Map<String, Object> result = new Map<String, Object>();
        if (oppId == null) return result;

        List<OpportunityLineItem> oliList = [
            SELECT Id,
                   Product2.Tower__c,
                   Product2.Tower__r.Project__c,
                   Product2.Tower__r.Project__r.Name,
                   Product2.Tower__r.Project__r.Location__c,
                   Product2.Tower__r.Project__r.RERA_Number__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :oppId
            AND Product2.Family = 'Unit'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (!oliList.isEmpty()) {
            OpportunityLineItem oli = oliList[0];
            if (oli.Product2.Tower__r != null &&
                oli.Product2.Tower__r.Project__r != null) {

                result.put('tower', oli.Product2.Tower__r);
                //result.put('project', oli.Product2.Tower__r.Project__r);
                result.put('project', oli.Product2.Tower__r.Project__r);
                result.put('projectId', oli.Product2.Tower__r.Project__c);

            }
        }

        return result;
    }

    // Total towers for project
    @AuraEnabled(cacheable=true)
    public static Integer getTowerCountByProject(Id projectId) {
        if (projectId == null) return 0;

        return [
            SELECT COUNT()
            FROM Tower__c
            WHERE Project__c = :projectId
        ];
    }

    // Total units for project
    @AuraEnabled(cacheable=true)
    public static Integer getUnitCountByProject(Id projectId) {
        if (projectId == null) return 0;

        return [
            SELECT COUNT()
            FROM Product2
            WHERE Tower__c IN (
                SELECT Id
                FROM Tower__c
                WHERE Project__c = :projectId
            )
        ];
    }

    // Fetch Payment Policies for a Project
    @AuraEnabled(cacheable=true)
    public static List<Policy__c> getPaymentPoliciesByProject(Id projectId) {
        if (projectId == null) return new List<Policy__c>();

        return [
            SELECT Id, Name, Type__c
            FROM Policy__c
            WHERE Applicable_Project__c = :projectId
              AND Type__c LIKE '%Payment%' 
            ORDER BY Name
        ];
    }

    // Fetch Booking Unit Details from OLI (Family = Unit)
    @AuraEnabled(cacheable=true)
    public static OpportunityLineItem getUnitBookingDetails(Id oppId) {
        if (oppId == null) return null;

        List<OpportunityLineItem> oliList = [
            SELECT Id,
                   UnitPrice,
                   TotalPrice,
                   Quantity,
                   Product2.Name,
                   Product2.UnitNumber__c,
                   Product2.SaleableArea__c,
                   Product2.CarpetArea__c,
                   Product2.Family
            FROM OpportunityLineItem
            WHERE OpportunityId = :oppId
              AND Product2.Family = 'Unit'
            LIMIT 1
        ];

        return oliList.isEmpty() ? null : oliList[0];
    }

    // Save Payment Policy in Booking (Opportunity)
    @AuraEnabled
    public static void savePaymentPolicy(Id bookingId, Id paymentPolicyId, Decimal totalDealCost) {
        if (bookingId == null || paymentPolicyId == null) return;

        Opportunity opp = [
            SELECT Id, Payment_Policy__c
            FROM Opportunity
            WHERE Id = :bookingId
            LIMIT 1
        ];

        opp.Payment_Policy__c = paymentPolicyId;
        update opp;
        if (totalDealCost != null) {

        OpportunityLineItem oli = [
            SELECT Id, UnitPrice
            FROM OpportunityLineItem
            WHERE OpportunityId = :bookingId
            LIMIT 1
        ];

        oli.UnitPrice = totalDealCost;
        update oli;
    }

    }

    // 🔹 NEW METHOD: Fetch Cost/Sqft from Policy
    @AuraEnabled(cacheable=false)
    public static Decimal getCostPerSqftByPolicy(Id policyId) {
        if (policyId == null) return null;

        Policy__c policy = [
            SELECT Cost_Sqft__c
            FROM Policy__c
            WHERE Id = :policyId
            LIMIT 1
        ];

        return policy.Cost_Sqft__c;
    }
}
