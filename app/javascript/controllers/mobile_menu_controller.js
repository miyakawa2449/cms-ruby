import { Controller } from "@hotwired/stimulus"

// Toggles the mobile navigation menu.
export default class extends Controller {
  static targets = ["panel", "button"]

  toggle() {
    if (this.panelTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "true")
    }
  }

  close() {
    this.panelTarget.classList.add("hidden")
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "false")
    }
  }
}
