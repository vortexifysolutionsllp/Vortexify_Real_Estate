trigger ConstructionUpdateTrigger on Construction_update__c (after insert, after update) {
    Set<Id> cuIds = new Set<Id>();
    for (Construction_Update__c cu : Trigger.new) {
        if(trigger.isUpdate && trigger.oldMap.get(cu.Id).Is_Payment_Triggered__c == cu.Is_Payment_Triggered__c){
            System.debug('Is_Payment_Triggered__c changed');
            System.debug('Old: ' + trigger.oldMap.get(cu.Id).Is_Payment_Triggered__c);
            System.debug('New: ' + cu.Is_Payment_Triggered__c);
            cuIds.add(cu.Id);
        }else if(trigger.isInsert){
            cuIds.add(cu.Id);
        }
    }

    if (!cuIds.isEmpty()) {
        System.enqueueJob(new ConstructionUpdateQueueable(cuIds));
    }
}