({
    getDates : function(component,event,helper) {
        
        var action= component.get("c.getDates"); 
        debugger;   
        
        action.setParams({
            "manId":component.get("v.mandateRecId"),
        });
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            var storeResponse = response.getReturnValue();
            
            if (state === "SUCCESS") {
                component.set("v.spinner",false);
                component.set("v.wrapperData.nextfollowupdate",storeResponse[0]);
                component.set("v.wrapperData.hcsStartDate",storeResponse[1]);
                component.set("v.wrapperData.hcsEndDate",storeResponse[0]);
            }
            component.set("v.spinner", false);
        });
        
        
        $A.enqueueAction(action);
        
    },
    
    generateReport : function(component,event,helper){
        var abc = component.get("v.wrapperData");
        //var val = component.get("v.selectHumanCapitalStudy");
        var manRecID = component.get("v.mandateRecId");
        
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('='); //Split by & so that you get the key value pairs separately in a list
        
        debugger;
        console.log(' sURLVariables[1]'+ sURLVariables[1]);
        console.log('NextFollowUpdate'+abc.nextfollowupdate);
        if(abc.selectCoverPage== true && (abc.nextfollowupdate == undefined || abc.nextfollowupdate == null)){
            alert('Please select a valid date for the Next Follow-up meeting.');
            return;
        }
        if(abc.selectHumanCapitalStudy == true){
            if(abc.hcsStartDate == undefined || abc.hcsStartDate == null) {
                alert('Please insert valid values for the Start and End dates.');
                return;   
            }
            
            if(abc.hcsStartDate >= abc.hcsEndDate){
                alert('Start date must be lower than end date.');
                return;
            }
        }
        
        //Ankita Ends
        
        abc.masterId = sURLVariables[1].split('&')[0]; // update to fix mandate id issue.
        abc.hcsSortBy = component.get("v.hcsSortBy");
        abc.reportType = component.get("v.reportType");
        
        debugger;
        abc.selectedSubComp = component.get("v.selectedsubComp");
        abc.selectedComp = component.get("v.selectedComp");
        abc.module = component.get("v.module");
        debugger;
        console.log(component.get("v.wrapperData"));
        var action = component.get("c.generateReport");
        var candIds = [];
        if(component.get("v.selectedcandidateIds") != undefined && component.get("v.selectedcandidateIds") != null ){
            candIds = component.get("v.selectedcandidateIds");
        }
        
        if(component.get("v.potentialCandidateIds") != undefined && component.get("v.potentialCandidateIds") != null){
            var temp= component.get("v.potentialCandidateIds");
            console.log('The ptential can:'+temp);
            console.log('The candidates are '+candIds);
            var a = 0;
            
            if(candIds.length==0)
            {
                for (var i = 0; i < temp.length; i++) 
                {
                    candIds.push(temp[i]);
                }
            }
            
        } 
        
        console.log('the final can list is'+candIds);
        
        debugger;
        var allPartner = [];
        allPartner = component.get("v.selectedPartners");
        abc.partners= allPartner;
        abc.selectedcandidateIds = candIds;
        var partnerList = component.get("v.partnerList");
        var researcherList = component.get("v.ResearcherList");
        var allUsersToUpdate = researcherList.concat(partnerList);
        console.log('abc'+abc);
        action.setParams({
            "wrapData":abc,
            "userList":allUsersToUpdate,
            "manId":manRecID,
        });
        
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            
            if (state === "SUCCESS") {
                
                debugger;
                
                swal.fire({
                    title: "Success!",
                    text: "The Report has been generated successfully.",
                    type: "success",
                    timer: 3000
                });
                component.set("v.displayLeadersReportModal",false);
            }else if (state === "INCOMPLETE") {
                
                alert("From server:INCOMPLETE Request ");
                
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        alert(errors[0].message);
                        console.log("Error message: " +
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    getcandidatesData : function(component,event,helper){
        var action= component.get("c.getAllCandidatesData");
        action.setParams({
            "canIds" : component.get("v.selectedcandidateIds")
        });
        
        action.setCallback(this,$A.getCallback(function(response){
            var state= response.getState();
            var storeResponse = response.getReturnValue();
            
            component.set("v.candidatesData",storeResponse);
            
            
            
        }));
        $A.enqueueAction(action);
    },
    
    getCandidatesByNameandId : function(component,event,helper){
        var action= component.get("c.getCandidateNameById");
        action.setParams({
            "canIds" : component.get("v.selectedcandidateIds")
        });
        
        action.setCallback(this,$A.getCallback(function(response){
            var state= response.getState();
            var storeResponse = response.getReturnValue();
            
            component.set("v.candidateNameMapById",storeResponse);
        }));
        $A.enqueueAction(action);
    },
    
    getPartnerName : function(component,event,helper){
        debugger;
        var action= component.get("c.getPartnerNameandId");
        action.setParams({
            "manId" : component.get("v.mandateRecId")
        });
        
        action.setCallback(this,$A.getCallback(function(response){
            var state= response.getState();
            var storeResponse = response.getReturnValue();
            var partnerName = [];
            if(storeResponse != null || storeResponse != undefined ) {
                debugger;
                
                component.set("v.partnerList",storeResponse[0].PartnerList);
                component.set("v.ResearcherList",storeResponse[0].ResearcherList); 
                component.set("v.CompetencyList",storeResponse[0].CompetencyName);
                component.set("v.selectedsubComp",storeResponse[0].CompetencyName);
                component.set("v.CompetencyFromLrn",storeResponse[0].CompetencyNameFromLrn);
                if(storeResponse[0].CompetencyNameFromLrn.length != 0){
                    component.set("v.displayCompetency",true);    
                }
                console.log('storeResponse'+storeResponse);
                
            }
        }));
        $A.enqueueAction(action);
    },
    
    UpdatePartner : function(component,event,helper){
        debugger;
        var flag =  event.getSource().get('v.value');
        //alert(flag);
        var esxistingPartner = [];
        esxistingPartner = component.get("v.selectedPartners");
        if(flag){
            esxistingPartner.push(event.getSource().get('v.name'));
            component.set("v.selectedPartners",esxistingPartner);
        }else{
            for (var i = esxistingPartner.length; i--;) {
                if (esxistingPartner[i] === event.getSource().get('v.name')) {
                    esxistingPartner.splice(i, 1);
                    break;
                }
            }
            component.set("v.selectedPartners",esxistingPartner);
        }
    },
})