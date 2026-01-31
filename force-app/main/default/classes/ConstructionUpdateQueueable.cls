public class ConstructionUpdateQueueable implements Queueable {

    private Set<Id> cuIds;

    public ConstructionUpdateQueueable(Set<Id> cuIds) {
        this.cuIds = cuIds;
    }

    public void execute(QueueableContext qc) {

        System.debug('Queueable context: ' + qc);
        List<Construction_Update__c> updates = [SELECT Id, Name, Is_Payment_Triggered__c, Project__c, Policy__c FROM Construction_Update__c WHERE Id IN :cuIds];
        System.debug('Updates: ' + updates);

        if (!updates.isEmpty()) {
            Database.executeBatch(new ConstructionUpdateBatch(updates),50);
        }
    }
}
