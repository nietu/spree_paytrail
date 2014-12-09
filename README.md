Paytrail payments for Spree Commerce
====================================

Unofficial Paytrail payments for Spree Commerce. Doesn't use Connect API.

Should *NOT* be used in production, yet.

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
