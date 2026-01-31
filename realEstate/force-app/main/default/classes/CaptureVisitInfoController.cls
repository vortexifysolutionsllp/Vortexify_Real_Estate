public with sharing class CaptureVisitInfoController {

    private static final String COMPLETED_STATUS = 'Completed';

    /* ================= FETCH LEAD DATA ================= */
    @AuraEnabled(cacheable=true)
    public static Lead getLeadData(Id siteVisitId) {

        Site_Visit__c sv = [
            SELECT Lead__c
            FROM Site_Visit__c
            WHERE Id = :siteVisitId
            LIMIT 1
        ];

        return [
            SELECT Id,
                   Budget__c,
                   Buying_Timeline__c,
                   Description,
                   Email,
                   Name
            FROM Lead
            WHERE Id = :sv.Lead__c
            LIMIT 1
        ];
    }

    /* ================= FETCH ALL PROJECTS ================= */
    @AuraEnabled(cacheable=true)
    public static List<Project__c> getAllProjects() {
        return [
            SELECT Id, Name
            FROM Project__c
            ORDER BY Name
        ];
    }

    /* ================= FETCH LEAD PROJECT INTERESTS ================= */
    @AuraEnabled(cacheable=true)
    public static List<Id> getLeadProjectInterests(Id siteVisitId) {

        Site_Visit__c sv = [
            SELECT Lead__c
            FROM Site_Visit__c
            WHERE Id = :siteVisitId
            LIMIT 1
        ];

        List<Project_Interest__c> interests = [
            SELECT Project__c
            FROM Project_Interest__c
            WHERE Lead__c = :sv.Lead__c
        ];

        List<Id> projectIds = new List<Id>();
        for (Project_Interest__c pi : interests) {
            if (pi.Project__c != null) {
                projectIds.add(pi.Project__c);
            }
        }
        return projectIds;
    }

    /* ================= SAVE & SYNC ================= */
    @AuraEnabled
    public static void saveVisitInformation(
        Id siteVisitId,
        Lead leadData,
        List<Id> selectedProjectIds
    ) {

        /* ---------- Fetch Site Visit ---------- */
        Site_Visit__c sv = [
            SELECT Id,
                   Lead__c,
                   Visit_Status__c,
                   CustomerName__c
            FROM Site_Visit__c
            WHERE Id = :siteVisitId
            LIMIT 1
        ];

        /* ---------- Hard validation ---------- */
        if (sv.Visit_Status__c == COMPLETED_STATUS) {
            throw new AuraHandledException(
                'Site visit already completed. Updates are not allowed.'
            );
        }

        /* ---------- Update Lead fields (NO status change) ---------- */
        leadData.Id = sv.Lead__c;
        update leadData;

        /* ---------- Update Site Visit Status ---------- */
        sv.Visit_Status__c = COMPLETED_STATUS;
        update sv;

        /* ---------- Fetch Lead for Email ---------- */
        Lead leadForEmail = [
            SELECT Email, Name
            FROM Lead
            WHERE Id = :sv.Lead__c
            LIMIT 1
        ];

        /* ---------- Send Feedback Email ---------- */
        sendFeedbackEmail(leadForEmail, sv);

        /* ---------- Sync Child Project_Interest__c ---------- */
        List<Project_Interest__c> existing = [
            SELECT Id, Project__c, Site_Visit__c
            FROM Project_Interest__c
            WHERE Lead__c = :sv.Lead__c
        ];

        Map<Id, Project_Interest__c> existingMap = new Map<Id, Project_Interest__c>();
        for (Project_Interest__c pi : existing) {
            existingMap.put(pi.Project__c, pi);
        }

        Map<Id, String> projectIdToName = new Map<Id, String>();
        for (Project__c p : [
            SELECT Id, Name
            FROM Project__c
            WHERE Id IN :selectedProjectIds
        ]) {
            projectIdToName.put(p.Id, p.Name);
        }

        List<Project_Interest__c> toUpsert = new List<Project_Interest__c>();
        for (Id projectId : selectedProjectIds) {
            if (!existingMap.containsKey(projectId)) {
                toUpsert.add(new Project_Interest__c(
                    Lead__c = sv.Lead__c,
                    Project__c = projectId,
                    Name = projectIdToName.get(projectId),
                    Site_Visit__c = sv.Id
                ));
            } else {
                Project_Interest__c pi = existingMap.get(projectId);
                pi.Site_Visit__c = sv.Id;
                toUpsert.add(pi);
            }
        }

        List<Project_Interest__c> toDelete = new List<Project_Interest__c>();
        for (Project_Interest__c pi : existing) {
            if (!selectedProjectIds.contains(pi.Project__c)) {
                toDelete.add(pi);
            }
        }

        if (!toUpsert.isEmpty()) upsert toUpsert;
        if (!toDelete.isEmpty()) delete toDelete;
    }

    /* ================= SEND FEEDBACK EMAIL ================= */
    private static void sendFeedbackEmail(Lead l, Site_Visit__c sv) {

        if (String.isBlank(l.Email)) return;

        String feedbackUrl =
            'https://vortexifysolutionsllp--estatedev.sandbox.my.salesforce-sites.com' +
            '/apex/SiteVisitFeedback?id=' + sv.Id;

        String emailBody =
            '<p>Hello ' + sv.CustomerName__c + ',</p>' +
            '<p>Thank you for taking the time to visit Project.</p>' +
            '<p>We hope your site visit experience was helpful and informative.</p>' +
            '<p>Your feedback is very important to us and helps us improve our service.</p>' +
            '<p><br></p>' +
            '<p>Please <a href="' + feedbackUrl +
            '" rel="noopener noreferrer" target="_blank">click here</a> to submit your feedback.</p>' +
            '<p><br></p>' +
            '<p>Thank you for your time and valuable input.</p>' +
            '<p><br></p>' +
            '<p>Warm regards,</p>' +
            '<p>Vortexify</p>';

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ l.Email });
        mail.setSubject('We’d love your feedback on your site visit');
        mail.setHtmlBody(emailBody);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }
}