class CreateSpreePaytrailPaymentsCheckouts < ActiveRecord::Migration
  def change
    create_table :spree_paytrail_payments_checkouts do |t|
      t.timestamp :timestamp
      t.string :method
    end
  end
end
