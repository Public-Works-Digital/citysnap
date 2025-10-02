class AddStatusToIssues < ActiveRecord::Migration[8.0]
  def up
    add_column :issues, :status, :string

    # Backfill all existing records with 'received' status
    execute <<-SQL
      UPDATE issues SET status = 'received' WHERE status IS NULL OR status = '';
    SQL

    # Now add the NOT NULL constraint and default
    change_column_null :issues, :status, false
    change_column_default :issues, :status, from: nil, to: "received"

    add_index :issues, :status
  end

  def down
    remove_index :issues, :status
    remove_column :issues, :status
  end
end
