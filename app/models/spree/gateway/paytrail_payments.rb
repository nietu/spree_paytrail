module Spree
	class Gateway::PaytrailPayments < Gateway
		preference :merchant_id, :string
		preference :merchant_secret, :string

		def supports?(source)
			true
		end

    def cancel(source)
      # TODO: this should use the `refund` method, but it needs some work.
      # Doing nothing for now to prevent an error and allow orders to be cancelled.
      OpenStruct.new(success?:true,warning:'Paytrail refund method not implemented, make sure payments are cancelled manually')
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