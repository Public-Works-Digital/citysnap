import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    this.menuTarget.classList.toggle('hidden')
  }

  close(event) {
    // Close if clicking outside
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add('hidden')
    }
  }

  disconnect() {
    this.menuTarget.classList.add('hidden')
  }
}
