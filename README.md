## Iyzico HPP Integration with Salesforce B2B(Aura)

This repository supplements the [commerce on core blog post](https://commerceoncore.com/b2b-aura-payment-integration/).

## Configuration Steps

1. Create a free sandbox [here](https://sandbox-merchant.iyzipay.com/auth/register)
2. After creating the account, generate new client_id(api key) and client_secret. 
3. Configure the client_id(api key) and client_secret in [IyzicoUtils](https://github.com/garran89/b2b-aura-iyzico-hpp/blob/main/force-app/main/default/classes/IyzicoUtils.cls) class.
4. Deploy the code to the salesforce org.
5. Follow the [blog post](https://commerceoncore.com/b2b-aura-payment-integration/#registering-a-payment-gateway-providerpgp) to register a new payment gateway provider.
4. Use [test card](https://dev.iyzipay.com/en/api/auth#testcards) details to create an order.

