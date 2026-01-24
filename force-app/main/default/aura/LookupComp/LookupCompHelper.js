({
    searchRecordsHelper : function(component, event, helper, value) {
        debugger;
        var contactId = component.get("v.contactId");
        $A.util.removeClass(component.find("Spinner"), "slds-hide");
        var searchString = component.get('v.searchString');
        component.set('v.message', '');
        component.set('v.recordsList', []);
        debugger;
     
        var action = component.get('c.fetchUserDataforConga');
        action.setParams({
            'objectName' : component.get('v.objectName'),
            'filterField' : component.get('v.fieldName'),
            'searchString' : searchString,
            'value' : value,
            'contactType': contactId
        });
        debugger;
        action.setCallback(this,function(response){
            var result = response.getReturnValue();
            if(response.getState() === 'SUCCESS') {
                if(result.length > 0) {
                    debugger;
                    if( $A.util.isEmpty(value) ) {
                        component.set('v.recordsList',result);   
                        //component.set('v.ProjectId',"");
                        debugger;
                    } else {
                        component.set('v.selectedRecord', result[0]);
                    }
                    debugger;
                } else {
                    component.set('v.message', "No Records Found for '" + searchString + "'");
                }
                debugger;
            } else {
                
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    component.set('v.message', errors[0].message);
                }
            }
            
            if( $A.util.isEmpty(value) )
                $A.util.addClass(component.find('resultsDiv'),'slds-is-open');
            $A.util.addClass(component.find("Spinner"), "slds-hide");
        });
        $A.enqueueAction(action);
    }
})