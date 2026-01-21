trigger ConstructionUpdateTrigger on Construction_update__c (after insert, after update) {
    Set<Id> cuIds = new Set<Id>();
    for (Construction_Update__c cu : Trigger.new) {
        cuIds.add(cu.Id);
    }

    if (!cuIds.isEmpty()) {
        System.enqueueJob(new ConstructionUpdateQueueable(cuIds));
    }
}