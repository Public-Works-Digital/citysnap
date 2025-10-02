ActiveAdmin.register User do
  permit_params :email, :user_type, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :email
    column :user_type
    column :created_at
    actions
  end

  filter :email
  filter :user_type
  filter :created_at

  form do |f|
    f.inputs do
      f.input :email
      f.input :user_type, as: :select, collection: User.user_types.keys
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
end
