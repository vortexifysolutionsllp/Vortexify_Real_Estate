public with sharing class LeadTriggerHandler {
    public static void createFollowUpTask(List<Lead> newLeads) {

        List<Task> taskList = new List<Task>();

        for (Lead ld : newLeads) {
            if (ld.Id != null) {

                Task t = new Task();
                t.Subject = 'Follow up with Lead';
                 t.WhoId = ld.Id;           // Related to Lead
                t.OwnerId = ld.OwnerId; 
                t.Status = 'Not Started';
                t.Priority = 'Normal';
			    taskList.add(t);
            }
        }

        if (!taskList.isEmpty()) {
            insert taskList;
        }
    }
}