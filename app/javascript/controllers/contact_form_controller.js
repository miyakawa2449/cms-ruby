import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "button", "name", "email", "subject", "message"]
  
  async submit(event) {
    event.preventDefault()
    
    const formData = new FormData(this.formTarget)
    const button = this.buttonTarget
    const originalText = button.textContent
    
    // ローディング状態にする
    button.disabled = true
    button.textContent = '送信中...'
    
    try {
      const response = await fetch('/contacts', {
        method: 'POST',
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        }
      })
      
      const result = await response.json()
      
      if (response.ok) {
        // 成功時
        this.showMessage(result.message, 'success')
        this.formTarget.reset()
      } else {
        // エラー時
        this.showMessage(result.message, 'error')
        if (result.errors) {
          console.log('Validation errors:', result.errors)
        }
      }
    } catch (error) {
      console.error('Error:', error)
      this.showMessage('送信に失敗しました。しばらくしてからもう一度お試しください。', 'error')
    } finally {
      // ボタンを元の状態に戻す
      button.disabled = false
      button.textContent = originalText
    }
  }
  
  showMessage(message, type) {
    // 既存のメッセージを削除
    const existingMessage = document.querySelector('.contact-message')
    if (existingMessage) {
      existingMessage.remove()
    }
    
    // 新しいメッセージを作成
    const messageDiv = document.createElement('div')
    messageDiv.className = `contact-message p-4 rounded-lg mb-4 ${
      type === 'success' 
        ? 'bg-green-100 text-green-800 border border-green-200' 
        : 'bg-red-100 text-red-800 border border-red-200'
    }`
    messageDiv.textContent = message
    
    // フォームの上に挿入
    this.formTarget.parentNode.insertBefore(messageDiv, this.formTarget)
    
    // 3秒後にフェードアウト
    setTimeout(() => {
      messageDiv.style.transition = 'opacity 0.5s'
      messageDiv.style.opacity = '0'
      setTimeout(() => {
        if (messageDiv.parentNode) {
          messageDiv.remove()
        }
      }, 500)
    }, 3000)
  }
}