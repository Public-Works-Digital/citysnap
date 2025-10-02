ActiveAdmin.register Category do

  permit_params :name, :description, :parent_id, :position, :active

end
