global class IyzicoPaymentAdaptor implements commercepayments.PaymentGatewayAdapter {
    private static final commercepayments.SalesforceResultCodeInfo SUCCESS_SALESFORCE_RESULT_CODE_INFO = 
    		new commercepayments.SalesforceResultCodeInfo(commercepayments.SalesforceResultCode.Success);
    private static final commercepayments.SalesforceResultCodeInfo DECLINE_SALESFORCE_RESULT_CODE_INFO = 
    		new commercepayments.SalesforceResultCodeInfo(commercepayments.SalesforceResultCode.Decline);
    
    global IyzicoPaymentAdaptor() {
    }

    global commercepayments.GatewayResponse processRequest(commercepayments.paymentGatewayContext gatewayContext) {
        commercepayments.RequestType requestType = gatewayContext.getPaymentRequestType();
        commercepayments.GatewayResponse response;
        try 
        {
            if (requestType == commercepayments.RequestType.PostAuth) {

                response = handlePostAuthorization((commercepayments.PostAuthorizationRequest)gatewayContext.getPaymentRequest());
            }
            return response;
        }
        catch(SalesforceValidationException e)
        {
             commercepayments.GatewayErrorResponse error = new commercepayments.GatewayErrorResponse('400', e.getMessage());
             return error;
        }
    }


public commercepayments.GatewayResponse handlePostAuthorization(commercepayments.PostAuthorizationRequest authRequest) {
        commercepayments.PaymentsHttp httpClient = new commercepayments.PaymentsHttp();
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint('/auth/ecom/detail/');
        httpReq.setMethod('POST');

        Map<String,String> additionalData = (Map<String,String>)authRequest.additionalData;
        Map<String,String> requestPayload = new  Map<String,String>();
        requestPayload.put('token', additionalData.get('token'));

        Map<String,String> headers = IyzicoUtils.getHTTPHeaders(requestPayload);
        for(String key : headers.keySet()){ 
            String value = headers.get(key);
            httpReq.setHeader(key, value);
        }

        httpReq.setBody(JSON.serialize(requestPayload, true));
        HttpResponse httpRes = httpClient.send(httpReq);
        String responseBody = httpRes.getBody() != null ? httpRes.getBody() : '';
        System.debug(responseBody);

        Map<String,Object> parsedResponse = (Map<String,Object>)JSON.deserializeUntyped(responseBody);
        commercepayments.PostAuthorizationResponse postAuthResponse = new commercepayments.PostAuthorizationResponse();
        if (parsedResponse != null) {
            String status = (String)parsedResponse.get('status');
            String paymentStatus = (String)parsedResponse.get('paymentStatus');
            postAuthResponse.setGatewayDate(system.now());

            if (status == 'success') {
                String paymentId = (String)parsedResponse.get('paymentId');
                String authCode = (String)parsedResponse.get('authCode');
                postAuthResponse.setGatewayResultCode(paymentStatus);
                postAuthResponse.setGatewayReferenceNumber(paymentId);
                postAuthResponse.setGatewayAuthCode(authCode);
                postAuthResponse.setSalesforceResultCodeInfo(SUCCESS_SALESFORCE_RESULT_CODE_INFO);
                Double price = (Double)parsedResponse.get('price');
                postAuthResponse.setAmount(price);
            } else {
                postAuthResponse.setGatewayResultCode(paymentStatus);
                postAuthResponse.setSalesforceResultCodeInfo(DECLINE_SALESFORCE_RESULT_CODE_INFO);
            }
        }
        return postAuthResponse;
    }
}