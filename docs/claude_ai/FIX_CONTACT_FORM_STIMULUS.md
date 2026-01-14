# コンタクトフォーム修正指示書（Stimulus登録 + UI改善）

## 問題の概要

1. **Stimulus コントローラーが登録されていない**
   - `contact_form_controller.js` は存在するが、`index.js` に登録されていない
   - そのためフォーム送信時に何も起きない

2. **送信成功メッセージが見えない**
   - 送信後のスクロール位置が悪く、メッセージがユーザーに見えない

---

## 修正ファイル

### 1. `app/javascript/controllers/index.js`

**問題:** `contact_form_controller` が登録されていない

**修正後:**

```javascript
// Import and register all your controllers
import { application } from "./application"
import ConfirmDialogController from "./confirm_dialog_controller"
import ContactFormController from "./contact_form_controller"

application.register("confirm-dialog", ConfirmDialogController)
application.register("contact-form", ContactFormController)
```

---

### 2. `app/javascript/controllers/contact_form_controller.js`

**問題:** スクロール先がフォーム自体で、その上に表示されるメッセージが見えない

**修正後:**

```javascript
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
```

---

### 3. `app/views/portfolio/sections/_contact.html.erb`

**問題:** セクションに `id="contact"` がない、メッセージエリアがない

**修正:** 先頭部分を以下のように変更

```erb
<section id="contact" class="py-20 bg-gray-900 text-white">
  <div class="container mx-auto px-6">
    <div class="max-w-6xl mx-auto">
      <!-- ヘッダー -->
      <div class="text-center mb-16">
        <h2 class="text-4xl md:text-5xl font-bold mb-6">
          <%= content['title'] || 'Contact' %>
        </h2>
        <p class="text-xl text-gray-300 max-w-3xl mx-auto">
          <%= content['description'] || 'プロジェクトのご相談やご質問がございましたら、お気軽にお問い合わせください。' %>
        </p>
      </div>
      
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-16">
        <!-- 入力フォーム -->
        <div data-controller="contact-form">
          <h3 class="text-2xl font-bold mb-8">入力フォーム</h3>
          
          <!-- メッセージ表示エリア（ここに成功/エラーメッセージが表示される） -->
          <div data-contact-form-target="messageArea"></div>
          
          <form data-contact-form-target="form"
                data-action="submit->contact-form#submit"
                action="/contacts" method="post" class="space-y-6">
            <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
            
            <!-- 以下、フォームフィールドは変更なし -->
```

**変更点:**
1. `<div class="py-20 bg-gray-900 text-white">` → `<section id="contact" class="py-20 bg-gray-900 text-white">`
2. `data-controller="contact-form"` を `<form>` から親の `<div>` に移動
3. `<div data-contact-form-target="messageArea"></div>` を追加

**末尾も修正:**
```erb
        </div>
      </div>
    </div>
  </div>
</section>
```

`</div>` → `</section>` に変更

---

## 検証手順

1. デプロイ後、ブラウザでページをリロード（Cmd+Shift+R でキャッシュクリア）

2. 開発者ツール（F12）のコンソールで確認:
   ```javascript
   // Stimulus コントローラーが登録されているか確認
   Stimulus.application.router.modules.map(m => m.identifier)
   // ["confirm-dialog", "contact-form"] が表示されればOK
   ```

3. フォームに入力して送信
   - 送信中にボタンが「送信中...」に変わる
   - 成功メッセージが表示される
   - フォームがリセットされる
   - セクション上部にスクロールする

---

## 備考

この修正でフロントエンドの問題は解決する。

メール送信については別途 AWS SES の設定が必要（RESTORE_API_SES_INSTRUCTION.md を参照）。
