Paytrail payments for Spree Commerce
====================================

Unofficial Paytrail payments for Spree Commerce. Doesn't use Connect API.

This extension *SHOULD NOT* be used in production. Yet.

The official Paytrail integration guide can be found here:
http://docs.paytrail.com/en/index-all.html

Installation
------------

Add spree_paytrail to your Gemfile and use the corresponding branch with your Spree Commerce.
The latest code goes to the master branch and it should never be used in production.

```ruby
gem 'spree_paytrail', github: 'vkvelho/spree_paytrail', branch: 'master'
```

```ruby
gem 'spree_paytrail', github: 'vkvelho/spree_paytrail', branch: '2-2-stable'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_paytrail:install
```

1) Go configure the payment methods in Spree Commerce backend.

2) From the PROVIDER dropdown menu choose the Spree::Gateway::PaytrailPayments.

3) From the AUTO CAPTURE dropdown menu choose Yes.

4) Give the payment the name and description you want to.

5) Save the payment gateway settings.

6) Set up the MERCHANT and MERCHANT SECRET and press UPDATE.

For testing leave MERCHANT and MERCHANT SECRET empty or set these credentials:

MERCHANT: 13466
MERCHANT SECRET: 6pKF4jkv97zmqBJ3ZL8gUw5DfT2NMQ


Testing
-------

No tests are made, sorry. To be done. In case tests are made and someone forgot to update this readme...


Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

```shell
bundle
bundle exec rake test_app
bundle exec rspec spec
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_paytrail/factories'
```

Copyright (c) 2014 Ilkka Sopanen, released under the New BSD License
