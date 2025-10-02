class AddLocationToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :latitude, :decimal, precision: 10, scale: 8
    add_column :issues, :longitude, :decimal, precision: 11, scale: 8
    add_column :issues, :street_address, :string

    add_index :issues, [ :latitude, :longitude ]
  end
end
