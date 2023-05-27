public with sharing class IyzicoCheckoutFormInitializeRequestModel {
    WebCart cart;
    String cartId;
    public IyzicoCheckoutFormInitializeRequestModel(WebCart cart) {
        this.cart = cart;
        this.cartId = cart.Id;
    }

    public Map<String,Object> getPayload() {
        String userId = UserInfo.getUserId();
        String contactId = [SELECT ContactId FROM User WHERE Id = :userId].ContactId;
        Contact contact = [Select Id, Email, FirstName, LastName from Contact where Id = :contactId];
        String accountId = [SELECT AccountId FROM Contact WHERE Id = :contactId].AccountId;
        List<ContactPointAddress> addresses = [Select Id,AddressType,City,Country,PostalCode,Street from ContactPointAddress where ParentId = :accountId];
        String fullName = contact.FirstName + ' ' + contact.LastName;

        Map<String,Object> requestPayload = new Map<String,Object>();
        String cartPrice = IyzicoUtils.formatPrice(cart.TotalProductAmount);
        requestPayload.put('conversationId', this.cartId);
        requestPayload.put('price', cartPrice);
        requestPayload.put('basketId', this.cartId);
        requestPayload.put('paymentGroup', 'PRODUCT');

        Map<String,Object> buyer = new Map<String,Object>();
        buyer.put('id', contactId);
        buyer.put('name', contact.FirstName);
        buyer.put('surname', contact.LastName);
        buyer.put('identityNumber', contactId);
        buyer.put('email', contact.Email);

        Map<String,Object> billingAddress = new Map<String,Object>();
        Map<String,Object> shippingAddress = new Map<String,Object>();

        for (ContactPointAddress cpa : addresses) {
            if (cpa.AddressType == 'Billing') {
                String billingAddressAsString = cpa.Street + ', ' + cpa.City + ', ' + cpa.PostalCode + ', ' + cpa.Country;
                buyer.put('registrationAddress', billingAddressAsString);
                buyer.put('city', cpa.City);
                buyer.put('country', 'Turkey');
                buyer.put('zipCode', cpa.PostalCode);

                billingAddress.put('address', billingAddressAsString);
                billingAddress.put('zipCode', cpa.PostalCode);
                billingAddress.put('contactName', fullName);
                billingAddress.put('city',  cpa.City);
                billingAddress.put('country', 'Turkey');

            }

            if (cpa.AddressType == 'Shipping') {
                String shippingAddressAsString = cpa.Street + ', ' + cpa.City + ', ' + cpa.PostalCode + ', ' + cpa.Country;
                shippingAddress.put('address', shippingAddressAsString);
                shippingAddress.put('zipCode', cpa.PostalCode);
                shippingAddress.put('contactName', fullName);
                shippingAddress.put('city',  cpa.City);
                shippingAddress.put('country', 'Turkey');
            }
        }


        requestPayload.put('buyer', buyer);
        requestPayload.put('shippingAddress', shippingAddress);
        requestPayload.put('billingAddress', billingAddress);

        List< Map<String, Object>> basketItems = new List<Map<String, Object>>();
        List<CartItem> cartItems = [Select Id,Product2Id,TotalPriceAfterAllAdjustments,Name from CartItem where CartId =: this.cartId AND Type = 'Product'];
        for (CartItem item : cartItems) {
            Map<String, Object> basketItem = new Map<String, Object>();
            basketItem.put('id', item.Product2Id);
            String itemPrice = IyzicoUtils.formatPrice(item.TotalPriceAfterAllAdjustments);
            basketItem.put('price', itemPrice);
            basketItem.put('name', item.Name);
            basketItem.put('category1', 'category1');
            basketItem.put('itemType', 'PHYSICAL');

            basketItems.add(basketItem);
        }

        requestPayload.put('basketItems', basketItems);

        WebStore store = [Select Name from WebStore where Id =: this.cart.WebStoreId];
        Network network = [SELECT Name, UrlPathPrefix FROM Network WHERE Name =: store.Name];
        String callbackUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + network.UrlPathPrefix + '/s/checkout/' + this.cartId;
        requestPayload.put('callbackUrl', callbackUrl);
        requestPayload.put('currency', 'TRY'); // hardcoded as iyzico only works with Turkish lira
        requestPayload.put('paidPrice', cartPrice);

        return requestPayload;
    }
}