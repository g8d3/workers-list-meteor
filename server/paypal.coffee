@Paypal = {}

Paypal.payUrl = (options = {})->
  if options.real
    "https://svcs.paypal.com/AdaptivePayments/Pay"
  else
    "https://svcs.sandbox.paypal.com/AdaptivePayments/Pay"

Paypal.userId   = 'AbVztxBLhT5zbJolEdTT3O8JRQzoZ0wqfjl6kDRkBCnYaIcYTfPaoqm4ECSJ'
Paypal.password = 'EBXxTBAcpVIC_eTC9brwvmYwLjctEJCp2f7UDGeSKvwzQHGU-k-5xTMik7zw'
Paypal.appId = (options = {}) ->
  if options.real
    ''
  else
    'APP-80W284485P519543T'

Paypal.data = (options = {}) ->
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

Paypal.payTo = (email, amount, callback) ->
  HTTP.post @payUrl(), @data(receivers: [{email: email, amount: amount}]), callback

Paypal.test = ->
  @payTo 'juandavid1707@gmail.com', '10.00', ->
    console.log('args')
    console.log(arguments)
    console.log('args')

#Paypal.test()
#HTTP.post payUrl, receivers: [{email: 'juandavid1707@gmail.com', amount: '10.00'}]
