module SpreePaytrail
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_paytrail'

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
    
    # supported by paytrail da_DK, de_DE, et_EE, en_US, fr_FR, no_NO, ru_RU, fi_FI ja sv_SE
    # keep this in sync with SpreeI18n::Config.available_locales in application intializer
    config.paytrail_locales = {'en-GB' => 'en_US', 'sv-SE' => 'sv_SE', 'fi' => 'fi_FI', 'de' => 'de_DE'}

    initializer "spree.paytrail.payment_methods", :after => "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << Spree::Gateway::PaytrailPayments
    end
  end
end
