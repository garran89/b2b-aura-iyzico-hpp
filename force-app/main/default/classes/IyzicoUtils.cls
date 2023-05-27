public with sharing class IyzicoUtils {
    private static final String IYZICO_HEADER_PREFIX_NAME = 'IYZWS';
    public static String getApiKey() {
        return 'API-KEY';
    }
    public static String getClientSecret() {
        return 'CLIENT-SECRET';
    }

    public static String substring(String str, Integer startIndex, Integer endIndex) {
        if (str == null) {
            return null;
        }
        // handle negatives
        if (endIndex < 0) {
            endIndex = str.length() + endIndex; // remember endIndex is negative
        }
        if (startIndex < 0) {
            startIndex = str.length() + startIndex; // remember startIndex is negative
        }

        // check length next
        if (endIndex > str.length()) {
            endIndex = str.length();
        }

        // if startIndex is greater than endIndex, return ''
        if (startIndex >= endIndex) {
            return '';
        }

        if (startIndex < 0) {
            startIndex = 0;
        }
        if (endIndex < 0) {
            endIndex = 0;
        }
        return str.substring(startIndex, endIndex);
    }
    public static String generateRequestString(Object requestString) {
        Boolean isArray = requestString instanceof List<Map<String, Object>>;
        Boolean isMap = requestString instanceof  Map<String,Object>;
        String finalString = '[';

        if (isMap) {
            Map<String,Object> requestString1 = (Map<String,Object>)requestString;
            for(String key : requestString1.keySet()){ 
                Object val = requestString1.get(key);
                finalString += key + '=';
                if (val instanceof List<Object>) {
                    finalString = finalString + generateRequestString(val);
                } else if (val instanceof Map<String, Object>) { 
                    finalString = finalString + generateRequestString(val);
                } else {
                    finalString = finalString + val;
                }
                finalString += isArray ? ', ' : ',';
            }
        } else if (isArray) {
            List< Map<String, Object>> requestString2 = (List< Map<String, Object>>)requestString;
            for (Integer i = 0; i < requestString2.size(); i++) {
                Object val = requestString2[i];
                if (val instanceof Map<String,Object>) {
                    finalString = finalString + generateRequestString(val);
                } else {
                    finalString = finalString + (String)val;
                }
                finalString += isArray ? ', ' : ',';
            }
        }
        Integer idx = isArray ? -2 : -1;
        finalString = substring(finalString, 0, idx);
        finalString += ']';
        return finalString;
    }

    public static String getSHA1Digest(Object body, String randomHeader) {
        String targetString = getApiKey() + randomHeader + getClientSecret() + generateRequestString(body);
        Blob targetBlob = Blob.valueOf(targetString);
        Blob hashSHA1 = Crypto.generateDigest('SHA1', targetBlob);
        String hashBase64SHA1 = EncodingUtil.base64encode (hashSHA1);
        System.debug(hashBase64SHA1);
        return hashBase64SHA1;
    }

    public static Map<String,String> getHTTPHeaders(Object body) {
        Map<String,String> headers = new Map<String,String>();
        DateTime myDateTime = DateTime.now();

        String randomHeader = String.valueOf(myDateTime.getTime());
        String authHeaderValue = IYZICO_HEADER_PREFIX_NAME + ' ' + getApiKey() + ':' + getSHA1Digest(body, randomHeader);
        headers.put('Authorization', authHeaderValue);
        headers.put('x-iyzi-rnd', randomHeader);
        headers.put('Content-Type', 'application/json');
        return headers;

    }

    public static String formatPrice(Decimal price) {
        String stringPrice = String.valueOf(price);
        if (stringPrice.indexOf('.') == -1) {
            stringPrice = stringPrice + '.0';
        }
        return stringPrice; 
    }

    public static String getPaymentGatewayId(Id webStoreId) {
        String paymentGatewayId = [SELECT Integration FROM StoreIntegratedService WHERE ServiceProviderType='Payment' AND StoreId=:webStoreId].Integration;
        return paymentGatewayId;
    }
}
