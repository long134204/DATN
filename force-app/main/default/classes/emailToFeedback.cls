global class emailToFeedback implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(
        Messaging.InboundEmail email, 
        Messaging.InboundEnvelope envelope
    ) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        try {
            
            String senderEmail = envelope.fromAddress;

            List<Contact> contacts = [
                SELECT Id 
                FROM Contact 
                WHERE Email = :senderEmail 
                LIMIT 1
            ];

            if (contacts.isEmpty()) {
                result.success = true;
                System.debug('============contacts.isEmpty============');
                return result;

            }

            Contact con = contacts[0];

            Feedback__c fb = new Feedback__c();
            fb.Subject__c = email.subject;
            fb.Type__c = 'Feedback';

            if (email.plainTextBody != null) {
                fb.Description__c = email.plainTextBody;
            } else {
                fb.Description__c = email.htmlBody;
            }

            fb.Contact__c = con.Id;
            System.debug('============contacts.notEmpty============');
            insert fb;

            result.success = true;

        } catch (Exception e) {
            result.success = false;
            result.message = e.getMessage();
        }

        return result;
    }
}