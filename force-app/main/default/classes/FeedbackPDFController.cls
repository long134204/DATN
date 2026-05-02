public with sharing class FeedbackPDFController {
    public Feedback__c feedback {get; set;}

    public FeedbackPDFController() {
        Id recordId = ApexPages.currentPage().getParameters().get('id');
        feedback = [SELECT Id, Name, Status__c, Description__c, Contact__r.Name, Priority__c, CreatedDate, Resolved_Date__c
                    FROM Feedback__c 
                    WHERE Id = :recordId];
    }
}