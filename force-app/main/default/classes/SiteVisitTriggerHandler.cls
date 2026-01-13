public class SiteVisitTriggerHandler {
    
    public static void updateVisitStatus(List<Site_Visit__c> newVisits) {
        for (Site_Visit__c sv : newVisits) {
            if (sv.Visit_Status__c == null) {
                sv.Visit_Status__c = 'Scheduled';
            }
        }
    }
    public static void updateLeadWhenScheduled(List<Site_Visit__c> newVisits,Map<Id, Site_Visit__c> oldMap) {
        
        Set<Id> leadIds = new Set<Id>();
        
        for (Site_Visit__c sv : newVisits) {
           
            if ( sv.Visit_Status__c == 'Scheduled' ) {
                leadIds.add(sv.Lead__c);
            }
        }
        
        if (leadIds.isEmpty()) return;
        
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (Lead ld : [SELECT Id, Status FROM Lead WHERE Id IN :leadIds]) {
            
            if (ld.Status != 'Site Visit Scheduled') {
                ld.Status = 'Site Visit Scheduled';
                leadsToUpdate.add(ld);
            }
        }
        
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
    /*
    public static void updateLeadWhenFeedbackReceived(List<Site_Visit__c> newVisits) { 
        
        Set<Id> leadIds = new Set<Id>();
        Map<Id, Boolean> leadHasFeedback = new Map<Id, Boolean>();
        
        for (Site_Visit__c sv : newVisits) {
            
            if (sv.Lead__c != null && sv.Visit_Status__c == 'Completed') {
                
                leadIds.add(sv.Lead__c);
                
                // store feedback info (your existing logic preserved)
                if (sv.Feedback_Received__c == true) {
                    leadHasFeedback.put(sv.Lead__c, true);
                }
            }
        }
        
        if (leadIds.isEmpty()) return;
        
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (Lead ld : [
            SELECT Id, Status
            FROM Lead
            WHERE Id IN :leadIds
        ]) {
            
            // 🔹 NEW CONDITION ADDED
            if (leadHasFeedback.containsKey(ld.Id)) {
                ld.Status = 'Feedback Received';   // existing behavior
            } else {
                ld.Status = 'Completed';           // ✅ NEW behavior
            }
            
            leadsToUpdate.add(ld);
        }
         
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }*/
    
     public static void updateLeadWhenComplete(List<Site_Visit__c> newVisits) {
        
        Set<Id> leadIds = new Set<Id>();
        
        for (Site_Visit__c sv : newVisits) {
            if (
                sv.Lead__c != null && sv.Visit_Status__c == 'Completed') {
                leadIds.add(sv.Lead__c);
            }
        }
        
        
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (Lead ld : [SELECT Id, Status FROM Lead WHERE Id IN :leadIds]) {
            ld.Status = 'Site Visit Completed';
            leadsToUpdate.add(ld);
        }
        
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
    

   
 public static void updateLeadWhenFeedbackReceived(List<Site_Visit__c> newVisits) {
        
        Set<Id> leadIds = new Set<Id>();
        
        for (Site_Visit__c sv : newVisits) {
            if (
                sv.Lead__c != null && sv.Visit_Status__c == 'Completed' && sv.Feedback_Received__c == true) {
                leadIds.add(sv.Lead__c);
            }
        }
        
        
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (Lead ld : [SELECT Id, Status FROM Lead WHERE Id IN :leadIds]) {
            ld.Status = 'Feedback Received';
            leadsToUpdate.add(ld);
        }
        
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
    
    
     //Follow up task on site Visit 
        public static void createFollowUpTasks(List<Site_Visit__c> newVisits,Map<Id, Site_Visit__c> oldMap) {

        List<Task> tasksToInsert = new List<Task>();

        for (Site_Visit__c sv : newVisits) {
            if (sv.Id == null || sv.Lead__c == null) {
                continue;
            }

            String newStatus = sv.Visit_Status__c;
            String oldStatus = (oldMap != null && oldMap.containsKey(sv.Id))
                ? oldMap.get(sv.Id).Visit_Status__c
                : null;

            // 🔹 When Status = Scheduled
            if (newStatus == 'Scheduled' && newStatus != oldStatus) {

                Task t = new Task();
                t.Subject = 'Site Visit Scheduled – Follow Up';
                t.WhatId = sv.Id;      
                t.OwnerId = sv.OwnerId;
                t.Status = 'Not Started';
                t.Priority = 'Normal';
                t.Description = 'Prepare for the scheduled site visit. Coordinate with the customer, confirm date and time, and ensure all visit details are in place.';
                t.ActivityDate = sv.VisitDate__c;

                tasksToInsert.add(t);
            }

            // When Status = Completed
            if (newStatus == 'Completed' && newStatus != oldStatus) {

                Task t = new Task();
                t.Subject = 'Site Visit Completed – Follow Up';
                t.WhatId = sv.Id;      
                t.OwnerId = sv.OwnerId;
                t.Status = 'Not Started';
                t.Priority = 'Normal';
                t.Description = 'Prepare for the scheduled site visit. Coordinate with the customer, confirm date and time, and ensure all visit details are in place.';
                t.ActivityDate = sv.VisitDate__c;

                tasksToInsert.add(t);
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
        
    // Send Email Method 
    public static void sendEmail(List<Site_Visit__c> siteVisits) {

        
        siteVisits = [
            SELECT Id,
                   CustomerName__c,
                   CustomerEmail__c,
                   VisitDate__c,
                   Visit_Time__c,
                   Project__r.Name,
                   Project__r.Location__c,
                   Sales_Representative__r.Name
            FROM Site_Visit__c
            WHERE Id IN :siteVisits
        ];

        for (Site_Visit__c visit : siteVisits) {

            if (visit.CustomerEmail__c != null) {

                String formattedDate = formatDate(visit.VisitDate__c);
                String formattedTime = formatTime(visit.Visit_Time__c);

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{ visit.CustomerEmail__c });
                mail.setSubject('Site Visit Confirmation');

                String emailBody =
                    'Hello ' + visit.CustomerName__c + ',\n\n' +
                    'Thank you for your interest in ' +visit.Project__r.Name + ',\n\n' +
                    'We are pleased to inform you that your site visit has been scheduled as per the details below:\n\n' +
                    'Project: ' + visit.Project__r.Name + '\n' +
                    'Visit Date: ' + formattedDate + '\n' +
                    'Visit Time: ' + formattedTime + '\n' +
                    'Location: ' + visit.Project__r.Location__c + '\n' +
                    'Sales Representative: ' + visit.Sales_Representative__r.Name + '\n\n' +
                    'We look forward to welcoming you.\n\n' +
                    'Warm Regards,\n' +
                    'Vortexify Solution LLP';

                mail.setPlainTextBody(emailBody);

                try {
                    Messaging.sendEmail(
                        new List<Messaging.SingleEmailMessage>{ mail }
                    );
                } catch (System.EmailException e) {
                    System.debug(
                        'Customer email failed. Site Visit still saved. Error: '
                        + e.getMessage()
                    );
                }
            }
        }
    }

public static void sendEmailToSalesRep(List<Site_Visit__c> siteVisits) { 

    List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
    Set<Id> salesRepIds = new Set<Id>();
         
    for (Site_Visit__c sv : siteVisits) {
        Id repId = sv.Sales_Representative__c != null
                 ? sv.Sales_Representative__c
                 : sv.OwnerId;

        if (repId != null) {
            salesRepIds.add(repId);
        }
    }

    if (salesRepIds.isEmpty()) return;

    Map<Id, User> userMap = new Map<Id, User>(
        [SELECT Id, Name, Email
         FROM User
         WHERE Id IN :salesRepIds
         AND IsActive = true
         AND Email != null]
    );

    for (Site_Visit__c sv : siteVisits) {

        User salesRep = userMap.get(
            sv.Sales_Representative__c != null
            ? sv.Sales_Representative__c
            : sv.OwnerId
        );
        if (salesRep == null) continue;

        String formattedDate = formatDate(sv.VisitDate__c);
        String formattedTime = formatTime(sv.Visit_Time__c);

        String siteVisitUrl =
            URL.getOrgDomainUrl().toExternalForm() +
            '/lightning/r/Site_Visit__c/' + sv.Id + '/view';

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ salesRep.Email });
        mail.setSaveAsActivity(false);
        mail.setSubject('New Site Visit Assigned');

        mail.setPlainTextBody(
            'Hello ' + salesRep.Name + ',\n\n' +
            'A site visit has been scheduled with the following details:\n\n' +
            'Customer Name: ' + sv.CustomerName__c + '\n' +
            'Customer Phone: ' + sv.Customer_Phone__c + '\n' +
            'Visit Date: ' + formattedDate + '\n' +
            'Visit Time: ' + formattedTime + '\n\n' +
            'Open Site Visit Record:\n' +
            siteVisitUrl + '\n\n' +
            'Please ensure you are prepared for the visit and reach out to the customer if required.\n\n' +
            'Regards,\nVortexify Solution LLP'
        );

        emailList.add(mail);
    }

    if (!emailList.isEmpty()) {
        try {
            Messaging.sendEmail(emailList);
        } catch (System.EmailException e) {
            System.debug(
                'Sales Rep email failed. Site Visit still saved. Error: '
                + e.getMessage()
            );
        }
    }
}

    // ================= Project Interest Method =================
    public static void createProjectInterestIfMissing(List<Site_Visit__c> siteVisits) {

        Set<Id> leadIds = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();

        for (Site_Visit__c sv : siteVisits) {
            if (sv.Lead__c != null && sv.Project__c != null) {
                leadIds.add(sv.Lead__c);
                projectIds.add(sv.Project__c);
            }
        }

        if (leadIds.isEmpty() || projectIds.isEmpty()) return;

        // Fetch Lead Names
        Map<Id, Lead> leadMap = new Map<Id, Lead>(
            [SELECT Id, Name FROM Lead WHERE Id IN :leadIds]
        );

        // Fetch Project Names
        Map<Id, Project__c> projectMap = new Map<Id, Project__c>(
            [SELECT Id, Name FROM Project__c WHERE Id IN :projectIds]
        );

        // Existing Project Interests
        Map<String, Project_Interest__c> existingMap = new Map<String, Project_Interest__c>();

        for (Project_Interest__c pi : [
            SELECT Id, Lead__c, Project__c, Site_Visit__c
            FROM Project_Interest__c
            WHERE Lead__c IN :leadIds
            AND Project__c IN :projectIds
        ]) {
            existingMap.put(pi.Lead__c + '-' + pi.Project__c, pi);
        }

        List<Project_Interest__c> toInsert = new List<Project_Interest__c>();
        List<Project_Interest__c> toUpdate = new List<Project_Interest__c>();

        for (Site_Visit__c sv : siteVisits) {
            if (sv.Lead__c == null || sv.Project__c == null) continue;

            String key = sv.Lead__c + '-' + sv.Project__c;

            if (existingMap.containsKey(key)) {

                // 🔁 UPDATE EXISTING PROJECT INTEREST
                Project_Interest__c existingPI = existingMap.get(key);
                existingPI.Site_Visit__c = sv.Id;
                toUpdate.add(existingPI);

            } else {

                // ➕ CREATE NEW PROJECT INTEREST
                Project_Interest__c pi = new Project_Interest__c();
                pi.Lead__c = sv.Lead__c;
                pi.Project__c = sv.Project__c;
                pi.Site_Visit__c = sv.Id;

                // Name = Lead Name / Project Name
                pi.Name = leadMap.get(sv.Lead__c).Name + ' / ' +
                          projectMap.get(sv.Project__c).Name;

                toInsert.add(pi);
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    // ================= HELPER METHODS =================

    private static String formatDate(Date d) {
        return d != null ? d.format() : 'N/A';
    }

    private static String formatTime(Time t) {
        if (t == null) return 'N/A';

        Date today = Date.today();
        Datetime dt = Datetime.newInstance(
            today.year(),
            today.month(),
            today.day(),
            t.hour(),
            t.minute(),
            t.second()
        );

        return dt.format('hh:mm a');
    }
}