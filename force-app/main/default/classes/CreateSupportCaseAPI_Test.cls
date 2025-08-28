@isTest
private with sharing class CreateSupportCaseAPI_Test {
    static List<User> testUsers = new List<User>();
    static void testDataSetup() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - API Only Integrations' LIMIT 1];

        testUsers.add(
            new User(
                FirstName = 'Test',
                LastName = 'User',
                Email = 'testuser@lyra.com',
                Username = 'testuser' + DateTime.now().getTime() + '@lyra.com.takehome',
                Alias = 'tuser',
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = p.Id
            )
        );
        insert testUsers;

        PermissionSetLicense psl = [
            SELECT Id, DeveloperName
            FROM PermissionSetLicense
            WHERE DeveloperName = 'SalesforceAPIIntegrationPsl'
            LIMIT 1
        ];

        PermissionSetLicenseAssign pslAssign = new PermissionSetLicenseAssign(
            AssigneeId = testUsers[0].Id,
            PermissionSetLicenseId = psl.Id
        );
        insert pslAssign;

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Call_Create_Support_Case' LIMIT 1];

        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = testUsers[0].Id, PermissionSetId = ps.Id);
        insert psa;
    }

    @isTest
    static void success_testSuccessfulCreation() {
        String jsonInput = JSON.serialize(
            new Map<String, Object>{
                'subject' => 'new support case #1232',
                'description' => 'Customer is complaining that their laptop wont turn on',
                'status' => 'New',
                'origin' => 'Web',
                'name' => 'Bobby G',
                'phone' => '9788123123',
                'email' => 'basfnjdf@gmail.com'
            }
        );

        initRestContext(jsonInput);
        testDataSetup();

        Test.startTest();
        System.runAs(testUsers[0]) {
            CreateSupportCaseAPI.createSupportCase();
        }
        Test.stopTest();

        List<Case> caseList = [
            SELECT Id, Status, Description, Origin, SuppliedName, SuppliedPhone, SuppliedEmail
            FROM Case
            WHERE subject = 'new support case #1232'
        ];

        String response = RestContext.response.responseBody.toString();
        Assert.isFalse(caseList.isEmpty());
        Assert.areEqual(1, caseList.size());
        Assert.areEqual('New', caseList[0].Status);
        Assert.areEqual('Customer is complaining that their laptop wont turn on', caseList[0].Description);
        Assert.areEqual('Web', caseList[0].Origin);
        Assert.areEqual('Bobby G', caseList[0].SuppliedName);
        Assert.areEqual('9788123123', caseList[0].SuppliedPhone);
        Assert.areEqual('basfnjdf@gmail.com', caseList[0].SuppliedEmail);
        Assert.areEqual(200, RestContext.response.statusCode);
        Assert.isTrue(response.contains('SUCCESS'));
        Assert.isTrue(response.contains('Support Case successfully created'));
    }

    @isTest
    static void failure_blankRequest() {
        initRestContext('');
        testDataSetup();

        Test.startTest();
        System.runAs(testUsers[0]) {
            CreateSupportCaseAPI.createSupportCase();
        }
        Test.stopTest();

        List<Case> caseList = [SELECT Id FROM Case];

        String response = RestContext.response.responseBody.toString();
        Assert.isTrue(caseList.isEmpty());
        Assert.areEqual(400, RestContext.response.statusCode);
        Assert.isTrue(response.contains('ERROR_BLANK_JSON_REQUEST'));
    }

    @isTest
    static void failure_incorrectOriginValues() {
        String jsonInput = JSON.serialize(
            new Map<String, Object>{
                'subject' => 'new support case #1232',
                'description' => 'description about the support Case',
                'status' => 'New',
                'origin' => 'New',
                'name' => 'Bobby G',
                'phone' => '6175129871',
                'email' => 'blah@json.com'
            }
        );

        initRestContext(jsonInput);
        testDataSetup();

        Test.startTest();
        System.runAs(testUsers[0]) {
            CreateSupportCaseAPI.createSupportCase();
        }
        Test.stopTest();

        List<Case> caseList = [SELECT Id FROM Case WHERE subject = 'new support case #1232'];

        String response = RestContext.response.responseBody.toString();
        Assert.isTrue(caseList.isEmpty());
        Assert.areEqual(400, RestContext.response.statusCode);
        Assert.isTrue(response.contains('JSON_REQUEST_INVALID_ORIGIN_VALUE'));
        Assert.isTrue(response.contains('Web or mobile are the only valid values for the origin field'));
    }

    @isTest
    static void failure_unparsableJson() {
        // Missing ending curly braces
        String jsonInput = JSON.serialize('{"subject": "{{');

        initRestContext(jsonInput);
        testDataSetup();

        Test.startTest();
        System.runAs(testUsers[0]) {
            CreateSupportCaseAPI.createSupportCase();
        }
        Test.stopTest();

        List<Case> caseList = [SELECT Id FROM Case];

        String response = RestContext.response.responseBody.toString();
        Assert.isTrue(caseList.isEmpty());
        Assert.areEqual(400, RestContext.response.statusCode);
        Assert.isTrue(response.contains('ERROR_PARSING_JSON_REQUEST'));
        Assert.isTrue(response.contains('Issue parsing JSON request'));
    }

    @isTest
    static void failure_processingRequest_lengthySubject() {
        String jsonInput = JSON.serialize(
            new Map<String, Object>{
                'subject' => 'new support case #1232asdasdasdjasdchkdasbCHKDASBFHJASBDHJASBDASHJDVAGSHVCAGHSDVCAGSHCVSAGHvdsaghcvbashgvdasghvcaghsvchagsvcghasvchgasvdgahwsvdhawsVCHASGvasdf askjfnBDHSVHJADSBCAHKSBDNksjNDXASJKDC adjks cajksndajksndcjkas nckjsaksj caksjc asJASDFASDAdcascascasfvsdcascscasdcascsaassacascasdcas',
                'description' => 'description about the support Case',
                'status' => 'New',
                'origin' => 'Web',
                'name' => 'Bobby G',
                'phone' => '6175129871',
                'email' => 'blah@json.com'
            }
        );

        initRestContext(jsonInput);
        testDataSetup();

        Test.startTest();
        System.runAs(testUsers[0]) {
            CreateSupportCaseAPI.createSupportCase();
        }
        Test.stopTest();

        List<Case> caseList = [SELECT Id FROM Case];

        String response = RestContext.response.responseBody.toString();
        Assert.isTrue(caseList.isEmpty());
        Assert.areEqual(500, RestContext.response.statusCode);
        Assert.isTrue(response.contains('ERROR_PROCESSING_REQUEST'));
        Assert.isTrue(response.contains('STRING_TOO_LONG'));
    }

    static void initRestContext(String jsonInput) {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonInput);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }
}
