public with sharing class SiteVisitController {

    @AuraEnabled(cacheable=true)
    public static Lead getLeadDetails(Id leadId) {
        return [
            SELECT Id, Name, Email, Phone, OwnerId, Owner.Name
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjects() {
        return [
            SELECT Id, Name
            FROM Project__c
            ORDER BY Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Tower__c> getTowersByProject(Id projectId) {
        return [
            SELECT Id, Name
            FROM Tower__c
            WHERE Project__c = :projectId
            ORDER BY Name
        ];
    }

    @AuraEnabled
    public static List<Site_Visit__c> getSiteVisits(Id leadId) {
        return [
            SELECT Id,
                   CustomerName__c,
                   CustomerEmail__c,
                   Customer_Phone__c,
                   VisitDate__c,
                   Visit_Time__c,
                   VisitType__c,
                   Sales_Representative__c,
                   Project__c,
                   Tower__c
            FROM Site_Visit__c
            WHERE Lead__c = :leadId
        ];
    }

   
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getVisitTypePicklist() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        Schema.DescribeFieldResult fieldDesc =
            Site_Visit__c.VisitType__c.getDescribe();

        for (Schema.PicklistEntry pe : fieldDesc.getPicklistValues()) {
            if (pe.isActive()) {
                options.add(new Map<String, String>{
                    'label' => pe.getLabel(),
                    'value' => pe.getValue()
                });
            }
        }
        return options;
    }

    @AuraEnabled
    public static void createSiteVisit(
        Id leadId,
        String customerName,
        Date visitDate,
        String visitTime,
        String customerEmail,
        String visitType,
        String customerPhone,
        Id salesRepId,
        Id projectId,
        Id towerId
    ) {

        System.debug('leadId-------->>>'+leadId);
        Site_Visit__c visit = new Site_Visit__c();
        visit.CustomerName__c = customerName;
        visit.VisitDate__c = visitDate;

        if (visitTime != null) {
            List<String> timeParts = visitTime.split(':');
            visit.Visit_Time__c = Time.newInstance(
                Integer.valueOf(timeParts[0]),
                Integer.valueOf(timeParts[1]),
                0,
                0
            );
        }

        visit.CustomerEmail__c = customerEmail;
        visit.VisitType__c = visitType;
        visit.Customer_Phone__c = customerPhone;
        visit.Lead__c = leadId;
        visit.Sales_Representative__c = salesRepId;
        visit.Project__c = projectId;
        visit.Tower__c = towerId;

        insert visit;
    }


    @AuraEnabled
public static void deleteSiteVisit(Id visitId) {
    delete [SELECT Id FROM Site_Visit__c WHERE Id = :visitId];
}

}