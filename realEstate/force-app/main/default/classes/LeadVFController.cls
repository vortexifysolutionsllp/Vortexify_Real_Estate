public class LeadVFController {

    public Lead leadRec { get; set; }
    public String enteredEmail { get; set; }

    // UI flags
    public Boolean showEmailOnly { get; set; }
    public Boolean showBasicFields { get; set; }      // existing users
    public Boolean showProjectFields { get; set; }    // new users

    public LeadVFController() {
        leadRec = new Lead();
        showEmailOnly = true;
        showBasicFields = false;
        showProjectFields = false;
    }

    // STEP 1: Email check
    public void checkEmail() {

    List<Lead> leads = [
        SELECT Id, Email, FirstName, LastName, Phone, City,
               Fax, AnnualRevenue, Project_Interest__c
        FROM Lead
        WHERE Email = :enteredEmail
        LIMIT 1
    ];

    // Reset flags
    showEmailOnly = false;
    showBasicFields = false;
    showProjectFields = false;

    if (!leads.isEmpty()) {
        //  EMAIL EXISTS → show Fax & Annual Revenue
        leadRec = leads[0];
        showProjectFields = true;

    } else {
        //  EMAIL DOES NOT EXIST → show basic fields
        leadRec = new Lead();
        leadRec.Email = enteredEmail;
        showBasicFields = true;
    }
}


    // STEP 2: Save
    public void saveLead() {

        // Required standard field
        leadRec.Company = 'Web Lead';

        Boolean isNewLead = (leadRec.Id == null);

        if (isNewLead) {
            insert leadRec;
        } else {
            update leadRec;
        }

        // Existing functionality: Project Interest child records
        if (!String.isBlank(leadRec.Project_Interest__c)) {

            List<Project_Interest__c> listPI = new List<Project_Interest__c>();

            for (String p : leadRec.Project_Interest__c.split(';')) {
                listPI.add(new Project_Interest__c(
                    Lead__c = leadRec.Id,
                    Project_Name__c = p
                ));
            }
            insert listPI;
        }

        ApexPages.addMessage(
            new ApexPages.Message(
                ApexPages.Severity.CONFIRM,
                'Thank you! Your details have been saved.'
            )
        );
    }
}