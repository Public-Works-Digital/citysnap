import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mainCategory", "subCategory", "issueType", "categoryId"]

  connect() {
    // Load all categories data from the DOM
    this.loadCategoriesData()

    // If editing an existing issue, pre-select the values
    if (this.categoryIdTarget.value) {
      this.preselectCategory()
    }
  }

  loadCategoriesData() {
    // Categories data is embedded in the form as a data attribute
    const dataElement = document.getElementById('categories-data')
    if (dataElement) {
      this.categories = JSON.parse(dataElement.textContent)
    }
  }

  preselectCategory() {
    const selectedCategoryId = parseInt(this.categoryIdTarget.value)
    if (!selectedCategoryId) return

    // Find the selected category and its ancestors
    const category = this.findCategoryById(selectedCategoryId)
    if (!category) return

    const ancestors = this.findAncestors(category)

    if (ancestors.length === 3) {
      // Set main category
      this.mainCategoryTarget.value = ancestors[0].id
      this.updateSubCategories()

      // Set sub category
      this.subCategoryTarget.value = ancestors[1].id
      this.updateIssueTypes()

      // Set issue type
      this.issueTypeTarget.value = ancestors[2].id
    }
  }

  findCategoryById(id, categories = this.categories) {
    for (const category of categories) {
      if (category.id === id) return category
      if (category.children) {
        const found = this.findCategoryById(id, category.children)
        if (found) return found
      }
    }
    return null
  }

  findAncestors(category) {
    const ancestors = []
    let current = category

    while (current) {
      ancestors.unshift(current)
      current = current.parent ? this.findCategoryById(current.parent_id) : null
    }

    return ancestors
  }

  mainCategoryChanged() {
    this.resetSubCategory()
    this.resetIssueType()
    this.updateSubCategories()
    this.categoryIdTarget.value = ""
  }

  subCategoryChanged() {
    this.resetIssueType()
    this.updateIssueTypes()
    this.categoryIdTarget.value = ""
  }

  issueTypeChanged() {
    this.categoryIdTarget.value = this.issueTypeTarget.value
  }

  updateSubCategories() {
    const mainCategoryId = parseInt(this.mainCategoryTarget.value)
    if (!mainCategoryId) return

    const mainCategory = this.findCategoryById(mainCategoryId)
    if (!mainCategory || !mainCategory.children) return

    this.populateSelect(this.subCategoryTarget, mainCategory.children, "Select a sub-category")
    this.subCategoryTarget.disabled = false
  }

  updateIssueTypes() {
    const subCategoryId = parseInt(this.subCategoryTarget.value)
    if (!subCategoryId) return

    const subCategory = this.findCategoryById(subCategoryId)
    if (!subCategory || !subCategory.children) return

    this.populateSelect(this.issueTypeTarget, subCategory.children, "Select an issue type")
    this.issueTypeTarget.disabled = false
  }

  populateSelect(selectElement, items, promptText) {
    selectElement.innerHTML = `<option value="">${promptText}</option>`

    items.forEach(item => {
      const option = document.createElement('option')
      option.value = item.id
      option.textContent = item.name
      selectElement.appendChild(option)
    })
  }

  resetSubCategory() {
    this.subCategoryTarget.innerHTML = '<option value="">Select a main category first</option>'
    this.subCategoryTarget.disabled = true
  }

  resetIssueType() {
    this.issueTypeTarget.innerHTML = '<option value="">Select a sub-category first</option>'
    this.issueTypeTarget.disabled = true
  }
}
