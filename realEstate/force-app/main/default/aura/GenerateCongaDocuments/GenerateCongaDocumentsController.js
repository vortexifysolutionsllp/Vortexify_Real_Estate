({
    doInit : function(component, event, helper) {
        debugger;
        var conRecList = component.get("v.CongaCompWrapperList");
        var userRecList = component.get("v.CongaCompWrapperListForUser");
        
        var action = component.get("c.fetchAllContactsFromContract");
        
        action.setParams({
            "contactId":component.get("v.recordId"),
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //component.set("v.spinner",false);
                var storeResponse = response.getReturnValue();
                for (let i = 0; i < storeResponse.length; i++) {
                    if(storeResponse[i].standardUser == true){
                        userRecList.push({
                            'conId': storeResponse[i].conId,
                            'conName': storeResponse[i].conName,
                            'type': storeResponse[i].type,
                            'sequence': storeResponse[i].sequence,
                            'standardUser': true,
                            'isChecked':false
                        });    
                    }else{
                        conRecList.push({
                            'conId': storeResponse[i].conId,
                            'conName': storeResponse[i].conName,
                            'type': storeResponse[i].type,
                            'sequence': storeResponse[i].sequence,
                            'isChecked':false
                        }); 
                    }
                }
                component.set("v.CongaCompWrapperList", conRecList);
                component.set("v.CongaCompWrapperListForUser", userRecList);
            }
            //component.set("v.spinner", false);
        });
        $A.enqueueAction(action);  
    },
    
    openModel: function(component, event, helper) {
        // Set isModalOpen attribute to true
        component.set("v.isModalOpen", true);
    },
    
    onCheck: function(component, event) {
        debugger;
        var accListLength = component.get("v.CongaCompWrapperListForUser");
        var selectedRec = event.target.id;
        var allRecords = component.get("v.CongaCompWrapperList");
        var listLength = accListLength.length;
        
        
        
        for (let i = 0; i < allRecords.length; i++) {
            if(allRecords[i].conId == selectedRec){
                if( allRecords[i].isChecked == false){
                    allRecords[i].isChecked = true;
                }else{
                    allRecords[i].isChecked = false;
                }
            } 
        }
        //Sorting the List 
        allRecords.sort(function(a, b) {
            // Sort elements with active=true to the top
            if (a.isChecked && !b.isChecked) {
                return -1; // a comes before b
            } else if (!a.isChecked && b.isChecked) {
                return 1; // a comes after b
            }
            return 0; // Preserve original order
        });
        
        for (let i = 0; i < allRecords.length; i++) {
            listLength++;
            allRecords[i].sequence = listLength;
        }
        component.set("v.CongaCompWrapperList",allRecords);
        
    },
    
    handleChange: function(component, event, helper) {
        debugger;
        var selValue = component.get("v.value");
        if(selValue == 'option2'){
            component.set("v.showDetails", true);
        }
        if(selValue == 'option1'){
            component.set("v.showDetails", false);
        }
        
    },
    
    closeModel: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.isModalOpen", false);
    },
    
    submitDetails: function(component, event, helper) {
        component.set("v.isModalOpen", false);
    },
    
    handleAddRow : function(component, event, helper){
        debugger;
        
        //Incrementing USer Sequence :
        var jiraTaskRecList = component.get("v.CongaCompWrapperListForUser");
        if(jiraTaskRecList.length > 2){
            alert('Maximum 3 records can be selected.');
        }else{
            var i = jiraTaskRecList.length;
            jiraTaskRecList.push({
                'conId': '',
                'type': 'SIGNER',
                'sequence': i+1
            });
            component.set("v.CongaCompWrapperListForUser", jiraTaskRecList);
            var currentlength = i+1;
            //Incrementinf Contact sequence :
            
            var jiraTaskRecListConts = component.get("v.CongaCompWrapperList");
            for (let i = 0; i < jiraTaskRecListConts.length; i++) {
                currentlength++;
                jiraTaskRecListConts[i].sequence = currentlength;
            } 
            
            component.set("v.CongaCompWrapperList", jiraTaskRecListConts);    
        }
    },
    
    removeRecord : function(component, event, helper){
        debugger;
        var userRecList = component.get("v.CongaCompWrapperListForUser");
        var contactRecList = component.get("v.CongaCompWrapperList");
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        var selSeq = userRecList[index].sequence;
        userRecList.splice(index, 1);
        
        if(index == 0){
            for (let i = 0; i < userRecList.length; i++) {
                userRecList[i].sequence = 1;
                selSeq++;
            } 
            for (let i = 0; i < contactRecList.length; i++) {
                contactRecList[i].sequence = selSeq;
                selSeq++;
            }
        }else{
            for (let i = 0; i < contactRecList.length; i++) {
                contactRecList[i].sequence = selSeq;
                selSeq++;
            }
        }
        component.set("v.CongaCompWrapperListForUser", userRecList);
        component.set("v.CongaCompWrapperList", contactRecList);
    },
    
    saveRecord : function(component, event, helper){
        debugger;
        component.set("v.spinner",true);
        
        var userRecords = component.get("v.CongaCompWrapperListForUser");
        var contactRecords = component.get("v.CongaCompWrapperList");
        
        var selectedRecords = [];
        var selectedConRecords = [];
        for (var i = 0; i < userRecords.length; i++) {
            selectedRecords.push(userRecords[i]);
        }
        
        for (var i = 0; i < contactRecords.length; i++) {
            if (contactRecords[i].isChecked) {
                selectedRecords.push(contactRecords[i]);
                selectedConRecords.push(contactRecords[i]);
            }
        }
        //var wrapperList = component.get("v.CongaCompWrapperList");
        var selValue = component.get("v.value");
        if(selValue == 'option2'){
            var action= component.get("c.GenerateDocumentAndSendForSignature"); 
            action.setParams({
                "recordId":component.get("v.recordId"),
                "messageBody":component.get("v.myVal"),
                "subject":component.get("v.subjectVal"),
                "CongaCompWrapperUserList":userRecords,
                "CongaCompWrapperConList":selectedConRecords,
                "CongaCompWrapperList": selectedRecords
            });
        }
        if(selValue == 'option1'){
            var action= component.get("c.GenerateDocument"); 
            action.setParams({
                "recordId":component.get("v.recordId")
            }); 
        }
        
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            var storeResponse = response.getReturnValue();
            
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The Documents are being generated."
                });
                toastEvent.fire();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                component.set("v.spinner",false);
            }
            component.set("v.spinner", false);
        });
        $A.enqueueAction(action);  
    },
    handleSectionToggle: function (cmp, event) {
        var openSections = event.getParam('openSections');
        
        if (openSections.length === 0) {
            cmp.set('v.activeSectionsMessage', "All sections are closed");
        } else {
            cmp.set('v.activeSectionsMessage', "Open sections: " + openSections.join(', '));
        }
    },
    closeModel: function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },
    
})