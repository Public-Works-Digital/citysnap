class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.text :description
      t.integer :parent_id
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :categories, :parent_id
    add_index :categories, :active
    add_index :categories, [:parent_id, :position]
    add_foreign_key :categories, :categories, column: :parent_id
  end
end
