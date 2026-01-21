import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]
  static values = {
    text: String,
    message: String
  }

  copy() {
    const text = this.textValue || (this.hasSourceTarget ? this.sourceTarget.value : "")
    if (!text) return

    navigator.clipboard.writeText(text).then(() => {
      if (this.messageValue) {
        alert(this.messageValue)
      }
    })
  }
}
