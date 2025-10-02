class Category < ApplicationRecord
  # Self-referential associations
  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: "parent_id", dependent: :destroy
  has_many :issues, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :prevent_circular_reference

  # Scopes
  scope :active, -> { where(active: true) }
  scope :top_level, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position, :name) }
  scope :leaf_nodes, -> { left_joins(:children).where(children_categories: { id: nil }) }

  # Ransack configuration for ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    %w[id name description parent_id position active created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[parent children issues]
  end

  # Instance methods
  def level
    return 1 if parent_id.nil?
    parent.level + 1
  end

  def leaf?
    children.empty?
  end

  def full_name(separator: " > ")
    ancestors_names = ancestors.map(&:name)
    ancestors_names.push(name).join(separator)
  end

  def ancestors
    return [] if parent.nil?
    parent.ancestors + [parent]
  end

  def descendants
    children.flat_map { |child| [child] + child.descendants }
  end

  def siblings
    if parent_id.nil?
      Category.top_level.where.not(id: id)
    else
      parent.children.where.not(id: id)
    end
  end

  # Class methods
  def self.build_tree
    categories_by_parent = all.group_by(&:parent_id)

    def build_node(parent_id, categories_by_parent)
      (categories_by_parent[parent_id] || []).map do |category|
        {
          category: category,
          children: build_node(category.id, categories_by_parent)
        }
      end
    end

    build_node(nil, categories_by_parent)
  end

  private

  def prevent_circular_reference
    return if parent_id.nil?

    current_parent = parent
    while current_parent
      if current_parent.id == id
        errors.add(:parent_id, "cannot be a circular reference")
        break
      end
      current_parent = current_parent.parent
    end
  end
end
