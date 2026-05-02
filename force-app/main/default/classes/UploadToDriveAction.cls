public with sharing class UploadToDriveAction {

    @InvocableMethod(label='Upload to Google Drive')
    public static void upload(List<Id> fileIds){

        System.enqueueJob(new UploadQueueable(fileIds));
    }
}