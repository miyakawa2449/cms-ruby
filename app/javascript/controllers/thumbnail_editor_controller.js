import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

// Connects to data-controller="thumbnail-editor"
export default class extends Controller {
  static targets = [
    "modal", 
    "cropperContainer", 
    "fileInput",
    "previewArticle",
    "previewOgp",
    "previewThumbnail",
    "saveBtn"
  ]
  
  static values = {
    aspectRatio: { type: String, default: "4:3" }
  }

  connect() {
    console.log("ThumbnailEditorController connected")
    this.cropper = null
  }

  disconnect() {
    this.destroyCropper()
  }

  // ファイル選択時
  selectFile(event) {
    const file = event.target.files[0]
    if (!file) return

    if (!file.type.startsWith('image/')) {
      alert('画像ファイルを選択してください')
      return
    }

    // モーダルを開いてトリミング開始
    this.openModal(file)
  }

  // モーダルを開く
  openModal(file) {
    const reader = new FileReader()
    
    reader.onload = (e) => {
      this.modalTarget.classList.remove("hidden")
      document.body.classList.add("overflow-hidden")
      this.initCropper(e.target.result)
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
    
    // 4:3のアスペクト比で初期化
    this.cropper = new Cropper(img, {
      viewMode: 1,
      dragMode: 'move',
      aspectRatio: 4 / 3,
      autoCropArea: 0.9,
      restore: false,
      guides: true,
      center: true,
      highlight: false,
      cropBoxMovable: true,
      cropBoxResizable: true,
      toggleDragModeOnDblclick: false,
      crop: () => {
        // 選択範囲が変更されたらプレビューを更新
        this.updatePreviews()
      },
      ready: () => {
        console.log("Cropper ready")
        this.updatePreviews()
      }
    })
  }

  // プレビューを更新
  updatePreviews() {
    if (!this.cropper) return

    try {
      // 記事表示用プレビュー（4:3そのまま）
      this.updateArticlePreview()
      
      // OGP用プレビュー（1.9:1に切り出し）
      this.updateOgpPreview()
      
      // サムネイル用プレビュー（縮小版）
      this.updateThumbnailPreview()
    } catch (error) {
      console.error("Preview update error:", error)
    }
  }

  // 記事表示用プレビュー（4:3）
  updateArticlePreview() {
    const canvas = this.cropper.getCroppedCanvas({
      width: 1200,
      height: 900,
      imageSmoothingEnabled: true,
      imageSmoothingQuality: 'high'
    })

    if (canvas && this.hasPreviewArticleTarget) {
      this.previewArticleTarget.src = canvas.toDataURL('image/jpeg', 0.9)
    }
  }

  // OGP用プレビュー（1.9:1 = 1200x630）
  updateOgpPreview() {
    const canvas = this.cropper.getCroppedCanvas({
      width: 1200,
      height: 900,
      imageSmoothingEnabled: true,
      imageSmoothingQuality: 'high'
    })

    if (!canvas || !this.hasPreviewOgpTarget) return

    // 4:3の画像から中央部分を1.9:1で切り出し
    const ogpCanvas = document.createElement('canvas')
    ogpCanvas.width = 1200
    ogpCanvas.height = 630
    
    const ctx = ogpCanvas.getContext('2d')
    
    // 中央から切り出し
    const sourceY = (900 - 630) / 2
    ctx.drawImage(
      canvas,
      0, sourceY, 1200, 630,  // source
      0, 0, 1200, 630          // destination
    )

    this.previewOgpTarget.src = ogpCanvas.toDataURL('image/jpeg', 0.9)
  }

  // サムネイル用プレビュー（600x450）
  updateThumbnailPreview() {
    const canvas = this.cropper.getCroppedCanvas({
      width: 600,
      height: 450,
      imageSmoothingEnabled: true,
      imageSmoothingQuality: 'high'
    })

    if (canvas && this.hasPreviewThumbnailTarget) {
      this.previewThumbnailTarget.src = canvas.toDataURL('image/jpeg', 0.9)
    }
  }

  // アスペクト比を変更
  changeAspectRatio(event) {
    const ratio = event.currentTarget.dataset.ratio
    
    // ボタンのアクティブ状態を更新
    document.querySelectorAll('[data-action*="thumbnail-editor#changeAspectRatio"]').forEach(btn => {
      btn.classList.remove("bg-blue-600", "text-white")
      btn.classList.add("bg-gray-200", "text-gray-700")
    })
    event.currentTarget.classList.remove("bg-gray-200", "text-gray-700")
    event.currentTarget.classList.add("bg-blue-600", "text-white")

    // アスペクト比を設定
    if (ratio === "4:3") {
      this.cropper.setAspectRatio(4 / 3)
    } else if (ratio === "3:2") {
      this.cropper.setAspectRatio(3 / 2)
    } else if (ratio === "16:9") {
      this.cropper.setAspectRatio(16 / 9)
    }
  }

  // 保存
  async save() {
    if (!this.cropper) return

    const saveBtn = this.saveBtnTarget
    const originalText = saveBtn.textContent
    saveBtn.disabled = true
    saveBtn.textContent = "保存中..."

    try {
      // 3つのサイズのBlobを生成
      const articleBlob = await this.getArticleBlob()
      const ogpBlob = await this.getOgpBlob()
      const thumbnailBlob = await this.getThumbnailBlob()

      // FormDataを作成
      const formData = new FormData()
      formData.append('thumbnail_image', articleBlob, 'thumbnail_article.jpg')
      formData.append('thumbnail_ogp', ogpBlob, 'thumbnail_ogp.jpg')
      formData.append('thumbnail_small', thumbnailBlob, 'thumbnail_small.jpg')

      // 元のフォームに画像を設定
      const originalInput = this.fileInputTarget
      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(new File([articleBlob], 'thumbnail.jpg', { type: 'image/jpeg' }))
      originalInput.files = dataTransfer.files

      // モーダルを閉じる
      this.close()
      
      this.showMessage('サムネイル画像を設定しました', 'success')
    } catch (error) {
      console.error("Save error:", error)
      this.showMessage(`エラー: ${error.message}`, 'error')
    } finally {
      saveBtn.disabled = false
      saveBtn.textContent = originalText
    }
  }

  // 記事表示用Blobを取得
  async getArticleBlob() {
    const canvas = this.cropper.getCroppedCanvas({
      width: 1200,
      height: 900,
      imageSmoothingEnabled: true,
      imageSmoothingQuality: 'high'
    })

    return new Promise((resolve, reject) => {
      canvas.toBlob(
        blob => blob ? resolve(blob) : reject(new Error("変換失敗")),
        'image/jpeg',
        0.92
      )
    })
  }

  // OGP用Blobを取得
  async getOgpBlob() {
    const canvas = this.cropper.getCroppedCanvas({
      width: 1200,
      height: 900,
      imageSmoothingEnabled: true,
      imageSmoothingQuality: 'high'
    })

    // 中央を切り出し
    const ogpCanvas = document.createElement('canvas')
    ogpCanvas.width = 1200
    ogpCanvas.height = 630
    
    const ctx = ogpCanvas.getContext('2d')
    const sourceY = (900 - 630) / 2
    ctx.drawImage(canvas, 0, sourceY, 1200, 630, 0, 0, 1200, 630)

    return new Promise((resolve, reject) => {
      ogpCanvas.toBlob(
        blob => blob ? resolve(blob) : reject(new Error("変換失敗")),
        'image/jpeg',
        0.92
      )
    })
  }

  // サムネイル用Blobを取得
  async getThumbnailBlob() {
    const canvas = this.cropper.getCroppedCanvas({
      width: 600,
      height: 450,
      imageSmoothingEnabled: true,
      imageSmoothingQuality: 'high'
    })

    return new Promise((resolve, reject) => {
      canvas.toBlob(
        blob => blob ? resolve(blob) : reject(new Error("変換失敗")),
        'image/jpeg',
        0.92
      )
    })
  }

  // モーダルを閉じる
  close() {
    this.destroyCropper()
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  // Cropperを破棄
  destroyCropper() {
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
  }

  // メッセージ表示
  showMessage(message, type = 'success') {
    const div = document.createElement("div")
    const bgColor = type === 'success' ? "bg-green-500" : "bg-red-500"
    div.className = `fixed top-4 right-4 px-6 py-3 rounded-md shadow-lg z-[100] ${bgColor} text-white`
    div.textContent = message
    
    document.body.appendChild(div)
    setTimeout(() => div.remove(), 3000)
  }
}
