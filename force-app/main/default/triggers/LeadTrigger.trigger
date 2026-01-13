trigger LeadTrigger on Lead (before insert, after insert) {
    if(Trigger.isBefore && Trigger.isInsert){
        LeadTriggerHandler.preventDuplicateLeadCreation(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        LeadTriggerHandler.createFollowUpTask(Trigger.new);
    }
}