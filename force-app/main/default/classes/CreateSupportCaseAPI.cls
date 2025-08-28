@RestResource(urlMapping='/CreateSupportCase')
global with sharing class CreateSupportCaseAPI {
    global class CaseRequest {
        //255 character limit
        public string subject;
        //long text area - 320000 limit
        public string description;
        //picklist
        public string status;
        // limited to web or mobile
        public string origin;
        // 80 character limit
        public string name;
        // text - 40 characters
        public string phone;
        // email field
        public string email;
    }

    class CreateCase_Exception extends System.Exception {
        CreateCase_Exception(ResponseInfo resInfo) {
            this.resInfo = resInfo;
            this.exceptionInfo = new List<Object>();
        }

        CreateCase_Exception(ResponseInfo resInfo, Object arg) {
            this.resInfo = resInfo;
            this.exceptionInfo = new List<Object>{ arg };
        }

        ResponseInfo resInfo;
        List<Object> exceptionInfo;
    }

    public class ResponseInfo {
        ResponseInfo(Integer httpStatusCode, String errorCode, String errorMessage) {
            this.httpStatusCode = httpStatusCode;
            this.errorCode = errorCode;
            this.errorMessage = errorMessage;
        }

        Integer httpStatusCode;
        String errorCode;
        String errorMessage;
    }

    final String STATUS_NEW = 'New';
    final String ORIGIN_WEB = 'Web';
    final String ORIGIN_MOBILE = 'Mobile';

    ResponseInfo RESPONSE_ERROR_BLANK_JSON_REQUEST() {
        return new ResponseInfo(400, 'ERROR_BLANK_JSON_REQUEST', 'JSON Request is empty');
    }

    ResponseInfo RESPONSE_ERROR_PARSING_JSON_REQUEST() {
        return new ResponseInfo(400, 'ERROR_PARSING_JSON_REQUEST', 'Issue parsing JSON request, Exception: {0}');
    }

    ResponseInfo RESPONSE_JSON_REQUEST_INVALID_ORIGIN_VALUE() {
        return new ResponseInfo(
            400,
            'JSON_REQUEST_INVALID_ORIGIN_VALUE',
            'Web or mobile are the only valid values for the origin field, {0} is not a valid value'
        );
    }

    ResponseInfo RESPONSE_ERROR_PROCESSING_REQUEST() {
        return new ResponseInfo(500, 'ERROR_PROCESSING_REQUEST', 'Issue processing request, Exception: {0}');
    }

    ResponseInfo RESPONSE_SUCCESS() {
        return new ResponseInfo(200, 'SUCCESS', 'Support Case successfully created');
    }

    @HttpPost
    global static void createSupportCase() {
        // Create instance of class for easier access to instance variables
        final CreateSupportCaseAPI instance = new CreateSupportCaseAPI();
        instance.createSupportCaseForInstance();
    }

    void createSupportCaseForInstance() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            CaseRequest input = parseJsonRequest(req.requestBody?.toString());

            validateValidOrigin(input.Origin);

            Case supportCase = new Case();
            supportCase.Subject = input.subject;
            supportCase.Description = input.description;
            supportCase.Status = STATUS_NEW;
            supportCase.Origin = input.origin;
            supportCase.SuppliedName = input.name;
            supportCase.SuppliedPhone = input.phone;
            supportCase.SuppliedEmail = input.email;

            insert supportCase;

            setResponseSuccess(res, RESPONSE_SUCCESS());
        } catch (exception e) {
            CreateCase_Exception ccException;
            if (e instanceof CreateCase_Exception) {
                ccException = (CreateCase_Exception) e;
            } else {
                ccException = new CreateCase_Exception(RESPONSE_ERROR_PROCESSING_REQUEST(), e.getMessage());
            }

            setResponseError(res, ccException);
        }
    }

    CaseRequest parseJsonRequest(String jsonRequest) {
        if (String.isBlank(jsonRequest)) {
            throw new CreateCase_Exception(RESPONSE_ERROR_BLANK_JSON_REQUEST());
        }

        try {
            return (CaseRequest) JSON.deserialize(jsonRequest, CaseRequest.class);
        } catch (System.JSONException e) {
            throw new CreateCase_Exception(RESPONSE_ERROR_PARSING_JSON_REQUEST(), e.getMessage());
        }
    }

    void validateValidOrigin(String origin) {
        if (origin != ORIGIN_WEB && origin != ORIGIN_MOBILE) {
            throw new CreateCase_Exception(RESPONSE_JSON_REQUEST_INVALID_ORIGIN_VALUE(), origin);
        }
    }

    void setResponseSuccess(RestResponse res, ResponseInfo ri) {
        res.statusCode = ri.httpStatusCode;
        res.responseBody = Blob.valueOf(JSON.serialize(ri));
    }

    void setResponseError(RestResponse res, CreateCase_Exception ccException) {
        res.statusCode = ccException.resInfo.httpStatusCode;
        ccException.resInfo.errorMessage = String.format(ccException.resInfo.errorMessage, ccException.exceptionInfo);
        res.responseBody = Blob.valueOf(JSON.serialize(ccException.resInfo));
    }
}
