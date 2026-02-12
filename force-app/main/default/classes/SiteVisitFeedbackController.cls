
//keshav code
public without sharing class SiteVisitFeedbackController {
 
    // Form fields
    public String rating { get; set; }
    public String comments { get; set; }
 
    // URL parameter
    public Id siteVisitId { get; set; }
 
    // UI state flags
    public Boolean isValidLink { get; set; }
    public Boolean isSubmitted { get; set; }
    public Boolean isAlreadyReceived { get; set; }
 
    // Constructor (runs on page load)
    public SiteVisitFeedbackController() {
 
        siteVisitId = ApexPages.currentPage().getParameters().get('id');
 
        isValidLink = (siteVisitId != null);
        isSubmitted = false;
        isAlreadyReceived = false;
 
        // Decide UI BEFORE page renders
        if (siteVisitId != null) {
            Site_Visit__c sv = [
                SELECT Feedback_Received__c
                FROM Site_Visit__c
                WHERE Id = :siteVisitId
                LIMIT 1
            ];
 
            if (sv.Feedback_Received__c == true) {
                isAlreadyReceived = true;
            }
        }
    }
 
    // Submit feedback
    public PageReference submitFeedback() {
 
        try {
 
            if (siteVisitId == null) {
                return null;
            }
 
            Site_Visit__c svCheck = [
                SELECT Feedback_Received__c
                FROM Site_Visit__c
                WHERE Id = :siteVisitId
                LIMIT 1
            ];
 
            // Extra protection
            if (svCheck.Feedback_Received__c) {
                isAlreadyReceived = true;
                return null;
            }
 
            Feedback__c fb = new Feedback__c();
            fb.Site_Visit__c   = siteVisitId;
            fb.Rating__c       = rating;
            fb.Comments__c     = comments;
            fb.Submitted_On__c = System.today();
            insert fb;
 
            svCheck.Feedback_Received__c = true;
            update svCheck;
 
            isSubmitted = true;
 
        } catch (Exception e) {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.ERROR,
                    'We were unable to submit your feedback. Please try again later.'
                )
            );
        }
 
        return null;
    }
}