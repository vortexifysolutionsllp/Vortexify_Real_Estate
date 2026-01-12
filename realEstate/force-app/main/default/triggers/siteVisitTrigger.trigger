trigger siteVisitTrigger on Site_Visit__c (before insert,after insert,after update) {

    if (Trigger.isbefore && Trigger.isInsert){
        SiteVisitTriggerHandler.updateVisitStatus(Trigger.new);
    }
     
    if (Trigger.isAfter && Trigger.isInsert) {

        // Email 
        SiteVisitTriggerHandler.sendEmail(Trigger.new);
        SiteVisitTriggerHandler.sendEmailToSalesRep(Trigger.new);

        // Project Interest Creation
        SiteVisitTriggerHandler.createProjectInterestIfMissing(Trigger.new);
        SiteVisitTriggerHandler.updateLeadWhenScheduled(Trigger.new,Trigger.oldMap); 
        SiteVisitTriggerHandler.createFollowUpTasks(Trigger.new,Trigger.oldMap); 
    }
    
      if (Trigger.isAfter && Trigger.isupdate) {
          SiteVisitTriggerHandler.updateLeadWhenFeedbackReceived(Trigger.new);     
              SiteVisitTriggerHandler.updateLeadWhenComplete(Trigger.new);
          SiteVisitTriggerHandler.createFollowUpTasks(Trigger.new,Trigger.oldMap); 
}
}