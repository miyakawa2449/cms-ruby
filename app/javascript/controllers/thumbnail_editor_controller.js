import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

// Connects to data-controller="thumbnail-editor"
//
// サムネイル/OGP画像のトリミング。
// 「編集エリアの選択範囲」がそのまま保存画像になる（サムネイル=OGP画像の設計）。
// 旧実装は4:3(1200x900)キャンバス前提の中央切り出しをしており、
// 1.91:1選択と前提がずれて保存画像の位置ずれ・黒帯が発生していた（2026-07-17修正）
export default class extends Controller {
  static targets = [
    "modal",
    "cropperContainer",
    "fileInput",
    "ogpInput",
    "preview",
    "saveBtn"
  ]

  static values = {
    // デフォルトはOGP標準比率（1200x630）。サムネイル=OGP画像として使えるようにする
    aspectRatio: { type: String, default: "1.91:1" }
  }

  // 保存画像の横幅（高さは選択範囲の比率に従う）
  static OUTPUT_WIDTH = 1200

  connect() {
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

    // OGP標準比率（1200x630 = 1.91:1）で初期化
    this.cropper = new Cropper(img, {
      viewMode: 1,
      dragMode: 'move',
      aspectRatio: 1200 / 630,
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
        this.updatePreview()
      },
      ready: () => {
        this.updatePreview()
      }
    })
  }

  // 選択範囲をそのまま切り出したキャンバスを返す（サイズ強制しない＝位置ずれの再発防止）
  croppedCanvas() {
    return this.cropper.getCroppedCanvas({
      maxWidth: 2400,
      maxHeight: 2400,
      imageSmoothingEnabled: true,
      imageSmoothingQuality: 'high'
    })
  }

  // 指定幅に縮小したキャンバスを返す（比率は選択範囲のまま）
  scaledCanvas(source, targetWidth) {
    const scale = targetWidth / source.width
    const canvas = document.createElement('canvas')
    canvas.width = targetWidth
    canvas.height = Math.round(source.height * scale)

    const ctx = canvas.getContext('2d')
    ctx.imageSmoothingEnabled = true
    ctx.imageSmoothingQuality = 'high'
    ctx.drawImage(source, 0, 0, canvas.width, canvas.height)
    return canvas
  }

  // プレビューを更新（保存されるのは選択範囲そのものなのでプレビューは1つ）
  updatePreview() {
    if (!this.cropper || !this.hasPreviewTarget) return

    try {
      const canvas = this.croppedCanvas()
      if (canvas) {
        this.previewTarget.src = canvas.toDataURL('image/jpeg', 0.9)
      }
    } catch (error) {
      console.error("Preview update error:", error)
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
    if (ratio === "1.91:1") {
      this.cropper.setAspectRatio(1200 / 630)
    } else if (ratio === "16:9") {
      this.cropper.setAspectRatio(16 / 9)
    } else if (ratio === "4:3") {
      this.cropper.setAspectRatio(4 / 3)
    }
  }

  // 保存: 選択範囲を1200px幅に整えて、サムネイルとOGPの両フィールドに設定する
  async save() {
    if (!this.cropper) return

    const saveBtn = this.saveBtnTarget
    const originalText = saveBtn.textContent
    saveBtn.disabled = true
    saveBtn.textContent = "保存中..."

    try {
      const output = this.scaledCanvas(this.croppedCanvas(), this.constructor.OUTPUT_WIDTH)
      const blob = await new Promise((resolve, reject) => {
        output.toBlob(
          b => b ? resolve(b) : reject(new Error("変換失敗")),
          'image/jpeg',
          0.92
        )
      })

      // 元のフォームに画像を設定（サムネイル=OGP画像。同じ切り抜きを両方に使う）
      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(new File([blob], 'thumbnail.jpg', { type: 'image/jpeg' }))
      this.fileInputTarget.files = dataTransfer.files

      if (this.hasOgpInputTarget) {
        const ogpTransfer = new DataTransfer()
        ogpTransfer.items.add(new File([blob], 'thumbnail_ogp.jpg', { type: 'image/jpeg' }))
        this.ogpInputTarget.files = ogpTransfer.files
      }

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
