# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding categories..."

# Category hierarchy: Main Category > Sub-Category > Issue Type
categories_data = {
  "Vehicles (Accidents, traffic, & parking)" => {
    "Accident" => {
      "Hit and run" => "Car ran into someone and left before police arrived",
      "Leaving the scene" => "Someone damaged property and left before police came",
      "Pedestrian hit" => "Vehicle ran into someone walking or running",
      "Vehicle accident" => "Car wrecks and bicycle crashes"
    },
    "Parking" => {
      "Parking in crosswalk" => "Parked car preventing people from safely crossing a street",
      "Car blocking my driveway" => "Car parked illegally in front of a driveway",
      "Illegal handicapped parking" => "Car parked in a handicapped spot without a handicapped sticker",
      "Blocked fire hydrant" => "Car parked in front of a fire hydrant",
      "Other illegal parking" => "Other illegal parking (no parking zones, cars on sidewalk, cars in bikelane, cars in bus stops)",
      "Parking without valid permit" => "Cars parked in a zone requiring a parking permit with expired or missing permit"
    },
    "Traffic" => {
      "Abandoned Vehicle" => "Car has been in same location for significant amount of time",
      "Disabled Vehicle" => "Car on the road or side of road is not running properly",
      "Drunk Driver" => "Driver intoxicated while driving a car",
      "Missing sign or broken signal" => "Traffic light out of order or traffic sign fallen/hidden",
      "Obstruction in roadway" => "Something blocking the road that could be dangerous",
      "Other vehicle or traffic problems" => "Any other problems with vehicles or traffic not described here",
      "Traffic congestion" => "Often referred to by drivers as stuck in traffic",
      "Vehicle running, no driver" => "Car appears to be on and running, but nobody is inside it",
      "Wreckless driving" => "Someone is driving dangerously and may cause harm to other people"
    }
  }
}

categories_data.each_with_index do |(main_name, subcategories), main_position|
  main_category = Category.find_or_create_by!(name: main_name) do |cat|
    cat.position = main_position
    cat.active = true
  end

  subcategories.each_with_index do |(sub_name, issue_types), sub_position|
    sub_category = Category.find_or_create_by!(name: sub_name, parent: main_category) do |cat|
      cat.position = sub_position
      cat.active = true
    end

    issue_types.each_with_index do |(type_name, description), type_position|
      Category.find_or_create_by!(name: type_name, parent: sub_category) do |cat|
        cat.description = description
        cat.position = type_position
        cat.active = true
      end
    end
  end
end

puts "Created #{Category.count} categories"
puts "  - #{Category.top_level.count} main categories"
puts "  - #{Category.where.not(parent_id: nil).where(id: Category.select(:parent_id)).count} sub-categories"
puts "  - #{Category.leaf_nodes.count} issue types"

# Create sample users (only in development)
if Rails.env.development?
  puts "\nCreating sample users..."

  # Create a citizen user
  citizen = User.find_or_create_by!(email: "citizen@example.com") do |user|
    user.password = "password"
    user.password_confirmation = "password"
    user.user_type = "citizen"
  end
  puts "  - Created citizen: #{citizen.email}"

  # Create an officer user
  officer = User.find_or_create_by!(email: "officer@example.com") do |user|
    user.password = "password"
    user.password_confirmation = "password"
    user.user_type = "officer"
  end
  puts "  - Created officer: #{officer.email}"

  puts "Sample users created. You can log in with:"
  puts "  Citizen: citizen@example.com / password"
  puts "  Officer: officer@example.com / password"
end

# Create admin user (all environments)
puts "\nCreating admin user..."

admin = User.find_or_initialize_by(email: "admin@citysnap.com")

if admin.new_record?
  # Generate a random temporary password
  temp_password = SecureRandom.hex(16)
  admin.password = temp_password
  admin.password_confirmation = temp_password
  admin.user_type = "admin"
  admin.save!

  # Generate password reset token
  raw_token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)
  admin.reset_password_token = encrypted_token
  admin.reset_password_sent_at = Time.current
  admin.save!

  puts "  - Created admin user: #{admin.email}"
  puts "  - A password reset is required on first login"
  puts "  - Password reset URL: http://localhost:3000/users/password/edit?reset_password_token=#{raw_token}"
  puts "  - Use this URL to set your admin password on first login"
else
  puts "  - Admin user already exists: #{admin.email}"
end
