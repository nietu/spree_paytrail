class ChangeTimestampFormatInSpreePaytrailPaymentsCheckouts < ActiveRecord::Migration
  def self.up
  	change_column :spree_paytrail_payments_checkouts, :timestamp, :datetime
  end

  def self.down
  	change_column :spree_paytrail_payments_checkouts, :timestamp, :timestamp
  end
end
