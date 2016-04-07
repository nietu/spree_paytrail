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
			  :"locale" => Rails.configuration.paytrail_locales["#{I18n.locale}"] || "en_US",
			  :"urlSet" => {
			    :"success" => confirm_paytrail_url(:payment_method_id => params[:payment_method_id], :utm_nooverride => 1),
			    :"failure" => cancel_paytrail_url,
			    :"pending" => "",
			    :"notification" => notify_paytrail_url
			  },
			  :"type" => "E1",
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
			        :"country" => order.billing_address.country.iso_name
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
					'X-Paytrail-Api-Version' => '1'
				}
			}

			begin
				require 'httparty'
				paytrail_response = HTTParty.post('https://payment.paytrail.com/api-payment/create', options)
				unless paytrail_response["errorCode"]
					redirect_to paytrail_response["url"]
				else
					flash[:error] = Spree.t(:paytrail_notification, :scope => :paytrail) + "#{paytrail_response['errorCode']}"
					redirect_to checkout_state_path(:payment)
				end
			rescue SocketError
				flash[:error] = Spree.t(:payment_error, :scope => :paytrail)
				redirect_to checkout_state_path(:payment)
			end
		end

		def confirm
			order = current_order || raise(ActiveRecord::RecordNotFound)
			
			calculated_md5 = Digest::MD5.hexdigest([
				params["ORDER_NUMBER"],
				params["TIMESTAMP"],
				params["PAID"],
				params["METHOD"],
				payment_method.preferred_merchant_secret.present? ? payment_method.preferred_merchant_secret : '6pKF4jkv97zmqBJ3ZL8gUw5DfT2NMQ'
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
					
					# Changing order.token to order.guest_token according to:
					# https://github.com/spree-contrib/better_spree_paypal_express/issues/115
					redirect_to order_path(order, :token => order.guest_token)
				else
					redirect_to checkout_state_path(order.state)
				end
			else
				flash[:notice] = "This is strange. Something called 'authcode' isn't what we expect. We expected to get #{calculated_md5}, but we got #{params['RETURN_AUTHCODE']}"
				redirect_to checkout_state_path(order.state)
			end

		end

		def cancel
			flash[:notice] = Spree.t(:payment_cancel, :scope => :paytrail)
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
        { identifier: '1',  title: 'Nordea' },
        { identifier: '2',  title: 'Osuuspankki' },
        { identifier: '3',  title: 'Danske Bank' },
        { identifier: '5',  title: 'Ålandsbanken' },
        { identifier: '6',  title: 'Handelsbanken' },
        { identifier: '9',  title: 'Paypal' },
        { identifier: '10', title: 'S-Pankki' },
        { identifier: '11', title: 'Klarna, Laskulla' },
        { identifier: '12', title: 'Klarna, Osamaksulla' },
        { identifier: '18', title: 'Jousto' },
        { identifier: '19', title: 'Collector' },
        { identifier: '30', title: 'Visa' },
        { identifier: '31', title: 'MasterCard' },
        { identifier: '34', title: 'Diners Club' },
        { identifier: '35', title: 'JCB' },
        { identifier: '36', title: 'Paytrail-tili' },
        { identifier: '50', title: 'Aktia' },
        { identifier: '51', title: 'POP Pankki' },
        { identifier: '52', title: 'Säästöpankki' },
        { identifier: '53', title: 'Visa (Nets)' },
        { identifier: '54', title: 'MasterCard (Nets)' },
        { identifier: '55', title: 'Diners Club (Nets)' },
        { identifier: '56', title: 'American Express (Nets)' },
        { identifier: '57', title: 'Maestro (Nets)' }
      ]

			correct_method = method_ids.find { |m| m[:identifier] == identifier.to_s }

			correct_method[:title] unless correct_method.nil?
		end

	end
end