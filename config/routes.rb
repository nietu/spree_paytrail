Spree::Core::Engine.routes.draw do
	post '/paytrail', 		  :to => "paytrail#payment", :as => :paytrail_payment  
	get  '/paytrail/confirm', :to => "paytrail#confirm", :as => :confirm_paytrail
	get  '/paytrail/cancel',  :to => "paytrail#cancel",	 :as => :cancel_paytrail
	get  '/paytrail/notify',  :to => "paytrail#notify",  :as => :notify_paytrail
end
