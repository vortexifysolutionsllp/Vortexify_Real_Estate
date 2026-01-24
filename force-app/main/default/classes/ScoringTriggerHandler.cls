public class ScoringTriggerHandler {

    public static void run(List<Lead> newLeads) {

        if (newLeads == null || newLeads.isEmpty()) return;

        ScoringCriteriaEngine.applyScoring(newLeads);
    }
}