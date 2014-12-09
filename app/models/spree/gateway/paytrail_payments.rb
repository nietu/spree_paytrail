module Spree
	class Gateway::PaytrailPayments < Gateway
		preference :merchant_id, :string
		preference :merchant_secret, :string

		def supports?(source)
			true
		end

		def provider_class
			ActiveMerchant::Billing::Integrations::Verkkomaksut
		end

		def auto_capture?
			true
		end

		def method_type
			'paytrail'
		end

		def provider
			provider.class.new
		end

		def purchase(amount, paytrail_response, gateway_options={})
			# Haven't bothered to find out what's going on here, but
			# it doesn't work without this hack from here:
			# https://github.com/radar/better_spree_paypal_express/blob/master/app/models/spree/gateway/pay_pal_express.rb#L59
			# This is rather hackish, required for payment/processing handle_response code.
			Class.new do
			  def success?; true; end
			  def authorization; nil; end
			end.new
		end

	end
end