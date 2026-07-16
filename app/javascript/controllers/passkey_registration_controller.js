import { Controller } from "@hotwired/stimulus"

// パスキー登録（S1-6）
// 1. サーバーからチャレンジを取得（パスワード再確認付き）
// 2. ブラウザのWebAuthn API（navigator.credentials.create）でパスキー生成
// 3. 生成された公開鍵をサーバーに送って検証・保存
export default class extends Controller {
  static targets = ["nickname", "password", "error"]
  static values = { optionsUrl: String, createUrl: String }

  async register() {
    this.hideError()

    if (!window.PublicKeyCredential) {
      this.showError("このブラウザはパスキーに対応していません")
      return
    }

    try {
      const options = await this.fetchOptions()
      const credential = await navigator.credentials.create({
        publicKey: this.decodeOptions(options)
      })
      await this.submitCredential(credential)
      window.location.reload()
    } catch (error) {
      if (error.name === "NotAllowedError") {
        this.showError("キャンセルされました。もう一度お試しください")
      } else if (error.name === "InvalidStateError") {
        // 同じ保管庫（例: iCloudキーチェーン）に登録済みの場合。二重登録防止が働いた状態
        this.showError(
          "この保存先には既にこのサイトのパスキーが登録されています。" +
          "ダイアログで保存先を変更してください（例: iCloudキーチェーン済みなら「Chromeプロファイル/Googleパスワードマネージャー」を選択）"
        )
      } else {
        this.showError(error.message || "登録に失敗しました")
      }
    }
  }

  async fetchOptions() {
    const response = await fetch(this.optionsUrlValue, {
      method: "POST",
      headers: this.jsonHeaders(),
      body: JSON.stringify({ current_password: this.passwordTarget.value })
    })
    const json = await response.json()
    if (!response.ok) throw new Error(json.error)
    return json
  }

  async submitCredential(credential) {
    const response = await fetch(this.createUrlValue, {
      method: "POST",
      headers: this.jsonHeaders(),
      body: JSON.stringify({
        nickname: this.nicknameTarget.value,
        credential: this.encodeCredential(credential)
      })
    })
    const json = await response.json()
    if (!response.ok) throw new Error(json.error)
    return json
  }

  // --- WebAuthnのバイナリ⇔base64url変換 ---

  decodeOptions(options) {
    return {
      ...options,
      challenge: this.base64urlToBuffer(options.challenge),
      user: { ...options.user, id: this.base64urlToBuffer(options.user.id) },
      excludeCredentials: (options.excludeCredentials || []).map((c) => ({
        ...c,
        id: this.base64urlToBuffer(c.id)
      }))
    }
  }

  encodeCredential(credential) {
    return {
      id: credential.id,
      rawId: this.bufferToBase64url(credential.rawId),
      type: credential.type,
      response: {
        clientDataJSON: this.bufferToBase64url(credential.response.clientDataJSON),
        attestationObject: this.bufferToBase64url(credential.response.attestationObject)
      }
    }
  }

  base64urlToBuffer(base64url) {
    const base64 = base64url.replace(/-/g, "+").replace(/_/g, "/")
    const binary = atob(base64)
    return Uint8Array.from(binary, (c) => c.charCodeAt(0)).buffer
  }

  bufferToBase64url(buffer) {
    const binary = String.fromCharCode(...new Uint8Array(buffer))
    return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")
  }

  jsonHeaders() {
    return {
      "Content-Type": "application/json",
      "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
    }
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorTarget.classList.add("hidden")
  }
}
