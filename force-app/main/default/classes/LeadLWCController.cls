public with sharing class LeadLWCController {

    // Check email and return lead if exists
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

    @AuraEnabled
    public static Id saveLead(Lead leadRec, String locationValue, List<String> selectedProjectNames) {

        Boolean isNewLead = (leadRec.Id == null);
        leadRec.Company = 'Web Lead';

        if (isNewLead) {
            insert leadRec;
        } else {
            update leadRec;
        }

        // create project interest
        if (selectedProjectNames != null) {

           // Step 1: Fetch existing project interests
List<Project_Interest__c> existingProjectInterest =
    [SELECT Id, Project__c, Is_Active__c
     FROM Project_Interest__c
     WHERE Lead__c = :leadRec.Id];

Map<Id, Project_Interest__c> projectInterestMap = new Map<Id, Project_Interest__c>();

for(Project_Interest__c pi : existingProjectInterest){
    if(pi.Project__c != null){
        projectInterestMap.put(pi.Project__c, pi);
    }
}

// Step 2: Convert selected ids
Set<Id> selectedProjectIds = new Set<Id>();
for(String pid : selectedProjectNames){
    selectedProjectIds.add((Id)pid);
}

// Step 3: Deactivate removed projects
List<Project_Interest__c> toDeactivate = new List<Project_Interest__c>();

for(Project_Interest__c pi : existingProjectInterest){
    if(!selectedProjectIds.contains(pi.Project__c)){
        pi.Is_Active__c = false;
        toDeactivate.add(pi);
    }
}

if(!toDeactivate.isEmpty()){
    update toDeactivate;
}

// Step 4: Reactivate OR Insert selected projects
List<Project_Interest__c> toInsert = new List<Project_Interest__c>();
List<Project_Interest__c> toReactivate = new List<Project_Interest__c>();

// Get project names
List<Project__c> selectedProjects =
    [SELECT Id, Name FROM Project__c WHERE Id IN :selectedProjectIds];

Map<Id, String> projectNameById = new Map<Id, String>();
for(Project__c prj : selectedProjects){
    projectNameById.put(prj.Id, prj.Name);
}

// Lead full name
String leadFullName =
    (leadRec.FirstName != null ? leadRec.FirstName : '') +
    ' ' +
    (leadRec.LastName != null ? leadRec.LastName : '');

for(Id projId : selectedProjectIds){

    // Case 1: Already exists → Reactivate
    if(projectInterestMap.containsKey(projId)){

        Project_Interest__c existingPI = projectInterestMap.get(projId);

        if(existingPI.Is_Active__c == false){
            existingPI.Is_Active__c = true;
            toReactivate.add(existingPI);
        }

    }
    // Case 2: Doesn't exist → Insert new
    else{

        String projectName = projectNameById.get(projId);

        toInsert.add(new Project_Interest__c(
            Name = leadFullName + ' - ' + projectName,
            Lead__c = leadRec.Id,
            Project__c = projId,
            Location__c = locationValue,
            Is_Active__c = true
        ));
    }
}

// Perform updates/inserts
if(!toReactivate.isEmpty()){
    update toReactivate;
}

if(!toInsert.isEmpty()){
    insert toInsert;
}

        }

        return leadRec.Id;
    }


    // Get picklist values for Location__c on Project_Interest__c
    // @AuraEnabled
    // public static List<String> getLocationValues() {

    //     List<String> results = new List<String>();

    //     Schema.DescribeFieldResult d =
    //         Project__c.Locations__c.getDescribe();

    //     for (Schema.PicklistEntry pe : d.getPicklistValues()) {
    //         results.add(pe.getValue());   // use value for LWC combobox
    //     }

    //     return results;
    // }


        @AuraEnabled
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
            //Where LOWER(Locations__c) = :location.toLowerCase()
            WHERE Locations__c = :location
            ORDER BY Name
        ];
    }

    @AuraEnabled
    public static Lead getLeadById111(Id recordId) {
        return [ SELECT Id, FirstName, LastName, Phone, Email FROM Lead WHERE Id = :recordId LIMIT 1];
    }

    @AuraEnabled(cacheable=false)
    public static List<Id> getSelectedProjectInterests(Id leadId){
        List<Project_Interest__c> projectInterestList = [SELECT Project__c FROM Project_Interest__c WHERE Lead__c = :leadId AND Is_Active__c = true ];
        List<Id> projectIds = new List<Id>();
        for(Project_Interest__c pr: projectInterestList){
            if(pr.Project__c != null){
                projectIds.add(pr.Project__c);
            }
        }
        return projectIds;
    }

    @AuraEnabled
    public static Id saveLeadRecord(Lead leadRec, String locationValue, List<String> selectedProjectNames) {
    
        Boolean isNewLead = (leadRec.Id == null);
        leadRec.Company = 'Web Lead';
    
        try {
        if (isNewLead) {
            insert leadRec;
        } else {
            update leadRec;
        }
    } catch (DmlException e) {
        System.debug('Error while saving Lead: ' + e.getMessage());

        throw new AuraHandledException(
            'Lead could not be saved because email daily limit was reached.'
        );
    }
    
        // create project interest
        if (selectedProjectNames != null && !selectedProjectNames.isEmpty()) {

    
            String leadFirstName = leadRec.FirstName!=null ? leadRec.FirstName : 'Unknown';
            String leadLastName = leadRec.LastName!=null ? leadRec.LastName : 'Unknown';
            String leadFullName = leadFirstName + ' ' + leadLastName;
    
            List<Project_Interest__c> listPI = new List<Project_Interest__c>();
            List<Project__c> selectedProjectList = [SELECT Id, Name FROM Project__c WHERE Id IN: selectedProjectNames];
            Map<Id,String> projectNameById = new Map<Id,String>();
            for(Project__c prjRec : selectedProjectList){
                projectNameById.put(prjRec.Id, prjRec.Name);
            }
    
            for (Id projId : selectedProjectNames) {
                listPI.add(new Project_Interest__c(
                Name = leadFullName + ' - ' + projectNameById.get(projId),
                Lead__c = leadRec.Id,
                Project__c = projId,
                Is_Active__c = true
                ));
            }
    
            insert listPI;
        }
    
        return leadRec.Id;
    }

}