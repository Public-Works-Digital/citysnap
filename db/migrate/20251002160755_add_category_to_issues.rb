class AddCategoryToIssues < ActiveRecord::Migration[8.0]
  def change
    add_reference :issues, :category, null: true, foreign_key: true

    # Note: After seeding categories and updating existing issues,
    # run a separate migration to add NOT NULL constraint
  end
end
