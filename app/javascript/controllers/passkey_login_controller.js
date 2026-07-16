import { Controller } from "@hotwired/stimulus"

// パスキーログイン（S1-6）
// メール・パスワード入力なしで、デバイスの生体認証だけでログインする
export default class extends Controller {
  static targets = ["error"]
  static values = { optionsUrl: String, loginUrl: String }

  connect() {
    // パスキー非対応ブラウザではボタンごと隠す
    if (!window.PublicKeyCredential) {
      this.element.classList.add("hidden")
    }
  }

  async login() {
    this.hideError()

    try {
      const options = await this.fetchOptions()
      const assertion = await navigator.credentials.get({
        publicKey: {
          ...options,
          challenge: this.base64urlToBuffer(options.challenge),
          allowCredentials: (options.allowCredentials || []).map((c) => ({
            ...c,
            id: this.base64urlToBuffer(c.id)
          }))
        }
      })
      const result = await this.submitAssertion(assertion)
      window.location.href = result.redirect_url
    } catch (error) {
      if (error.name === "NotAllowedError") {
        this.showError("キャンセルされました")
      } else {
        this.showError(error.message || "パスキー認証に失敗しました")
      }
    }
  }

  async fetchOptions() {
    const response = await fetch(this.optionsUrlValue, {
      method: "POST",
      headers: this.jsonHeaders()
    })
    const json = await response.json()
    if (!response.ok) throw new Error(json.error)
    return json
  }

  async submitAssertion(assertion) {
    const response = await fetch(this.loginUrlValue, {
      method: "POST",
      headers: this.jsonHeaders(),
      body: JSON.stringify({ credential: this.encodeAssertion(assertion) })
    })
    const json = await response.json()
    if (!response.ok) throw new Error(json.error)
    return json
  }

  encodeAssertion(assertion) {
    return {
      id: assertion.id,
      rawId: this.bufferToBase64url(assertion.rawId),
      type: assertion.type,
      response: {
        clientDataJSON: this.bufferToBase64url(assertion.response.clientDataJSON),
        authenticatorData: this.bufferToBase64url(assertion.response.authenticatorData),
        signature: this.bufferToBase64url(assertion.response.signature),
        userHandle: assertion.response.userHandle
          ? this.bufferToBase64url(assertion.response.userHandle)
          : null
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
