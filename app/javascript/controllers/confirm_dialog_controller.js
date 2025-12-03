import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    title: String,
    message: String,
    confirmText: String,
    cancelText: String 
  }

  confirm(event) {
    event.preventDefault()
    
    // シンプルに直接モーダルを表示
    const confirmed = window.confirm(this.messageValue || "本当に削除しますか？")
    
    if (confirmed) {
      // 削除を実行
      event.target.closest('form').submit()
    }
  }
}