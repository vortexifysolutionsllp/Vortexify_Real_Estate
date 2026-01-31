trigger ScoringCriteriaTrigger on Lead (before insert, before update) {

    if (ScoringTriggerGuard.isRunning) {
        return;
    }

    ScoringTriggerGuard.isRunning = true;

    ScoringTriggerHandler.run(Trigger.new);

    ScoringTriggerGuard.isRunning = false;
}