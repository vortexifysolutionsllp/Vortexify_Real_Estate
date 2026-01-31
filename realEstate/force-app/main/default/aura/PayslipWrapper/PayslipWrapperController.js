({
    doInit: function(component, event, helper) {
        var currentUrl = window.location.origin;
        var recordId = component.get("v.recordId");
        if (recordId) {
            var vfPageUrl = currentUrl + "/apex/Payslip?id=" + recordId;
            component.set("v.vfPageUrl", vfPageUrl);
        }
    },

    sendEmail: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        
        // First, save the PDF file
        var saveAction = component.get("c.generateAndSavePDF");
        saveAction.setParams({ recordId: recordId });
        saveAction.setCallback(this, function(saveResponse) {
            var saveState = saveResponse.getState();
            if (saveState === "SUCCESS") {
                // After saving, send the email
                var emailAction = component.get("c.sendPdfEmail");
                emailAction.setParams({ recordId: recordId });
                emailAction.setCallback(this, function(emailResponse) {
                    var emailState = emailResponse.getState();
                    if (emailState === "SUCCESS") {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "message": "The payslip has been saved and sent successfully."
                        });
                        toastEvent.fire();
                        $A.get("e.force:closeQuickAction").fire();
                    } else {
                        var errors = emailResponse.getError();
                        if (errors) {
                            console.log("Error sending email: " + errors[0].message);
                        }
                    }
                });
                $A.enqueueAction(emailAction);
            } else {
                var errors = saveResponse.getError();
                if (errors) {
                    console.log("Error saving PDF: " + errors[0].message);
                }
            }
        });
        $A.enqueueAction(saveAction);
    },
    
    cancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})