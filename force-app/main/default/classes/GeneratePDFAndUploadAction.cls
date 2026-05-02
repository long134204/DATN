public with sharing class GeneratePDFAndUploadAction {

    @InvocableMethod(label='Generate PDF and Upload to Drive')
    public static void generate(List<Id> recordIds){

        if(recordIds == null || recordIds.isEmpty()) return;

        List<ContentVersion> contentVersions = new List<ContentVersion>();

        // ===== 1. GENERATE PDF =====
        for(Id recordId : recordIds){

            try{
                PageReference pdfPage = Page.renderPDF;
                pdfPage.getParameters().put('id', recordId);

                Blob pdfBlob = pdfPage.getContent();

                ContentVersion cv = new ContentVersion();
                cv.Title = 'Feedback_' + recordId + '_' + Date.today();
                cv.PathOnClient = 'Feedback_' + recordId + '.pdf';
                cv.VersionData = pdfBlob;

                contentVersions.add(cv);

            } catch(Exception e){
                System.debug('PDF ERROR: ' + e.getMessage());
            }
        }

        if(contentVersions.isEmpty()) return;

        insert contentVersions;

        // ===== 2. QUERY LẠI =====
        List<ContentVersion> insertedCVs = [
            SELECT Id, ContentDocumentId, VersionData, PathOnClient, Title
            FROM ContentVersion
            WHERE Id IN :contentVersions
        ];

        // ===== 3. LINK FILE =====
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();

        for(Integer i = 0; i < insertedCVs.size(); i++){

            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = insertedCVs[i].ContentDocumentId;
            link.LinkedEntityId = recordIds[i]; // đúng record
            link.ShareType = 'I';

            links.add(link);
        }

        insert links;

        // ===== 4. UPLOAD GOOGLE DRIVE =====
        uploadToDrive(insertedCVs);
    }


    // ================= UPLOAD =================
    public static void uploadToDrive(List<ContentVersion> files){

        String folderId = getOrCreateRootFolder();
        if(folderId == null){
            System.debug('Folder not found');
            return;
        }

        Http http = new Http();

        for(ContentVersion cv : files){
            try{
                uploadFile(cv, folderId, http);
            } catch(Exception e){
                System.debug('UPLOAD ERROR: ' + e.getMessage());
            }
        }
    }


    // ===== ROOT FOLDER (KHÔNG BỊ TRÙNG) =====
    public static String getOrCreateRootFolder(){

        String folderName = 'Salesforce Files';
        Http http = new Http();

        // 🔍 SEARCH (chỉ lấy 1 folder)
        String query = 'mimeType="application/vnd.google-apps.folder" and name="' + folderName + '" and trashed=false';
        query = EncodingUtil.urlEncode(query, 'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint('callout:GoogleDrive/drive/v3/files?q=' + query + '&fields=files(id,name)&pageSize=1');

        HttpResponse res = http.send(req);

        if(res.getStatusCode() == 200){
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> files = (List<Object>) result.get('files');

            if(files != null && !files.isEmpty()){
                return (String)((Map<String, Object>)files[0]).get('id');
            }
        }

        // ❗ CREATE nếu chưa có
        HttpRequest createReq = new HttpRequest();
        createReq.setMethod('POST');
        createReq.setEndpoint('callout:GoogleDrive/drive/v3/files');
        createReq.setHeader('Content-Type','application/json');

        Map<String,Object> body = new Map<String,Object>{
            'name' => folderName,
            'mimeType' => 'application/vnd.google-apps.folder'
        };

        createReq.setBody(JSON.serialize(body));

        HttpResponse createRes = http.send(createReq);

        if(createRes.getStatusCode() == 200 || createRes.getStatusCode() == 201){
            Map<String,Object> data = (Map<String,Object>) JSON.deserializeUntyped(createRes.getBody());
            return (String)data.get('id');
        }

        return null;
    }


    // ===== UPLOAD FILE =====
    public static void uploadFile(ContentVersion cv, String folderId, Http http){

        String fileName = cv.PathOnClient != null ? cv.PathOnClient : cv.Title;

        String boundary = '-------314159265358979323846';
        String delimiter = '\r\n--' + boundary + '\r\n';
        String closeDelimiter = '\r\n--' + boundary + '--';

        Map<String,Object> metadata = new Map<String,Object>{
            'name' => fileName,
            'parents' => new List<String>{folderId}
        };

        String body = delimiter +
            'Content-Type: application/json\r\n\r\n' +
            JSON.serialize(metadata) +
            delimiter +
            'Content-Type: application/octet-stream\r\n' +
            'Content-Transfer-Encoding: base64\r\n\r\n' +
            EncodingUtil.base64Encode(cv.VersionData) +
            closeDelimiter;

        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('callout:GoogleDrive/upload/drive/v3/files?uploadType=multipart');
        req.setHeader('Content-Type','multipart/related; boundary=' + boundary);
        req.setBody(body);
        req.setTimeout(120000);

        HttpResponse res = http.send(req);

        System.debug('Upload result: ' + res.getBody());
    }
}