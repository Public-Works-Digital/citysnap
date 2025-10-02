require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "should be valid with name" do
    category = Category.new(name: "Test Category")
    assert category.valid?
  end

  test "should not be valid without name" do
    category = Category.new
    assert_not category.valid?
    assert category.errors[:name].any?
  end

  test "should have default position of 0" do
    category = Category.create!(name: "Test")
    assert_equal 0, category.position
  end

  test "should be active by default" do
    category = Category.create!(name: "Test")
    assert category.active?
  end

  test "should support parent-child relationships" do
    parent = Category.create!(name: "Parent")
    child = Category.create!(name: "Child", parent: parent)

    assert_equal parent, child.parent
    assert_includes parent.children, child
  end

  test "should calculate level correctly" do
    main = Category.create!(name: "Main")
    sub = Category.create!(name: "Sub", parent: main)
    leaf = Category.create!(name: "Leaf", parent: sub)

    assert_equal 1, main.level
    assert_equal 2, sub.level
    assert_equal 3, leaf.level
  end

  test "should identify leaf nodes" do
    parent = Category.create!(name: "Parent")
    child = Category.create!(name: "Child", parent: parent)

    assert_not parent.leaf?
    assert child.leaf?
  end

  test "should return full_name with ancestors" do
    main = Category.create!(name: "Main")
    sub = Category.create!(name: "Sub", parent: main)
    leaf = Category.create!(name: "Leaf", parent: sub)

    assert_equal "Main", main.full_name
    assert_equal "Main > Sub", sub.full_name
    assert_equal "Main > Sub > Leaf", leaf.full_name
  end

  test "should return ancestors" do
    main = Category.create!(name: "Main")
    sub = Category.create!(name: "Sub", parent: main)
    leaf = Category.create!(name: "Leaf", parent: sub)

    assert_equal [], main.ancestors
    assert_equal [ main ], sub.ancestors
    assert_equal [ main, sub ], leaf.ancestors
  end

  test "should scope top_level categories" do
    main = Category.create!(name: "Main Test")
    Category.create!(name: "Child", parent: main)

    # Count only includes the main test category plus fixtures
    assert_includes Category.top_level, main
    assert Category.top_level.count >= 1
  end

  test "should scope leaf_nodes" do
    main = Category.create!(name: "Main")
    sub = Category.create!(name: "Sub", parent: main)
    leaf = Category.create!(name: "Leaf", parent: sub)

    leaf_nodes = Category.leaf_nodes
    assert_includes leaf_nodes, leaf
    assert_not_includes leaf_nodes, main
    assert_not_includes leaf_nodes, sub
  end

  test "should prevent circular reference" do
    cat1 = Category.create!(name: "Cat 1")
    cat2 = Category.create!(name: "Cat 2", parent: cat1)

    cat1.parent = cat2
    assert_not cat1.valid?
    assert_includes cat1.errors[:parent_id], "cannot be a circular reference"
  end

  test "should restrict deletion if has issues" do
    category = categories(:vehicles_hit_and_run)

    # Issue :one is already associated with this category via fixtures
    assert_not category.destroy
    assert_includes category.errors[:base], "Cannot delete record because dependent issues exist"
  end
end
