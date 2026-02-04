trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, after insert) {
    // if(Trigger.isBefore && Trigger.isInsert){
    //     OpportunityLineItemTriggerHandler.validateOliCount(Trigger.NEW);
    // }
    if(Trigger.isAfter && Trigger.isInsert){
        OpportunityLineItemTriggerHandler.createPLC(Trigger.new);
    }
}