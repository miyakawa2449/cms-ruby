import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { codes: Array }

  copy() {
    const codesText = this.codesValue.join("\n")
    navigator.clipboard.writeText(codesText).then(() => {
      alert("バックアップコードをクリップボードにコピーしました")
    })
  }

  download() {
    const blob = new Blob([
      "Portfolio Site - 2FA Backup Codes\n",
      "=".repeat(40) + "\n\n",
      "Generated: " + new Date().toLocaleString() + "\n\n",
      "These codes can be used once each:\n\n",
      this.codesValue.join("\n"),
      "\n\nKeep these codes in a safe place."
    ], { type: "text/plain" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = "portfolio-2fa-backup-codes.txt"
    a.click()
    URL.revokeObjectURL(url)
  }

  print() {
    window.print()
  }
}
