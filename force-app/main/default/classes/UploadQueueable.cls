public class UploadQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> fileIds;

    public UploadQueueable(List<Id> fileIds){
        this.fileIds = fileIds;
    }

    public void execute(QueueableContext context){

        List<ContentVersion> files = [
            SELECT Id, Title, VersionData, PathOnClient
            FROM ContentVersion
            WHERE Id IN :fileIds
        ];

        String folderId = getOrCreateRootFolder();
        Http http = new Http();

        for(ContentVersion cv : files){
            uploadFile(cv, folderId, http);
        }
    }

    public static String getOrCreateRootFolder(){

        String folderName = 'Salesforce Files';
        Http http = new Http();

        String query = 'mimeType="application/vnd.google-apps.folder" and name="' + folderName + '" and trashed=false';
        query = EncodingUtil.urlEncode(query, 'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:GoogleDrive/drive/v3/files?q=' + query + '&fields=files(id,name)&pageSize=1');
        req.setMethod('GET');

        HttpResponse res = http.send(req);

        if(res.getStatusCode() == 200){
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> files = (List<Object>) result.get('files');

            if(!files.isEmpty()){
                return (String)((Map<String, Object>)files[0]).get('id');
            }
        }

        HttpRequest createReq = new HttpRequest();
        createReq.setMethod('POST');
        createReq.setEndpoint('callout:GoogleDrive/drive/v3/files');
        createReq.setHeader('Content-Type','application/json');

        createReq.setBody(JSON.serialize(new Map<String,Object>{
            'name' => folderName,
            'mimeType' => 'application/vnd.google-apps.folder'
        }));

        HttpResponse createRes = http.send(createReq);

        if(createRes.getStatusCode() == 200 || createRes.getStatusCode() == 201){
            Map<String,Object> data = (Map<String,Object>) JSON.deserializeUntyped(createRes.getBody());
            return (String)data.get('id');
        }

        return null;
    }

    // ===== UPLOAD =====
    public static void uploadFile(ContentVersion cv, String folderId, Http http){

        // String fileName = cv.PathOnClient != null ? cv.PathOnClient : cv.Title;
        String fileName = cv.Title;

        String boundary = '-------314159265358979323846';

        String body =
            '--' + boundary + '\r\n' +
            'Content-Type: application/json\r\n\r\n' +
            JSON.serialize(new Map<String,Object>{
                'name' => fileName,
                'parents' => new List<String>{folderId}
            }) +
            '\r\n--' + boundary + '\r\n' +
            'Content-Type: application/octet-stream\r\n' +
            'Content-Transfer-Encoding: base64\r\n\r\n' +
            EncodingUtil.base64Encode(cv.VersionData) +
            '\r\n--' + boundary + '--';

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:GoogleDrive/upload/drive/v3/files?uploadType=multipart');
        req.setMethod('POST');
        req.setHeader('Content-Type','multipart/related; boundary=' + boundary);
        req.setBody(body);

        http.send(req);
    }
}