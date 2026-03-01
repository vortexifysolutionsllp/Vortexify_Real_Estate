public with sharing class LeadTriggerHandler { 
    
    // =========================
    // PREVENT DUPLICATE LEADS
    // =========================
    public static void preventDuplicateLeadCreation(List<Lead> newLeads){

        Set<String> emailSet  = new Set<String>();
        Set<String> phoneSet  = new Set<String>();
        Set<String> mobileSet = new Set<String>();

        for (Lead ld : newLeads) {
            if (String.isNotBlank(ld.Email)) {
                emailSet.add(ld.Email.toLowerCase());
            }
            if (String.isNotBlank(ld.Phone)) {
                phoneSet.add(ld.Phone);
            }
            if (String.isNotBlank(ld.MobilePhone)) {
                mobileSet.add(ld.MobilePhone);
            }
        }

        if (emailSet.isEmpty() && phoneSet.isEmpty() && mobileSet.isEmpty()) {
            return;
        }

        List<Lead> existingLeads = [
            SELECT Id, Email, Phone, MobilePhone 
            FROM Lead 
            WHERE Email IN :emailSet 
            OR Phone IN :phoneSet 
            OR MobilePhone IN :mobileSet
        ];

        for (Lead newLd : newLeads) {
            for (Lead oldLd : existingLeads) {

                Boolean group1Match =
                    (String.isNotBlank(newLd.Email) && newLd.Email.equalsIgnoreCase(oldLd.Email)) ||
                    (String.isNotBlank(newLd.Phone) && newLd.Phone == oldLd.Phone);

                Boolean group2Match =
                    (String.isNotBlank(newLd.Email) && newLd.Email.equalsIgnoreCase(oldLd.Email)) ||
                    (String.isNotBlank(newLd.MobilePhone) && newLd.MobilePhone == oldLd.MobilePhone);

                if (group1Match && group2Match) {
                    newLd.addError('Duplicate Lead found. A lead already exists with matching Email/Phone/Mobile.');
                    break;
                }
            }
        }
    }
    
    
    // =========================
    // CREATE TASK ON LEAD CREATE
    // =========================
    public static void createFollowUpTask(List<Lead> newLeads) {

        List<Task> taskList = new List<Task>();

        for (Lead ld : newLeads) {
            if (ld.Id != null) {

                Task t         = new Task();
                t.Subject      = 'Follow up with Lead';
                t.WhoId        = ld.Id;                   // ✅ Name field → Lead
                t.OwnerId      = ld.OwnerId;              // ✅ Assigned To → Lead Owner
                t.ActivityDate = Date.today().addDays(1);
                t.Description  = 'Follow up with the new lead to confirm interest, understand requirements, and share initial project details. Schedule the next step, such as a call or site visit.';
                t.Status       = 'Not Started';
                t.Priority     = 'Normal';

                taskList.add(t);
            }
        }

        if (!taskList.isEmpty()) {
            insert taskList;
        }
    }
    
    
    // ==========================================
    // CREATE TASK WHEN SITE VISIT STATUS CHANGES
    // ==========================================
    public static void createFollowUpTaskWhenSiteVisit(List<Lead> newLeads, Map<Id, Lead> oldMap){

        List<Task> taskList = new List<Task>();
        Set<Id> leadIds     = new Set<Id>();

        for(Lead newLead : newLeads){
            if(oldMap.containsKey(newLead.Id) &&
               (newLead.Status != oldMap.get(newLead.Id).Status) &&
               (newLead.Status == 'Site Visit Scheduled' || 
                newLead.Status == 'Site Visit Completed')){
                
                leadIds.add(newLead.Id);
            }
        }

        if(leadIds.isEmpty()){
            return;
        }

        Map<Id, Site_Visit__c> leadSiteVisitMap = new Map<Id, Site_Visit__c>();

        List<Site_Visit__c> siteVisitList = [
            SELECT Id, Lead__c, VisitDate__c, Visit_Time__c, Visit_Status__c 
            FROM Site_Visit__c 
            WHERE Lead__c IN :leadIds 
            ORDER BY CreatedDate DESC
        ];

        for(Site_Visit__c siteVisit : siteVisitList){
            if(!leadSiteVisitMap.containsKey(siteVisit.Lead__c)){
                leadSiteVisitMap.put(siteVisit.Lead__c, siteVisit);
            }
        }

        for(Lead newLead : newLeads){

            if(!leadIds.contains(newLead.Id)){
                continue;
            }

            Site_Visit__c latestVisit = leadSiteVisitMap.get(newLead.Id);

            Task t        = new Task();
            t.Subject     = 'Follow up - ' + newLead.Status;
            t.WhoId       = newLead.Id;                                        // ✅ Name field → Lead
            t.WhatId      = (latestVisit != null) ? latestVisit.Id : null;     // ✅ Related To → Site Visit
            t.OwnerId     = newLead.OwnerId;                                   // ✅ Assigned To → Lead Owner
            t.Status      = 'Not Started';
            t.Priority    = 'Normal';
            t.Description = getDescriptionByStatus(newLead.Status);

            if(latestVisit != null && latestVisit.VisitDate__c != null){
                t.ActivityDate = latestVisit.VisitDate__c.addDays(-1);
            } else {
                t.ActivityDate = Date.today();
            }

            taskList.add(t);
        }

        if(!taskList.isEmpty()){
            insert taskList;
        }
    }


    // ======================================
    // HANDLE STATUS CHANGE (TASK + EMAIL)
    // ======================================
    public static void handleStatusChangeTaskAndEmail(List<Lead> newLeads, Map<Id, Lead> oldMap){

        List<Task> taskList                          = new List<Task>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

        Set<Id> changedLeadIds = new Set<Id>();
        for(Lead newLead : newLeads){
            Lead oldLead = oldMap.get(newLead.Id);
            if(oldLead == null) continue;
            if(newLead.Status != oldLead.Status){
                changedLeadIds.add(newLead.Id);
            }
        }

        Map<Id, Site_Visit__c> leadSiteVisitMap = new Map<Id, Site_Visit__c>();
        if(!changedLeadIds.isEmpty()){
            List<Site_Visit__c> siteVisits = [
                SELECT Id, Lead__c, VisitDate__c
                FROM Site_Visit__c
                WHERE Lead__c IN :changedLeadIds
                ORDER BY CreatedDate DESC
            ];
            for(Site_Visit__c sv : siteVisits){
                if(!leadSiteVisitMap.containsKey(sv.Lead__c)){
                    leadSiteVisitMap.put(sv.Lead__c, sv);
                }
            }
        }

        for(Lead newLead : newLeads){

            Lead oldLead = oldMap.get(newLead.Id);
            if(oldLead == null) continue;

            if(newLead.Status != oldLead.Status){

                Site_Visit__c latestVisit = leadSiteVisitMap.get(newLead.Id);

                // -------- TASK CREATION --------
                Task t         = new Task();
                t.Subject      = getSubjectByStatus(newLead.Status);
                t.Description  = getDescriptionByStatus(newLead.Status);
                t.WhoId        = newLead.Id;                                     // ✅ Name field → Lead
                t.WhatId       = (latestVisit != null) ? latestVisit.Id : null;  // ✅ Related To → Site Visit
                t.OwnerId      = newLead.OwnerId;                                 // ✅ Assigned To → Lead Owner
                t.Status       = 'Not Started';
                t.Priority     = 'High';
                t.ActivityDate = System.today().addDays(5);

                taskList.add(t);

                // -------- EMAIL LOGIC --------
                if((newLead.Status == 'Site Visit Scheduled' ||
                    newLead.Status == 'Site Visit Completed') &&
                    String.isNotBlank(newLead.Email)){

                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[]{ newLead.Email });
                    mail.setSubject(getEmailSubject(newLead.Status));
                    mail.setPlainTextBody(getEmailBody(newLead));
                    mail.setSaveAsActivity(true);  // ✅ Auto-create EmailMessage activity

                    emailList.add(mail);
                }
            }
        }

        if(!taskList.isEmpty()){
            insert taskList;
        }
        if(!emailList.isEmpty()){
            Messaging.sendEmail(emailList);
        }
    }


    // =========================
    // SUBJECT MAPPING
    // =========================
    private static String getSubjectByStatus(String status){
        switch on status {
            when 'New'                  { return 'Initial Outreach to New Lead'; }
            when 'Contacted'            { return 'Follow-up Discussion with Prospect'; }
            when 'Site Visit Scheduled' { return 'Prepare Documentation for Scheduled Site Visit'; }
            when 'Site Visit Completed' { return 'Post Site Visit Feedback & Qualification'; }
            when 'Feedback Received'    { return 'Analyze Feedback and Discuss Next Steps'; }
            when 'Unqualified'          { return 'Closure and Lead Disqualification Review'; }
            when 'Converted'            { return 'Client Handoff and Onboarding Coordination'; }
            when else                   { return 'Lead Status Follow-up'; }
        }
    }


    // =========================
    // DESCRIPTION MAPPING
    // =========================
    private static String getDescriptionByStatus(String status){
        switch on status {
            when 'New' {
                return 'Initiate first contact with the lead to understand requirements, introduce available offerings, and qualify interest level.';
            }
            when 'Contacted' {
                return 'Conduct a detailed discussion with the prospect to understand budget, preferences, and timeline. Identify potential property matches.';
            }
            when 'Site Visit Scheduled' {
                return 'Ensure site visit arrangements are confirmed. Coordinate with the sales team, prepare necessary documents, and confirm client availability.';
            }
            when 'Site Visit Completed' {
                return 'Collect feedback from the prospect regarding the property visit. Identify objections, clarify queries, and evaluate conversion potential.';
            }
            when 'Feedback Received' {
                return 'Analyze client feedback and propose suitable next steps such as pricing discussion, negotiation, or alternative property options.';
            }
            when 'Unqualified' {
                return 'Review disqualification reason, document insights, and ensure proper closure in CRM for reporting and future reference.';
            }
            when 'Converted' {
                return 'Coordinate with internal teams for successful onboarding, documentation processing, and transaction completion.';
            }
            when else {
                return 'Follow up on lead status progression and ensure timely action is taken.';
            }
        }
    }


    // =========================
    // EMAIL SUBJECT
    // =========================
    private static String getEmailSubject(String status){
        if(status == 'Site Visit Scheduled'){
            return 'Confirmation of Your Scheduled Site Visit';
        } else {
            return 'Thank You for Visiting – Next Steps';
        }
    }


    // =========================
    // EMAIL BODY
    // =========================
    private static String getEmailBody(Lead l){

        String greeting = (l.FirstName != null) ? 
                          'Dear ' + l.FirstName : 
                          'Dear Valued Customer';

        return greeting + ',\n\n'
            + 'Thank you for your continued interest in our property offerings.\n\n'
            + 'We truly appreciate the opportunity to assist you in your property search. '
            + 'Our team remains committed to providing you with complete support throughout the process.\n\n'
            + 'Should you have any questions or require further clarification, please feel free to reach out to us at any time.\n\n'
            + 'Warm regards,\n'
            + 'Sales Team\n'
            + 'Real Estate Division';
    }

    public static void assignRandomValues(List<Lead> records){
        // 🔹 City Options
        List<String> cities = new List<String>{
            'Delhi','Ghaziabad','Noida','Gurugram',
            'Mumbai','Chennai','Hyderabad','Hebbal'
        };

        // 🔹 Budget Options
        List<Decimal> budgets = new List<Decimal>{
            10000000,15000000,20000000,25000000
        };

        // 🔹 Buying Timeline
        List<String> timelines = new List<String>{
            'Immediate (0–1 Month)',
            '1–3 Months',
            '3–6 Months',
            '6–12 Months'
        };

        // 🔹 Whatsapp Count
        List<Integer> whatsappCounts = new List<Integer>{
            2,4,5,9,3
        };

        // 🔹 Rating
        List<String> ratings = new List<String>{
            'Hot','Warm','Cold'
        };

        for(Lead rec : records){

            // Generate random index safely
            rec.City = String.isBlank(rec.City) ? cities[getRandomIndex(cities.size())] : rec.City ;
            rec.Budget__c = rec.Budget__c == 0 || rec.Budget__c == null ? budgets[getRandomIndex(budgets.size())] : rec.Budget__c ;
            rec.Buying_Timeline__c = String.isBlank(rec.Buying_Timeline__c) ? timelines[getRandomIndex(timelines.size())] : rec.Buying_Timeline__c;
            rec.Whatsapp_Count__c = rec.Whatsapp_Count__c == 0 || rec.Whatsapp_Count__c == null ? whatsappCounts[getRandomIndex(whatsappCounts.size())] : rec.Whatsapp_Count__c;
            rec.Rating = String.isBlank(rec.Rating) ? ratings[getRandomIndex(ratings.size())] : rec.Rating;
        }
    }

    private static Integer getRandomIndex(Integer size){
        return Math.mod(Math.abs(Crypto.getRandomInteger()), size);
    }
}