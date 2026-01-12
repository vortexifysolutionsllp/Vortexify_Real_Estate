public without sharing class SiteVisitFeedbackController {

    // Form fields
    public String rating { get; set; }
    public String comments { get; set; }

    // URL parameter
    public Id siteVisitId { get; set; }

    // UI control flags
    public Boolean isValidLink { get; set; }
    public Boolean isSubmitted { get; set; } // NEW (UI only)

    // Constructor
    public SiteVisitFeedbackController() {
        siteVisitId = ApexPages.currentPage()
            .getParameters()
            .get('id');

        isValidLink = (siteVisitId != null);
        isSubmitted = false;
    }

    // Submit feedback
    public PageReference submitFeedback() {

        try {
            // Validate link
            if (siteVisitId == null) {
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.ERROR,
                        'This feedback link is invalid or expired.'
                    )
                );
                return null;
            }

            // Prevent duplicate submissions
            Site_Visit__c svCheck = [
                SELECT Feedback_Received__c
                FROM Site_Visit__c
                WHERE Id = :siteVisitId
                LIMIT 1
            ];

            if (svCheck.Feedback_Received__c) {
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.ERROR,
                        'Feedback has already been submitted for this visit.'
                    )
                );
                return null;
            }

            // Create Feedback record
            Feedback__c fb = new Feedback__c();
            fb.Site_Visit__c = siteVisitId;
            fb.Rating__c = rating;
            fb.Comments__c = comments;
            fb.Submitted_On__c = system.today();   
            insert fb;

            // Update Site Visit
            svCheck.Feedback_Received__c = true;
            update svCheck;

            // Mark UI as submitted (NO MORE EDITING)
            isSubmitted = true;

            // Success message
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.CONFIRM,
                    'Thank you! Your feedback has been submitted successfully.'
                )
            );

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