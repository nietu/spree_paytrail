module Spree
  module PaytrailHelper

    include CheckoutHelper
    include ActiveMerchant::Billing::Integrations::ActionViewHelper
  end
end

