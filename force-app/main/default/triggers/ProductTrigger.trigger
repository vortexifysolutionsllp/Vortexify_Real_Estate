trigger ProductTrigger on Product2 (after insert, before insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        ProductTriggerHandler.createPBE(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isInsert) {
        ProductTriggerHandler.handleBeforeInsert(Trigger.new);
        //ProductTriggerHandler.preventDuplicatePLCCreation(Trigger.New);
    }
}