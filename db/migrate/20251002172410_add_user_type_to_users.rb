class AddUserTypeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :user_type, :string, default: "citizen", null: false

    # Backfill existing users as citizens
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE users SET user_type = 'citizen' WHERE user_type IS NULL OR user_type = '';
        SQL
      end
    end

    add_index :users, :user_type
  end
end
