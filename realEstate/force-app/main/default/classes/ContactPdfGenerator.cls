public with sharing class ContactPdfGenerator {

    public static void generateContactPdf(Id contactId) {

        Contact con = [
            SELECT Id, Name, Email, Phone
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];

        String name  = con.Name  != null ? con.Name  : '';
        String email = con.Email != null ? con.Email : '';
        String phone = con.Phone != null ? con.Phone : '';

        String logoUrl = URL.getOrgDomainUrl().toExternalForm()
            + '/resource/RealEstateLogo';

        String htmlContent =
        '<html>' +
        '<body style="font-family:Arial;font-size:12px;">' +
        '<table width="100%" border="0">' +
        '<tr>' +
        '<td><h2>Contact Details</h2></td>' +
        '<td align="right">' +
        '<img src="' + logoUrl + '" width="90"/>' +
        '</td>' +
        '</tr>' +
        '</table>' +

        '<br/>' +

        '<p><b>Name:</b> ' + name + '</p>' +
        '<p><b>Email:</b> ' + email + '</p>' +
        '<p><b>Phone:</b> ' + phone + '</p>' +

        '<br/>' +

        '<table width="100%" border="1" cellpadding="6">' +
        '<tr>' +
        '<th align="left">Field</th>' +
        '<th align="left">Value</th>' +
        '</tr>' +
        '<tr><td>Name</td><td>' + name + '</td></tr>' +
        '<tr><td>Email</td><td>' + email + '</td></tr>' +
        '<tr><td>Phone</td><td>' + phone + '</td></tr>' +
        '</table>' +

        '</body>' +
        '</html>';

       
        Blob pdfBlob = Blob.toPdf(htmlContent);

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Contact_Details_' + name;
        cv.PathOnClient = 'Contact_Details.pdf';
        cv.VersionData = pdfBlob;

        insert cv;
    }
}