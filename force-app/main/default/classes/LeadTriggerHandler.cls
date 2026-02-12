public with sharing class LeadTriggerHandler { 
    
    public static void preventDuplicateLeadCreation(List<Lead> newLeads){
        Set<String> emailSet  = new Set<String>();
        Set<String> phoneSet  = new Set<String>();
        Set<String> mobileSet = new Set<String>();

        for (Lead ld : newLeads) {
            if (String.isNotBlank(ld.Email)) {
                emailSet.add(ld.Email.toLowerCase());
            }
            if (String.isNotBlank(ld.Phone)) {
                phoneSet.add(ld.Phone);
            }
            if (String.isNotBlank(ld.MobilePhone)) {
                mobileSet.add(ld.MobilePhone);
            }
        }

        if (emailSet.isEmpty() && phoneSet.isEmpty() && mobileSet.isEmpty()) {
            return;
        }

        // Query existing leads
        List<Lead> existingLeads = [SELECT Id, Email, Phone, MobilePhone FROM Lead WHERE Email IN :emailSet OR Phone IN :phoneSet OR MobilePhone IN :mobileSet];

        // Compare incoming leads with existing ones
        for (Lead newLd : newLeads) {

            for (Lead oldLd : existingLeads) {

                Boolean group1Match =(String.isNotBlank(newLd.Email) && newLd.Email.equalsIgnoreCase(oldLd.Email)) ||
                                     (String.isNotBlank(newLd.Phone) && newLd.Phone == oldLd.Phone);

                Boolean group2Match =(String.isNotBlank(newLd.Email) && newLd.Email.equalsIgnoreCase(oldLd.Email)) ||
                                     (String.isNotBlank(newLd.MobilePhone) && newLd.MobilePhone == oldLd.MobilePhone);

                // (Email OR Phone) AND (Email OR Mobile)
                if (group1Match && group2Match) {
                    newLd.addError('Duplicate Lead found. A lead already exists with matching Email/Phone/Mobile.');
                    break;
                }
            }
        }
    }
    
    public static void createFollowUpTask(List<Lead> newLeads) {

        List<Task> taskList = new List<Task>();

        for (Lead ld : newLeads) {
            if (ld.Id != null) {

                Task t = new Task();
                t.Subject = 'Follow up with Lead';
                t.WhoId = ld.Id;
                t.ActivityDate = Date.today()+1;
                t.Description = 'Follow up with the new lead to confirm interest, understand requirements, and share initial project details. Schedule the next step, such as a call or site visit.';
                t.Status = 'Not Started';
                t.Priority = 'Normal';
			    taskList.add(t);
            }
        }

        if (!taskList.isEmpty()) {
            insert taskList;
        }
    }
    
        public static void createFollowUpTaskWhenSiteVisit(List<Lead> newLeads, Map<Id, Lead> oldMap){

        List<Task> taskList = new List<Task>();
        Set<Id> leadIds = new Set<Id>();
        for(Lead newLead: newLeads){
            if((newLead.Status != oldMap.get(newLead.Id).Status) && (newLead.Status == 'Site Visit Scheduled' || newLead.Status == 'Site Visit Completed')){
                leadIds.add(newLead.Id);
            }
        }

        if(leadIds.isEmpty()){
            return;
        }

        Map<Id, Site_Visit__c> leadSiteVisitMap = new Map<Id, Site_Visit__c>();
        List<Site_Visit__c> siteVisitList = [SELECT Id, Lead__c, VisitDate__c, Visit_Time__c, Visit_Status__c FROM Site_Visit__c WHERE Lead__c IN :leadIds AND VisitDate__c != null ORDER BY VisitDate__c DESC Limit 1];
        for(Site_Visit__c siteVisit: siteVisitList){
            if(!leadSiteVisitMap.containsKey(siteVisit.Lead__c)){
                leadSiteVisitMap.put(siteVisit.Lead__c, siteVisit);
            }
        }

        for(Lead newLead : newLeads){
            if(!leadIds.contains(newLead.Id)){
                continue;
            }

            Site_Visit__c latestVisit = leadSiteVisitMap.get(newLead.Id);
            
            Lead oldLead = oldMap.get(newLead.Id);

            if(newLead.Status != oldLead.Status){

                if(newLead.Status == 'Site Visit Scheduled' ||
                   newLead.Status == 'Site Visit Completed'){

                    Task t = new Task();
                    t.Subject = 'Follow up - ' + newLead.Status;
                    t.WhoId = newLead.Id;  
				    t.OwnerId = newLead.OwnerId;
                    t.Status = 'Not Started';
                    t.Priority = 'Normal';
                    t.ActivityDate = latestVisit.VisitDate__c.addDays(-1);

                    taskList.add(t);
                }
            }
        }

        if(!taskList.isEmpty()){
            insert taskList;
        }
    }
}