trigger LeadTrigger on Lead (before insert, after insert,after update) {
    if(Trigger.isBefore && Trigger.isInsert){
        LeadTriggerHandler.preventDuplicateLeadCreation(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        LeadTriggerHandler.createFollowUpTask(Trigger.new);
    }
    
    if(Trigger.isAfter && Trigger.isUpdate){
        LeadTriggerHandler.createFollowUpTaskWhenSiteVisit(Trigger.new, Trigger.oldMap);
        
    }
}