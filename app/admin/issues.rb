ActiveAdmin.register Issue do

  permit_params :user_id, :comment, :latitude, :longitude, :street_address, :status, :category_id, :photo

  # Remove default filters and add only the ones we want
  remove_filter :photo_attachment, :photo_blob

  filter :user
  filter :category
  filter :status, as: :select, collection: Issue.statuses.keys
  filter :street_address
  filter :created_at
  filter :updated_at

  # Customize the form
  form do |f|
    f.inputs do
      f.input :user
      f.input :category, as: :select, collection: Category.active.leaf_nodes.ordered
      f.input :status, as: :select, collection: Issue.statuses.keys.map { |k| [k.titleize, k] }
      f.input :comment
      f.input :street_address
      f.input :latitude
      f.input :longitude
      f.input :photo, as: :file
    end
    f.actions
  end

end
