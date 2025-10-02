class AddAdminToUsers < ActiveRecord::Migration[8.0]
  def change
    # No schema change needed - just updating the enum values in the model
    # The user_type column already exists and can hold "admin" value
  end
end
