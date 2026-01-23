trigger OpportunityTrigger on Opportunity (after update) {

    if (Trigger.isAfter && Trigger.isUpdate) {
        OpportunityTriggerHandler.handleStageChange(
            Trigger.new,
            Trigger.oldMap
        );
    }

}
