module Spree
  CheckoutController.class_eval do

    # Use this if you want to automatically select paytrail.
    # Other payment methods are not used

    #Due Upgrade - autoselect has been disabled
    #before_filter :autoselect_paytrail, :only => [:edit, :update]

    # Use this if you want to select paytrail from one of different payment methods

    #Due Upgrade - autoselect has been disabled
    #before_filter :redirect_for_paytrail, :only => :update

    private

    # Use this if you want to automatically select paytrail.
    def autoselect_paytrail
      return unless params[:state] == "payment"
      payment_methods = current_order.available_payment_methods
      if payment_methods.count == 1 && \
          payment_methods.first.class.name == "Spree::Gateway::PaytrailPayments"
        redirect_to paytrail_show_path(:order_id => @order.id,
                                                        :payment_method_id => payment_methods.first.id)
      end
    end

    # Use this if you want to select paytrail from one of different payment methods
    def redirect_for_paytrail
      return unless params[:state] == "payment"
      @payment_method = Spree::PaymentMethod.where(:id => params[:order][:payments_attributes].first[:payment_method_id],
                                                  :environment => Rails.env).first
      if @payment_method && @payment_method.kind_of?(Spree::Gateway::PaytrailPayments)
        @order.update_attributes(object_params)

        redirect_to main_app.paytrail_show_path(:order_id => @order.id, :payment_method_id => @payment_method.id)
      end
    end
  
  end
end
