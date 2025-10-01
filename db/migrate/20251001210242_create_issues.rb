class CreateIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :issues do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.text :comment

      t.timestamps
    end
  end
end
