trigger BookingTrigger on Opportunity (before insert, before update, after insert, after update) {
    if(Trigger.isBefore){
        BookingTriggerHandler.UpdateBookingStage(Trigger.new, Trigger.isUpdate ? Trigger.oldMap : null);
    }

    if(Trigger.isAfter){
        BookingTriggerHandler.createPaymentSchedule(Trigger.new, Trigger.isUpdate ? Trigger.oldMap : null);
        BookingTriggerHandler.createBookingCommissionAndUserCommissionAllocations(Trigger.new, Trigger.isUpdate ? Trigger.oldMap : null);
    }
}