#!/bin/bash
real=$1

payUrl(){
  if [ -z $real ]; then
    "https://svcs.paypal.com/AdaptivePayments/Pay"
  else
    "https://svcs.sandbox.paypal.com/AdaptivePayments/Pay"
  fi
}
userId='AbVztxBLhT5zbJolEdTT3O8JRQzoZ0wqfjl6kDRkBCnYaIcYTfPaoqm4ECSJ'
password='EBXxTBAcpVIC_eTC9brwvmYwLjctEJCp2f7UDGeSKvwzQHGU-k-5xTMik7zw'
appId(){
  if [ -z $real ]; then
    ''
  else
    'APP-80W284485P519543T'
  fi
}
data()
  headers:
    'X-PAYPAL-SECURITY-USERID':       @userId
    'X-PAYPAL-SECURITY-PASSWORD':     @password
    'X-PAYPAL-SECURITY-SIGNATURE':    '123'
    'X-PAYPAL-REQUEST-DATA-FORMAT':   'JSON'
    'X-PAYPAL-RESPONSE-DATA-FORMAT':  'JSON'
    'X-PAYPAL-DEVICE-IPADDRESS':      '192.168.0.1'
    'X-PAYPAL-APPLICATION-ID':        @appId()
  data:
    actionType: 'PAY'
    returnUrl: 'none'
    cancelUrl: 'none'
    requestEnvelope:
      errorLanguage: 'en_US'
    currencyCode: 'USD'
    receiverList:
      receiver: options.receivers


while read line ; do
  headers=(${headers[@]} -H "$line")
done < public/headers.txt
echo ${headers[@]}
curl -X PUT \
     ${headers[@]} \
     -d @'public/example.json' \
     echo.httpkit.com
