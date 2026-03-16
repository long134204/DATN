public with sharing class feedbackListController {
    private static final Id UserId = ConstantVariableController.CURRENT_USER_INFOR?.Id;

    @AuraEnabled(cacheable=true)
    public static List<Feedback__c> getFeedbacks(String keyword) {
        List<List<Feedback__c>> res = [
            FIND :keyword IN ALL FIELDS
            RETURNING Feedback__c(
                Id,
                Name,
                Subject__c,
                Category__c,
                Type__c
                WHERE OwnerId = :UserId
                ORDER BY CreatedDate DESC
            )
            LIMIT 2000
        ];
        return res.isEmpty() ? new List<Feedback__c>() : res[0];
    }

}
