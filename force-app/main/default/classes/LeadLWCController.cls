public with sharing class LeadLWCController {

    // STEP 1 — Check email and return lead if exists
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> checkEmail(String email) {

        Map<String, Object> response = new Map<String, Object>();

        List<Lead> leads = [SELECT Id, FirstName, LastName, Phone, Email, OwnerId FROM Lead WHERE Email = :email LIMIT 1];

        if (!leads.isEmpty()) {

            Lead existingLead = leads[0];

            // Create follow-up task for re-enquiry
            Task t = new Task();
            t.Subject = 'Follow up Lead Re-enquired';
            t.WhoId = existingLead.Id;
            t.OwnerId = existingLead.OwnerId;
            t.ActivityDate = Date.today()+1;
            t.Status = 'Not Started';
            t.Priority = 'High';
            t.Description ='Lead has re-enquired. Please connect with the customer today to understand updated requirements and take next action. Same-day follow-up required.';

            insert t;

            response.put('exists', true);
            response.put('leadRec', existingLead);

        } else {

            Lead l = new Lead();
            l.Email = email;

            response.put('exists', false);
            response.put('leadRec', l);
        }

        return response;
    }


    // STEP 2 — Save lead (insert or update) + create Project_Interest__c child records
  /*  @AuraEnabled
    public static Id saveLead(Lead leadRec, String locationValue, String selectedProjectNames) {

        Boolean isNewLead = (leadRec.Id == null);

        // Required standard field
        leadRec.Company = 'Web Lead';

        // Save lead
        if (isNewLead) {
            insert leadRec;
        } else {
            update leadRec;
        }

        // Create child records from multiselect picklist
        if (!String.isBlank(leadRec.Project_Interest__c)) {

            List<Project_Interest__c> listPI = new List<Project_Interest__c>();

            // Split multi-select values like A;B;C
            for (String p : leadRec.Project_Interest__c.split(';')) {

                if (String.isBlank(p)) continue;

                listPI.add(new Project_Interest__c(
                    Lead__c = leadRec.Id,
                    Projects__c = p,
                    		Projects_Name__c=selectedProjectNames
                   // Location__c = locationValue   // <-- NEW: save Location
                ));
            }

            if (!listPI.isEmpty()) {
                insert listPI;
            }
        }

        return leadRec.Id;
    }*/

    @AuraEnabled
public static Id saveLead(Lead leadRec, String locationValue, List<String> selectedProjectNames) {

    Boolean isNewLead = (leadRec.Id == null);
    leadRec.Company = 'Web Lead';

    if (isNewLead) {
        insert leadRec;
    } else {
        update leadRec;
    }

    // create project interest children
    if (selectedProjectNames != null && !selectedProjectNames.isEmpty()) {
         // 🔥 create combined text for Projects_Name__c field
       // String combinedNames = String.join(selectedProjectNames, '; ');

        String leadFirstName = leadRec.FirstName!=null ? leadRec.FirstName : '';
        String leadLastName = leadRec.LastName!=null ? leadRec.LastName : '';
        String leadFullName = leadFirstName + leadLastName;

        List<Project_Interest__c> listPI = new List<Project_Interest__c>();

        for (String projName : selectedProjectNames) {

            listPI.add(new Project_Interest__c(
                Name = leadFullName + ' / ' + projName,
                Lead__c = leadRec.Id,
                Projects_Name__c = projName,
                Location__c = locationValue
            ));
        }

        insert listPI;
    }

    return leadRec.Id;
}


    // STEP 3 — Get picklist values for Location__c on Project_Interest__c
    @AuraEnabled(cacheable=true)
    public static List<String> getLocationValues() {

        List<String> results = new List<String>();

        Schema.DescribeFieldResult d =
            Project__c.Locations__c.getDescribe();

        for (Schema.PicklistEntry pe : d.getPicklistValues()) {
            results.add(pe.getValue());   // use value for LWC combobox
        }

        return results;
    }

	 @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjectsByLocation(String location) {
        if(String.isBlank(location)) return new List<Project__c>();
        return [
            SELECT Id, Name
            FROM Project__c
            WHERE Locations__c = :location
            ORDER BY Name
        ];
    }
}