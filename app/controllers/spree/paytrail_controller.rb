module Spree
	class PaytrailController < StoreController

		def payment
			order = current_order || raise(ActiveRecord::RecordNotFound)

			paytrail_line_items = []

			order.line_items.each do |item|
				paytrail_line_items << {
					title: item.name,
					amount: item.quantity,
					price: item.price.to_f,
					vat: 100*order.tax_zone.tax_rates.find_by(tax_category_id: item.tax_category_id).amount.to_f,
					type: 1
				}
			end

			order.adjustments.where(source_type: "Spree::Shipment").each do |shipment_costs|
				paytrail_line_items << {
					title: shipment_costs.label,
					amount: 1,
					price: shipment_costs.amount.to_f.round(2),
					vat: 24.00,
					type: 2
				}
			end

			request_body = {
			  :"orderNumber" => order.number,
			  :"currency" => order.currency,
			  :"locale" => "fi_FI",
			  :"urlSet" => {
			    :"success" => confirm_paytrail_url(:payment_method_id => params[:payment_method_id], :utm_nooverride => 1),
			    :"failure" => cancel_paytrail_url,
			    :"pending" => "",
			    :"notification" => notify_paytrail_url
			  },
			  :"orderDetails" => {
			    :"includeVat" => "1",
			    :"contact" => {
			      :"telephone" => order.billing_address.phone,
			      :"mobile" => order.billing_address.phone,
			      :"email" => order.email,
			      :"firstName" => order.billing_address.firstname,
			      :"lastName" => order.billing_address.lastname,
			      :"companyName" => order.billing_address.company,
			      :"address" => {
			        :"street" => order.billing_address.address1,
			        :"postalCode" => order.billing_address.zipcode,
			        :"postalOffice" => order.billing_address.city,
			        :"country" => order.billing_address.country.iso
			      }
			    },
			    :"products" => paytrail_line_items
			  }
			}.to_json

			options = {
				:body => request_body,
				:basic_auth => {
					:username => payment_method.preferred_merchant_id.present? ? payment_method.preferred_merchant_id : '13466',
					:password => payment_method.preferred_merchant_secret.present? ? payment_method.preferred_merchant_secret : '6pKF4jkv97zmqBJ3ZL8gUw5DfT2NMQ'
				},
				:headers => {
					'Content-Type' => 'application/json',
					'Accept' => 'application/json',
					'X-Verkkomaksut-Api-Version' => '1'
				}
			}

			begin
				require 'httparty'
				paytrail_response = HTTParty.post('https://payment.paytrail.com/api-payment/create', options)

				unless paytrail_response["errorCode"]
					redirect_to paytrail_response["url"]
				else
					# TODO i18n
					flash[:error] = "Maksutapa ei toiminut. Paytrail ilmoittaa: #{paytrail_response['errorCode']}"
					redirect_to checkout_state_path(:payment)
				end
			rescue SocketError
				flash[:error] = "Could not connect to Paytrail."
				redirect_to checkout_state_path(:payment)
			end
		end

		def confirm
			order = current_order || raise(ActiveRecord::RecordNotFound)
			md5_fingerprint = Digest::MD5.hexdigest([
				payment_method.preferred_merchant_secret,
				payment_method.preferred_merchant_id,
				order.number
			].join('&')).upcase

			calculated_md5 = Digest::MD5.hexdigest([
				params["ORDER_NUMBER"],
				params["TIMESTAMP"],
				params["PAID"],
				params["METHOD"],
				payment_method.preferred_merchant_secret
			].join('|')).upcase

			if calculated_md5 == params["RETURN_AUTHCODE"]

				order.payments.create!({
					:source => Spree::PaytrailPaymentsCheckout.create({
						:timestamp => Time.at(params["TIMESTAMP"].to_i).to_datetime,
						:method => paytrail_method_in_words(params["METHOD"])
					}),
					:amount => order.total,
					:payment_method => payment_method
				})

				order.next
				if order.complete?
					flash.notice = Spree.t(:order_processed_successfully)
					flash[:commerce_tracking] = "nothing special"
					
					# Changing order.token to order.guest_token according to:
					# https://github.com/spree-contrib/better_spree_paypal_express/issues/115
					redirect_to order_path(order, :token => order.guest_token)
				else
					redirect_to checkout_state_path(order.state)
				end
			else
				flash[:notice] = "Now this is strange. Something called 'authcode' isn't what we expect. We expected to get #{calculated_md5}, but we got #{params['RETURN_AUTHCODE']}"
				redirect_to checkout_state_path(order.state)
			end

		end

		def cancel
			# TODO i18n
			flash[:notice] = "Valitsitko väärän maksutavan? Ei hätää, kokeile uudestaan."
			redirect_to checkout_state_path(current_order.state)
		end

		def notify
			# TODO: Find out how to use this.
			# UPDATE: I think we should 
			true
		end

		private

		def payment_method
			Spree::PaymentMethod.find(params[:payment_method_id])
		end

		def paytrail_method_in_words(identifier)
			method_ids = [
				{ identifier: '1', title: 'Nordea' },
				{ identifier: '2', title: 'Osuuspankki' },
				{ identifier: '3', title: 'Sampo Pankki' },
				{ identifier: '4', title: 'Tapiola' },
				{ identifier: '5', title: 'Ålandsbanken' },
				{ identifier: '6', title: 'Handelsbanken' },
				{ identifier: '7', title: 'Säästöpankit, paikallisosuuspankit, Aktia, Nooa' },
				{ identifier: '8', title: 'Luottokunta' },
				{ identifier: '9', title: 'Paypal' },
				{ identifier: '10', title: 'S-Pankki' },
				{ identifier: '11', title: 'Klarna, Laskulla' },
				{ identifier: '12', title: 'Klarna, Osamaksulla' },
				{ identifier: '13', title: 'Collector (poistunut marraskuussa 2012. Uusi Collector = 19)' },
				{ identifier: '18', title: 'Joustoraha' },
				{ identifier: '19', title: 'Collector' }
			]

			correct_method = method_ids.find { |m| m[:identifier] == identifier.to_s }

			correct_method[:title] unless correct_method.nil?
		end

	end
end