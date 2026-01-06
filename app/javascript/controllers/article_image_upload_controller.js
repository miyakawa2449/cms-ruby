import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="article-image-upload"
export default class extends Controller {
  static targets = ["fileInput", "altInput", "uploadButton", "status", "contentArea"]
  static values = {
    articleId: Number,
    uploadUrl: String
  }

  connect() {
    console.log("Article image upload controller connected")
  }

  // ファイル選択時の処理
  fileSelected() {
    const file = this.fileInputTarget.files[0]
    if (file) {
      this.statusTarget.textContent = `選択: ${file.name}`
      this.statusTarget.className = "text-sm text-blue-600 mt-2"
      this.uploadButtonTarget.disabled = false
    }
  }

  // アップロード処理
  async upload(event) {
    event.preventDefault()
    
    const file = this.fileInputTarget.files[0]
    if (!file) {
      this.showError("画像ファイルを選択してください")
      return
    }

    // alt属性の取得（未入力の場合はファイル名）
    const altText = this.altInputTarget.value.trim() || file.name

    // FormDataの作成
    const formData = new FormData()
    formData.append("image", file)
    formData.append("alt_text", altText)

    // CSRFトークンの取得
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    try {
      // アップロード中の表示
      this.uploadButtonTarget.disabled = true
      this.statusTarget.textContent = "アップロード中..."
      this.statusTarget.className = "text-sm text-blue-600 mt-2"

      // APIリクエスト
      const response = await fetch(this.uploadUrlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken
        },
        body: formData
      })

      const data = await response.json()

      if (data.success) {
        // Markdownをテキストエリアに挿入
        this.insertMarkdown(data.markdown)
        
        // 成功メッセージ
        this.showSuccess(`画像をアップロードしました: ${data.filename}`)
        
        // フォームをリセット
        this.reset()
      } else {
        this.showError(data.error || "アップロードに失敗しました")
      }
    } catch (error) {
      console.error("Upload error:", error)
      this.showError("アップロード中にエラーが発生しました")
    } finally {
      this.uploadButtonTarget.disabled = false
    }
  }

  // Markdownをテキストエリアに挿入
  insertMarkdown(markdown) {
    const textarea = this.contentAreaTarget
    const cursorPos = textarea.selectionStart
    const textBefore = textarea.value.substring(0, cursorPos)
    const textAfter = textarea.value.substring(cursorPos)
    
    // カーソル位置にMarkdownを挿入（前後に改行を追加）
    const newText = textBefore + "\n\n" + markdown + "\n\n" + textAfter
    textarea.value = newText
    
    // カーソル位置を挿入後の位置に移動
    const newCursorPos = cursorPos + markdown.length + 4
    textarea.setSelectionRange(newCursorPos, newCursorPos)
    textarea.focus()
  }

  // フォームリセット
  reset() {
    this.fileInputTarget.value = ""
    this.altInputTarget.value = ""
    this.uploadButtonTarget.disabled = true
    this.statusTarget.textContent = ""
  }

  // 成功メッセージ表示
  showSuccess(message) {
    this.statusTarget.textContent = message
    this.statusTarget.className = "text-sm text-green-600 mt-2"
    
    // 3秒後にメッセージをクリア
    setTimeout(() => {
      this.statusTarget.textContent = ""
    }, 3000)
  }

  // エラーメッセージ表示
  showError(message) {
    this.statusTarget.textContent = message
    this.statusTarget.className = "text-sm text-red-600 mt-2"
  }
}
