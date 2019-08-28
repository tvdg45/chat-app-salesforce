public class ChatAppController {
    
    //This method initializes a connection to the REST API.
    @future(callout=true)
    public static void addUsersToOtherServer(String[] allFirstNames, String[] allLastNames, String[] allEmails,
                                                 String[] allUserIds) {
        
        String requestUrl = '';
        
        Http http = new Http();
        HttpRequest httpRequest = new HttpRequest();
        HttpResponse httpResponse = new HttpResponse();
        
        requestUrl = 'first_name=' + allFirstNames + '&last_name=' + allLastNames + '&email=' + allEmails +
            '&user_id=' + allUserIds + '&add_user=Add user';
        httpRequest.setEndpoint('https://chat-app-java.herokuapp.com/admin-change-users');
        httpRequest.setMethod('POST');
        httpRequest.setBody(requestUrl);
        
        httpResponse = http.send(httpRequest);
        
       	System.debug('Users added ' + httpResponse.getBody());
    }
    
    //This method initializes a connection to the REST API.
    @future(callout=true)
    public static void changeUsersOnOtherServer(String[] allFirstNames, String[] allLastNames, String[] allEmails,
                                                 String[] allUserIds) {
        
        String requestUrl = '';
        
        Http http = new Http();
        HttpRequest httpRequest = new HttpRequest();
        HttpResponse httpResponse = new HttpResponse();
        
        requestUrl = 'first_name=' + allFirstNames + '&last_name=' + allLastNames + '&email=' + allEmails +
            '&user_id=' + allUserIds + '&change_user=Change user';
        httpRequest.setEndpoint('https://chat-app-java.herokuapp.com/admin-change-users');
        httpRequest.setMethod('POST');
        httpRequest.setBody(requestUrl);
        
        httpResponse = http.send(httpRequest);
        
       	System.debug('Users changed ' + httpResponse.getBody());       
    }

    //This method initializes a connection to the REST API.
    @future(callout=true)
    public static void deleteUsersFromOtherServer(String[] allFirstNames, String[] allLastNames, String[] allEmails,
                                                 String[] allUserIds) {
        
        String requestUrl = '';
        
        Http http = new Http();
        HttpRequest httpRequest = new HttpRequest();
        HttpResponse httpResponse = new HttpResponse();
        
        requestUrl = 'user_id=' + allUserIds + '&delete_user=Delete user';
        httpRequest.setEndpoint('https://chat-app-java.herokuapp.com/admin-change-users');
        httpRequest.setMethod('POST');
        httpRequest.setBody(requestUrl);
        
        httpResponse = http.send(httpRequest);
        
       	System.debug('Users deleted ' + httpResponse.getBody());      
    }  
    
    //A before trigger utilizes this method
    public static void validateChatAppUser(List<ChatAppUser__c> allChatAppUsers) {
        
        for (ChatAppUser__c eachSavedChatAppUser: [SELECT FirstName__c, LastName__c, Email__c, User__c FROM ChatAppUser__c]) {
            
            for (ChatAppUser__c eachChatAppUserToBeSaved: allChatAppUsers) {
                
                if (eachChatAppUserToBeSaved.User__c != null) {
                    
                    if (eachChatAppUserToBeSaved.FirstName__c == eachSavedChatAppUser.FirstName__c
                        && eachChatAppUserToBeSaved.LastName__c == eachSavedChatAppUser.LastName__c
                        && eachChatAppUserToBeSaved.Email__c == eachSavedChatAppUser.Email__c
                        && eachChatAppUserToBeSaved.User__c == eachSavedChatAppUser.User__c) {
                        
                        eachChatAppUserToBeSaved.addError('You already have that user assigned to this chat app. ' +
                                                         'Please choose a different user.');
                    }
                }
            }
        }
    }
    
    //This method initializes a connection to the REST API.
    @future(callout=true)
    public static void deleteMessagesFromOtherServer(String adminSession) {
        
        String requestUrl = '';
        
        Http http = new Http();
        HttpRequest httpRequest = new HttpRequest();
        HttpResponse httpResponse = new HttpResponse();
        
        requestUrl = 'conversation_owner=' + adminSession;
        httpRequest.setEndpoint('https://chat-app-java.herokuapp.com/admin-delete-my-messages');
        httpRequest.setMethod('POST');
        httpRequest.setBody(requestUrl);
        
        httpResponse = http.send(httpRequest);
        
       	System.debug('Messages deleted ' + httpResponse.getBody());       
    }
    
    //This method initializes a connection to the REST API.
    public static void flushConversation() {
        
        String requestUrl = '';
        String[] find = new String[2];
        String[] replace = new String[2];
        List<InstantChatMessage__c> chatMessagesToInsert = new List<InstantChatMessage__c>();
        
        find[0] = '&apos;';
        find[1] = '&quot;';
        
        replace[0] = '\'';
        replace[1] = '"';
        
        if (UserInfo.getUserId() == Apexpages.currentPage().getParameters().get('adminSession')) {
            
            try {
                
        		Http http = new Http();
        		HttpRequest httpRequest = new HttpRequest();
        		HttpResponse httpResponse = new HttpResponse();
        
        		requestUrl = 'conversation_owner=' + Apexpages.currentPage().getParameters().get('adminSession');
        		httpRequest.setEndpoint('https://chat-app-java.herokuapp.com/admin-extract-messages');
        		httpRequest.setMethod('POST');
        		httpRequest.setBody(requestUrl);
        
        		httpResponse = http.send(httpRequest);
                
            	Map<String, Object> readJSONString = (Map<String, Object>)JSON.deserializeUntyped(
                	'{"messages":' + httpResponse.getBody() + '}');
            
            	List<Object> messages = (List<Object>)readJSONString.get('messages');
            
            	for (Object eachMessage: messages) {
                
                	Map<String, Object> messageFields = (Map<String, Object>)eachMessage;
                
                	if (messageFields.get('full_name') != null && messageFields.get('message') != null
                   		&& messageFields.get('conversation_owner') != null) {

                    	InstantChatMessage__c newInstantChatMessage = new InstantChatMessage__c(
                       	FullName__c = String.valueOf(messageFields.get('full_name')).replace(find[0], replace[0]).replace(find[1], replace[1]),
                       	Message__c = String.valueOf(messageFields.get('message')).replace(find[0], replace[0]).replace(find[1], replace[1]),
                       	User__c = String.valueOf(messageFields.get('conversation_owner'))
                    	);
                       
                    	chatMessagesToInsert.add(newInstantChatMessage);
                	}
            	}
            
            	if (chatMessagesToInsert.size() > 0) {
                
                	insert chatMessagesToInsert;
            	}
                
                //Messages are deleted from the MySQL table via a REST callout.
                //This action prevents guest users from seeing other guest users' data.            
				deleteMessagesFromOtherServer(Apexpages.currentPage().getParameters().get('adminSession'));
            } catch (Exception e) {  
            }
        }
    }
    
    //This method initializes a connection to the REST API.
    //If the administrator session is valid, corresponding conversation
    //data will be presented.  Otherwise, no data will be displayed.
    public static String getShowApplication() {
        
        String output = '';
        String requestUrl = '';
        
        Http http = new Http();
        HttpRequest httpRequest = new HttpRequest();
        HttpResponse httpResponse = new HttpResponse();
        
        requestUrl = 'admin_session=' + UserInfo.getUserId();
        httpRequest.setEndpoint('https://chat-app-java.herokuapp.com/admin-chat-interface');
        httpRequest.setMethod('POST');
        httpRequest.setBody(requestUrl);
        
        httpResponse = http.send(httpRequest);
        
        output += httpResponse.getBody();
        
        return output;
    }
}
