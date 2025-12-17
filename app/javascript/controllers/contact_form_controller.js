import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "button", "messageArea"]
  
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
        // contactセクション上部へスクロール
        this.scrollToSection()
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
    messageDiv.className = `contact-message p-4 rounded-lg mb-6 text-center ${
      type === 'success' 
        ? 'bg-green-500/20 text-green-300 border border-green-500/30' 
        : 'bg-red-500/20 text-red-300 border border-red-500/30'
    }`
    
    // アイコン付きメッセージ
    const icon = type === 'success' 
      ? '<svg class="w-6 h-6 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>'
      : '<svg class="w-6 h-6 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>'
    
    messageDiv.innerHTML = `${icon}<span class="font-medium">${message}</span>`
    
    // メッセージエリアに挿入
    if (this.hasMessageAreaTarget) {
      this.messageAreaTarget.innerHTML = ''
      this.messageAreaTarget.appendChild(messageDiv)
    } else {
      this.formTarget.parentNode.insertBefore(messageDiv, this.formTarget)
    }
    
    // 成功時は10秒後にフェードアウト
    if (type === 'success') {
      setTimeout(() => {
        messageDiv.style.transition = 'opacity 0.5s'
        messageDiv.style.opacity = '0'
        setTimeout(() => {
          if (messageDiv.parentNode) {
            messageDiv.remove()
          }
        }, 500)
      }, 10000)
    }
  }
  
  scrollToSection() {
    // contactセクション全体を取得してスクロール
    const contactSection = document.getElementById('contact')
    if (contactSection) {
      // セクションの上部にスクロール（ヘッダー分のオフセットを考慮）
      const headerOffset = 100
      const elementPosition = contactSection.getBoundingClientRect().top
      const offsetPosition = elementPosition + window.pageYOffset - headerOffset
      
      window.scrollTo({
        top: offsetPosition,
        behavior: 'smooth'
      })
    }
  }
}