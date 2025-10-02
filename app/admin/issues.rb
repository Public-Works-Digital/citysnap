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

end
