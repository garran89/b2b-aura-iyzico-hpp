public with sharing class IyzicoController {
    @AuraEnabled
    public static Map<String,Object> iyzicoCheckoutFormInit(String cartId) {
        IyzicoRequestBuilderDTO request = new IyzicoRequestBuilderDTO();
        WebCart cart = [Select WebStoreId, TotalProductAmount,CurrencyIsoCode from WebCart where Id =: cartId];
        String paymentGatewayId = IyzicoUtils.getPaymentGatewayId(cart.WebStoreId);

        IyzicoCheckoutFormInitializeRequestModel model = new IyzicoCheckoutFormInitializeRequestModel(cart);
        Map<String,Object> requestPayload = model.getPayload();


        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint('callout:Iyzico/initialize/auth/ecom');
        httpReq.setMethod('POST');

        Map<String,String> headers = IyzicoUtils.getHTTPHeaders(requestPayload);
        for(String key : headers.keySet()){ 
            String value = headers.get(key);
            httpReq.setHeader(key, value);
        }
        httpReq.setBody(JSON.serialize(requestPayload, true));
        Http httpClient = new Http();
        HttpResponse httpRes = httpClient.send(httpReq);

        if (httpRes.getStatusCode() != 200) {
            Map<String,Object> result = new Map<String,Object>();
            result.put('success', false);
            return result;
        }

        String responseBody = httpRes.getBody() != null ? httpRes.getBody() : '';
        Map<String,Object> parsedResponse = (Map<String,Object>)JSON.deserializeUntyped(responseBody);
        System.debug(responseBody);

        String iyzicoStatus = (String)parsedResponse.get('status');
        if (iyzicoStatus != 'success') {
            Map<String,Object> result = new Map<String,Object>();
            result.put('success', false);
            return result;
        }

        CardPaymentMethod cpm = new CardPaymentMethod();
        cpm.Status = 'Active';
        cpm.ProcessingMode = 'External';
        cpm.paymentGatewayId = paymentGatewayId;
        insert cpm;

        cart.PaymentMethodId = cpm.ID;
        cart.CartHandling__c = 'redirect';
        update cart;

        Map<String,Object> result = new Map<String,Object>();
        result.put('success', true);
        result.put('paymentPageUrl', (String)parsedResponse.get('paymentPageUrl'));
        return result;
        
    }

    @AuraEnabled
    public static ConnectApi.PostAuthorizationResponse handlePostAuthorization(String token, String cartId) {
        WebCart cart = [SELECT WebStoreId, GrandTotalAmount, AccountId, PaymentMethodId FROM WebCart WHERE Id=:cartId];
        String paymentGatewayId = IyzicoUtils.getPaymentGatewayId(cart.WebStoreId);

        ConnectApi.PostAuthRequest postAuthRequest = new ConnectApi.PostAuthRequest();
		ConnectApi.PostAuthApiPaymentMethodRequest authApiPaymentMethodRequest = new ConnectApi.PostAuthApiPaymentMethodRequest();
        ConnectApi.AlternativePaymentMethod apm = new ConnectApi.AlternativePaymentMethod();
        apm.accountId = cart.AccountId;
        apm.gatewayToken = token;
        apm.gatewayTokenDetails = 'detail';
 
        authApiPaymentMethodRequest.alternativePaymentMethod = apm;
        postAuthRequest.paymentGroup = getPaymentGroup(cartId);

        postAuthRequest.accountId = cart.AccountId;
        postAuthRequest.amount = cart.GrandTotalAmount;
        postAuthRequest.comments = 'Authorizing $' + cart.GrandTotalAmount;
        postAuthRequest.effectiveDate = Datetime.now();
        postAuthRequest.currencyIsoCode = UserInfo.getDefaultCurrency();
        postAuthRequest.paymentGatewayId = paymentGatewayId;
        postAuthRequest.paymentMethod = authApiPaymentMethodRequest;

        Map<String,String> additionalData = new Map<String,String>();
        additionalData.put('token', token);
        postAuthRequest.additionalData = additionalData;

        ConnectApi.PostAuthorizationResponse postAuthResponse = ConnectApi.Payments.postAuth(postAuthRequest);
        return postAuthResponse;

    }

    // important otherwise order payment summaries are not created
    private static ConnectApi.PaymentGroupRequest getPaymentGroup(String cartId) {
        ConnectApi.PaymentGroupRequest paymentGroup = new ConnectApi.PaymentGroupRequest();
        
        paymentGroup.createPaymentGroup = true;
        paymentGroup.currencyIsoCode = UserInfo.getDefaultCurrency();
        
        String orderId = getOrderId(cartId);
        if (orderId != null && !orderId.equals('')) {
            paymentGroup.sourceObjectId = getOrderId(cartId);            
        }

        return paymentGroup;
    }

    private static String getOrderId(String cartId) {
        return [SELECT OrderId FROM CartCheckoutSession WHERE WebCartId=:cartId AND IsArchived=false].OrderId;
    }    
}