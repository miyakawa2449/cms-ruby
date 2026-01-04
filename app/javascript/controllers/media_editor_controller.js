import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

// Connects to data-controller="media-editor"
export default class extends Controller {
  static targets = ["modal", "cropperContainer", "aspectRatio", "saveBtn"]
  static values = { 
    mediaId: Number, 
    editUrl: String 
  }

  connect() {
    console.log("MediaEditorController connected")
    this.cropper = null
  }

  disconnect() {
    this.destroyCropper()
  }

  // モーダルを開く
  open(event) {
    const imageUrl = event.currentTarget.dataset.imageUrl
    this.mediaIdValue = parseInt(event.currentTarget.dataset.mediaId)
    
    console.log("MediaEditorController open called", { imageUrl, mediaId: this.mediaIdValue })
    
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    
    this.initCropper(imageUrl)
  }

  // モーダルを閉じる
  close() {
    this.destroyCropper()
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  // Cropper.js v1の初期化
  initCropper(imageUrl) {
    this.destroyCropper()
    
    // 画像要素を作成
    const img = document.createElement("img")
    img.src = imageUrl
    img.style.maxWidth = "100%"
    img.style.display = "block"
    
    // コンテナをクリア
    this.cropperContainerTarget.innerHTML = ""
    this.cropperContainerTarget.appendChild(img)
    
    // Cropper.js v1の初期化
    this.cropper = new Cropper(img, {
      viewMode: 1,
      dragMode: 'move',
      aspectRatio: NaN,
      autoCropArea: 0.8,
      restore: false,
      guides: true,
      center: true,
      highlight: false,
      cropBoxMovable: true,
      cropBoxResizable: true,
      toggleDragModeOnDblclick: false,
      ready: () => {
        console.log("Cropper ready")
      }
    })
  }

  // Cropperを破棄
  destroyCropper() {
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
  }

  // アスペクト比を設定
  setAspectRatio(event) {
    if (!this.cropper) return
    
    const ratio = event.currentTarget.dataset.ratio
    
    // ボタンのアクティブ状態を更新
    this.aspectRatioTargets.forEach(btn => {
      btn.classList.remove("bg-blue-600", "text-white")
      btn.classList.add("bg-gray-200", "text-gray-700")
    })
    event.currentTarget.classList.remove("bg-gray-200", "text-gray-700")
    event.currentTarget.classList.add("bg-blue-600", "text-white")

    // アスペクト比を設定
    if (ratio === "free") {
      this.cropper.setAspectRatio(NaN)
    } else {
      // "16:9" -> 16/9
      const [width, height] = ratio.split(":").map(Number)
      this.cropper.setAspectRatio(width / height)
    }
  }

  // 左回転
  rotateLeft() {
    if (!this.cropper) return
    this.cropper.rotate(-90)
  }

  // 右回転
  rotateRight() {
    if (!this.cropper) return
    this.cropper.rotate(90)
  }

  // 水平反転
  flipHorizontal() {
    if (!this.cropper) return
    const data = this.cropper.getData()
    this.cropper.scaleX(-data.scaleX || -1)
  }

  // 垂直反転
  flipVertical() {
    if (!this.cropper) return
    const data = this.cropper.getData()
    this.cropper.scaleY(-data.scaleY || -1)
  }

  // リセット
  reset() {
    if (!this.cropper) return
    this.cropper.reset()
  }

  // 保存
  async save(event) {
    if (!this.cropper) {
      this.showMessage("エディターが初期化されていません", "error")
      return
    }

    const saveAsNew = event.currentTarget.dataset.saveAsNew === "true"
    const button = event.currentTarget
    const originalText = button.textContent
    
    button.disabled = true
    button.textContent = "保存中..."

    try {
      // Cropper.js v1: getCroppedCanvas()を使用
      const canvas = this.cropper.getCroppedCanvas({
        maxWidth: 4096,
        maxHeight: 4096,
        imageSmoothingEnabled: true,
        imageSmoothingQuality: 'high'
      })

      if (!canvas) {
        throw new Error("画像の処理に失敗しました")
      }

      // CanvasをBlobに変換
      const blob = await new Promise((resolve, reject) => {
        canvas.toBlob(
          blob => blob ? resolve(blob) : reject(new Error("画像の変換に失敗しました")),
          "image/jpeg",
          0.92
        )
      })

      // FormDataを作成
      const formData = new FormData()
      formData.append("image", blob, "edited_image.jpg")
      formData.append("save_as_new", saveAsNew)

      // サーバーに送信
      const response = await fetch(this.editUrlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: formData
      })

      const data = await response.json()

      if (data.success) {
        this.showMessage(data.data.message || "画像を保存しました", "success")
        this.close()
        
        // メディアライブラリ一覧ページに戻る
        setTimeout(() => {
          window.location.href = '/admin-secure-panel-miyakawa2449/media'
        }, 1000)
      } else {
        throw new Error(data.error || "保存に失敗しました")
      }
    } catch (error) {
      console.error("Save error:", error)
      this.showMessage(`エラー: ${error.message}`, "error")
    } finally {
      button.disabled = false
      button.textContent = originalText
    }
  }

  // メッセージ表示
  showMessage(message, type = "success") {
    const div = document.createElement("div")
    const bgColor = type === "success" ? "bg-green-500" : "bg-red-500"
    div.className = `fixed top-4 right-4 px-6 py-3 rounded-md shadow-lg z-[100] ${bgColor} text-white`
    div.textContent = message
    
    document.body.appendChild(div)
    
    setTimeout(() => div.remove(), 3000)
  }
}
