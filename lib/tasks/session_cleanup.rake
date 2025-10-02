namespace :sessions do
  desc "Clean up expired sessions from the database"
  task cleanup: :environment do
    ActiveRecord::SessionStore::Session.where("updated_at < ?", 2.weeks.ago).delete_all
  end
end
