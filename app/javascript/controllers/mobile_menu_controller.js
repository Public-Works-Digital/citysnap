import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  initialize() {
    // This runs once when the controller is first instantiated
    this.menuOpen = false
  }

  connect() {
    console.log("Mobile menu controller connected, menuOpen:", this.menuOpen)

    // Only close on first connect, not on reconnect
    if (!this.menuOpen && this.hasMenuTarget) {
      this.menuTarget.classList.add('hidden')
    }
  }

  toggle(event) {
    console.log("Toggle clicked", event)

    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    const isHidden = this.menuTarget.classList.contains('hidden')
    console.log("Menu is hidden:", isHidden)

    if (isHidden) {
      this.menuTarget.classList.remove('hidden')
      this.menuOpen = true
      console.log("Opening menu")
    } else {
      this.menuTarget.classList.add('hidden')
      this.menuOpen = false
      console.log("Closing menu")
    }
  }
}
