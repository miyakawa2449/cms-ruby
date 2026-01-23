import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["codeInput", "useBackupCodeInput", "toggleButton"]

  connect() {
    this.isBackupMode = false
  }

  toggle() {
    this.isBackupMode = !this.isBackupMode

    if (this.isBackupMode) {
      this.codeInputTarget.placeholder = "バックアップコード"
      this.codeInputTarget.maxLength = 10
      this.codeInputTarget.pattern = "[A-Fa-f0-9]*"
      this.codeInputTarget.style.textTransform = "uppercase"
      this.useBackupCodeInputTarget.value = "1"
      this.toggleButtonTarget.textContent = "認証アプリを使う"
    } else {
      this.codeInputTarget.placeholder = "000000"
      this.codeInputTarget.maxLength = 6
      this.codeInputTarget.pattern = "[0-9]*"
      this.codeInputTarget.style.textTransform = "none"
      this.useBackupCodeInputTarget.value = "0"
      this.toggleButtonTarget.textContent = "バックアップコードを使う"
    }

    this.codeInputTarget.value = ""
    this.codeInputTarget.focus()
  }
}
