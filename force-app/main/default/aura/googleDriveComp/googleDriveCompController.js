({
    doInit : function(component, event, helper) {
       	var url = window.location.href;
        function getParameterByName(name, url) {
            if (!url) url = window.location.href;
            name = name.replace(/[\[\]]/g, '\\$&');
            var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
                results = regex.exec(url);
            console.log('===results==',results);
            if (!results) return null;
            if (!results[2]) return '';
            return decodeURIComponent(results[2].replace(/\+/g, ' '));
        }
        var code = getParameterByName('code');
        
        if(code !== undefined && code!=='' && code!==null) {
            var action = component.get('c.getAccessToken');
            action.setParams({
                'code' : code
            });
            action.setCallback(this, function(response){
                var status = response.getState();
               	if(status === "SUCCESS"){
                    var accessToken = response.getReturnValue();
                    component.set("v.accessToken", accessToken);
                    component.set("v.access", accessToken==true?'Authenticated..':'Not Authenticated..');
                }
            });
            
            $A.enqueueAction(action);
        }
    },
    doAuth : function(component, event, helper) {
        var action  = component.get("c.createAuthURL");
        action.setCallback(this, function(response){
            var status = response.getState();
            if(status === "SUCCESS"){
                var authUrl = response.getReturnValue();
                window.location.href = response.getReturnValue();
            }
        });
        
        $A.enqueueAction(action);
    }
})