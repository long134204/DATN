public with sharing class GeneratePDFAction {

    public class OutputWrapper {
        @InvocableVariable
        public Id contentVersionId;
    }

    @InvocableMethod(label='Generate PDF')
    public static List<OutputWrapper> generate(List<Id> recordIds){

        List<ContentVersion> contentVersions = new List<ContentVersion>();

        // 👉 Lấy Name
        Map<Id, Feedback__c> feedbackMap = new Map<Id, Feedback__c>(
            [SELECT Id, Name FROM Feedback__c WHERE Id IN :recordIds]
        );

        for(Id recordId : recordIds){

            PageReference pdfPage = Page.renderPDF;
            pdfPage.getParameters().put('id', recordId);

            Blob pdfBlob = pdfPage.getContent();

            String feedbackName = feedbackMap.get(recordId).Name;
            String formattedDate = Datetime.now().format('yyyy-MM-dd');

            ContentVersion cv = new ContentVersion();
            cv.Title = feedbackName + '_' + formattedDate;
            cv.PathOnClient = feedbackName + '_' + formattedDate + '.pdf';
            cv.VersionData = pdfBlob;

            contentVersions.add(cv);
        }

        insert contentVersions;

        // 👉 Query lại để lấy ContentDocumentId
        List<ContentVersion> insertedCVs = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id IN :contentVersions
        ];

        // 🔥 Tìm Library theo Name
        ContentWorkspace library = [
            SELECT Id
            FROM ContentWorkspace
            WHERE Name = 'FileFeedback'
            LIMIT 1
        ];

        // 👉 Link file vào Library
        List<ContentWorkspaceDoc> workspaceDocs = new List<ContentWorkspaceDoc>();

        for(ContentVersion cv : insertedCVs){
            ContentWorkspaceDoc cwd = new ContentWorkspaceDoc();
            cwd.ContentWorkspaceId = library.Id;
            cwd.ContentDocumentId = cv.ContentDocumentId;

            workspaceDocs.add(cwd);
        }

        if(!workspaceDocs.isEmpty()){
            insert workspaceDocs;
        }

        // 👉 Output cho Flow
        List<OutputWrapper> outputs = new List<OutputWrapper>();

        for(ContentVersion cv : contentVersions){
            OutputWrapper out = new OutputWrapper();
            out.contentVersionId = cv.Id;
            outputs.add(out);
        }

        return outputs;
    }
}