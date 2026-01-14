import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

// Connects to data-controller="content-image-editor"
// 本文内画像のトリミング機能（800x600px、4:3固定）
export default class extends Controller {
  static targets = [
    "modal",
    "cropperContainer",
    "fileInput",
    "preview",
    "altInput",
    "captionInput",
    "saveBtn",
    "errorMessage"
  ]

  static values = {
    uploadUrl: String,
    articleId: String
  }

  // 出力サイズ（固定）- インスタンスで参照可能な形式で定義
  OUTPUT_WIDTH = 800
  OUTPUT_HEIGHT = 600
  ASPECT_RATIO = 4 / 3
  MAX_FILE_SIZE = 10 * 1024 * 1024  // 10MB
  ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']

  connect() {
    console.log("ContentImageEditorController connected")
    this.cropper = null
    this.currentFile = null
    this.previewUpdateTimer = null

    // ESCキーでモーダルを閉じる
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundHandleKeydown)
  }

  disconnect() {
    this.destroyCropper()
    document.removeEventListener('keydown', this.boundHandleKeydown)
    if (this.previewUpdateTimer) {
      clearTimeout(this.previewUpdateTimer)
    }
  }

  // ESCキーハンドラー
  handleKeydown(event) {
    if (event.key === 'Escape' && this.hasModalTarget && !this.modalTarget.classList.contains('hidden')) {
      this.close()
    }
  }

  // ファイル選択ダイアログを開く
  openFileDialog() {
    this.fileInputTarget.click()
  }

  // ファイル選択時
  selectFile(event) {
    const file = event.target.files[0]
    if (!file) return

    // ファイル形式チェック
    if (!this.ALLOWED_TYPES.includes(file.type)) {
      this.showError('対応していないファイル形式です。JPEG, PNG, GIF, WebPを選択してください。')
      this.resetFileInput()
      return
    }

    // ファイルサイズチェック
    if (file.size > this.MAX_FILE_SIZE) {
      this.showError('ファイルサイズは10MB以下にしてください。')
      this.resetFileInput()
      return
    }

    this.currentFile = file
    this.openModal(file)
  }

  // モーダルを開く
  openModal(file) {
    const reader = new FileReader()

    reader.onload = (e) => {
      this.modalTarget.classList.remove("hidden")
      document.body.classList.add("overflow-hidden")
      this.initCropper(e.target.result)
      this.clearError()

      // alt入力をクリア
      if (this.hasAltInputTarget) {
        this.altInputTarget.value = ''
      }
      if (this.hasCaptionInputTarget) {
        this.captionInputTarget.value = ''
      }
    }

    reader.onerror = () => {
      this.showError('画像の読み込みに失敗しました。')
    }

    reader.readAsDataURL(file)
  }

  // Cropperを初期化
  initCropper(imageUrl) {
    this.destroyCropper()

    const img = document.createElement("img")
    img.src = imageUrl
    img.style.maxWidth = "100%"
    img.style.display = "block"

    this.cropperContainerTarget.innerHTML = ""
    this.cropperContainerTarget.appendChild(img)

    // 4:3のアスペクト比で初期化（固定）
    this.cropper = new Cropper(img, {
      viewMode: 1,
      dragMode: 'move',
      aspectRatio: this.ASPECT_RATIO,  // 4:3固定
      autoCropArea: 0.9,
      restore: false,
      guides: true,
      center: true,
      highlight: false,
      cropBoxMovable: true,
      cropBoxResizable: true,
      toggleDragModeOnDblclick: false,
      crop: () => {
        // デバウンスでパフォーマンス改善
        this.debouncedUpdatePreview()
      },
      ready: () => {
        console.log("Cropper ready")
        this.updatePreview()
      }
    })
  }

  // デバウンス付きプレビュー更新
  debouncedUpdatePreview() {
    if (this.previewUpdateTimer) {
      clearTimeout(this.previewUpdateTimer)
    }
    this.previewUpdateTimer = setTimeout(() => {
      this.updatePreview()
    }, 100)
  }

  // プレビューを更新
  updatePreview() {
    if (!this.cropper || !this.hasPreviewTarget) return

    try {
      const canvas = this.cropper.getCroppedCanvas({
        width: this.OUTPUT_WIDTH,
        height: this.OUTPUT_HEIGHT,
        imageSmoothingEnabled: true,
        imageSmoothingQuality: 'high'
      })

      if (canvas) {
        this.previewTarget.src = canvas.toDataURL('image/jpeg', 0.9)
        this.previewTarget.style.display = 'block'
        // プレースホルダーを非表示
        const placeholder = this.previewTarget.parentElement.querySelector('.preview-placeholder')
        if (placeholder) {
          placeholder.style.display = 'none'
        }
      }
    } catch (error) {
      console.error("Preview update error:", error)
    }
  }

  // 保存処理
  async save() {
    // バリデーション
    if (!this.hasAltInputTarget || !this.altInputTarget.value.trim()) {
      this.showError('alt属性（画像の説明）は必須です。')
      this.altInputTarget.focus()
      return
    }

    if (!this.cropper) {
      this.showError('画像が読み込まれていません。')
      return
    }

    const saveBtn = this.saveBtnTarget
    const originalText = saveBtn.textContent
    saveBtn.disabled = true
    saveBtn.textContent = "アップロード中..."

    try {
      // 800x600pxのBlobを生成
      const blob = await this.getImageBlob()

      // サーバーにアップロード
      const altText = this.altInputTarget.value.trim()
      const caption = this.hasCaptionInputTarget ? this.captionInputTarget.value.trim() : ''

      const result = await this.uploadImage(blob, altText, caption)

      if (result.success) {
        // Markdownをエディタに挿入
        this.insertMarkdown(result.markdown)

        // モーダルを閉じる
        this.close()

        this.showMessage('画像をアップロードして本文に挿入しました', 'success')
      } else {
        this.showError(result.error || 'アップロードに失敗しました')
      }
    } catch (error) {
      console.error("Save error:", error)
      this.showError(`エラー: ${error.message}`)
    } finally {
      saveBtn.disabled = false
      saveBtn.textContent = originalText
    }
  }

  // 800x600pxのBlobを取得
  async getImageBlob() {
    const canvas = this.cropper.getCroppedCanvas({
      width: this.OUTPUT_WIDTH,
      height: this.OUTPUT_HEIGHT,
      imageSmoothingEnabled: true,
      imageSmoothingQuality: 'high'
    })

    return new Promise((resolve, reject) => {
      canvas.toBlob(
        blob => blob ? resolve(blob) : reject(new Error("画像の変換に失敗しました")),
        'image/jpeg',
        0.92
      )
    })
  }

  // サーバーにアップロード
  async uploadImage(blob, altText, caption) {
    const formData = new FormData()
    formData.append('image', blob, 'content_image.jpg')
    formData.append('alt_text', altText)
    if (caption) {
      formData.append('caption', caption)
    }

    const csrfToken = document.querySelector('[name="csrf-token"]')?.content

    const response = await fetch(this.uploadUrlValue, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken
      },
      body: formData
    })

    if (!response.ok) {
      const data = await response.json()
      throw new Error(data.error || 'アップロードに失敗しました')
    }

    return await response.json()
  }

  // Markdownをエディタに挿入
  insertMarkdown(markdown) {
    const editor = document.getElementById('article_content')
    if (!editor) {
      console.error("Editor not found")
      return
    }

    // カーソル位置に挿入
    const start = editor.selectionStart
    const end = editor.selectionEnd
    const text = editor.value

    // 前後に改行を追加（見やすさのため）
    const insertText = '\n\n' + markdown + '\n\n'

    editor.value = text.substring(0, start) + insertText + text.substring(end)

    // カーソルを挿入テキストの後ろに移動
    const newPosition = start + insertText.length
    editor.setSelectionRange(newPosition, newPosition)
    editor.focus()

    // 変更イベントを発火（Turboなど用）
    editor.dispatchEvent(new Event('input', { bubbles: true }))
  }

  // モーダルを閉じる
  close() {
    this.destroyCropper()
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    this.resetFileInput()
    this.clearError()
    this.resetPreview()
  }

  // プレビューをリセット
  resetPreview() {
    if (this.hasPreviewTarget) {
      this.previewTarget.src = ''
      this.previewTarget.style.display = 'none'
      const placeholder = this.previewTarget.parentElement?.querySelector('.preview-placeholder')
      if (placeholder) {
        placeholder.style.display = 'block'
      }
    }
  }

  // Cropperを破棄
  destroyCropper() {
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
    this.currentFile = null
  }

  // ファイル入力をリセット
  resetFileInput() {
    if (this.hasFileInputTarget) {
      this.fileInputTarget.value = ''
    }
  }

  // エラーメッセージ表示
  showError(message) {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message
      this.errorMessageTarget.classList.remove('hidden')
    } else {
      // フォールバック: アラート表示
      alert(message)
    }
  }

  // エラーメッセージクリア
  clearError() {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = ''
      this.errorMessageTarget.classList.add('hidden')
    }
  }

  // トースト通知表示
  showMessage(message, type = 'success') {
    const div = document.createElement("div")
    const bgColor = type === 'success' ? "bg-green-500" : "bg-red-500"
    div.className = `fixed top-4 right-4 px-6 py-3 rounded-md shadow-lg z-[100] ${bgColor} text-white`
    div.textContent = message

    document.body.appendChild(div)
    setTimeout(() => div.remove(), 3000)
  }
}
