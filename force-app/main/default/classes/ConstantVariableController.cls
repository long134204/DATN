public with sharing class ConstantVariableController {
    public static String CURRENT_USER_ID = UserInfo.getUserId();
    public static User CURRENT_USER_INFOR = [SELECT
                                            Id,
                                             AccountId,
                                             ContactId,
                                             Profile.Id,
                                             Signature,
                                             UserRole.Name,
                                             UserRoleId,
                                             Email,
                                             Name
                                             FROM User
                                             WHERE Id = :CURRENT_USER_ID
                                             LIMIT 1];
}