import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="image-upload"
export default class extends Controller {
  static targets = ["input", "altText", "caption", "preview", "uploadButton", "insertButton"]
  static values = {
    articleId: Number,
    uploadUrl: String
  }

  connect() {
    console.log("Image upload controller connected")
  }

  // ファイル選択時のプレビュー表示
  previewImage(event) {
    const file = event.target.files[0]
    if (!file) return

    // 画像ファイルかチェック
    if (!file.type.startsWith('image/')) {
      alert('画像ファイルを選択してください')
      return
    }

    // プレビュー表示
    const reader = new FileReader()
    reader.onload = (e) => {
      if (this.hasPreviewTarget) {
        this.previewTarget.innerHTML = `
          <img src="${e.target.result}" class="max-w-full h-auto rounded-md shadow-sm" style="max-height: 200px;">
        `
        this.previewTarget.classList.remove('hidden')
      }
      
      // 挿入ボタンを有効化
      if (this.hasInsertButtonTarget) {
        this.insertButtonTarget.disabled = false
      }
    }
    reader.readAsDataURL(file)
  }

  // 画像アップロード＆Markdown挿入
  async uploadAndInsert(event) {
    event.preventDefault()
    
    const fileInput = this.inputTarget
    const file = fileInput.files[0]
    
    if (!file) {
      alert('画像ファイルを選択してください')
      return
    }

    const altText = this.hasAltTextTarget ? this.altTextTarget.value : file.name
    const caption = this.hasCaptionTarget ? this.captionTarget.value : ''

    // FormData作成
    const formData = new FormData()
    formData.append('image', file)
    formData.append('alt_text', altText)
    formData.append('caption', caption)
    
    // CSRF トークン取得
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    
    // ボタンを無効化してローディング表示
    const insertButton = this.insertButtonTarget
    const originalText = insertButton.textContent
    insertButton.disabled = true
    insertButton.textContent = 'アップロード中...'
    
    try {
      // アップロードリクエスト
      const response = await fetch(this.uploadUrlValue, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': csrfToken
        },
        body: formData
      })
      
      const data = await response.json()
      
      if (data.success) {
        // Markdownをテキストエリアに挿入
        this.insertMarkdown(data.markdown)
        
        // フォームをリセット
        this.resetForm()
        
        // 成功メッセージ
        this.showMessage('画像をアップロードしました', 'success')
      } else {
        throw new Error(data.error || 'アップロードに失敗しました')
      }
    } catch (error) {
      console.error('Upload error:', error)
      alert(`エラー: ${error.message}`)
    } finally {
      // ボタンを元に戻す
      insertButton.disabled = false
      insertButton.textContent = originalText
    }
  }

  // Markdownをテキストエリアに挿入
  insertMarkdown(markdown) {
    const contentTextarea = document.querySelector('#article_content')
    if (!contentTextarea) return
    
    const cursorPos = contentTextarea.selectionStart
    const textBefore = contentTextarea.value.substring(0, cursorPos)
    const textAfter = contentTextarea.value.substring(cursorPos)
    
    // カーソル位置にMarkdownを挿入（前後に改行を追加）
    contentTextarea.value = textBefore + '\n\n' + markdown + '\n\n' + textAfter
    
    // カーソル位置を調整
    const newCursorPos = cursorPos + markdown.length + 4
    contentTextarea.setSelectionRange(newCursorPos, newCursorPos)
    contentTextarea.focus()
  }

  // フォームリセット
  resetForm() {
    if (this.hasInputTarget) {
      this.inputTarget.value = ''
    }
    if (this.hasAltTextTarget) {
      this.altTextTarget.value = ''
    }
    if (this.hasCaptionTarget) {
      this.captionTarget.value = ''
    }
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = ''
      this.previewTarget.classList.add('hidden')
    }
    if (this.hasInsertButtonTarget) {
      this.insertButtonTarget.disabled = true
    }
  }

  // メッセージ表示
  showMessage(message, type = 'success') {
    const messageDiv = document.createElement('div')
    messageDiv.className = `fixed top-4 right-4 px-6 py-3 rounded-md shadow-lg z-50 ${
      type === 'success' ? 'bg-green-500 text-white' : 'bg-red-500 text-white'
    }`
    messageDiv.textContent = message
    
    document.body.appendChild(messageDiv)
    
    setTimeout(() => {
      messageDiv.remove()
    }, 3000)
  }
}
