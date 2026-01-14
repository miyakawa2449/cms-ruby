# Cropper.js v2 実装調査レポート

## 📅 調査日時
2025年12月31日

## 🎯 調査目的
Cropper.js v2のWeb Components APIを正しく理解し、画像編集機能を実装する

---

## 🔍 発見した問題

### 1. 画像が上に偏っている
**原因**: 初期化時に`$center()`を呼んでいない
**解決**: `img.onload`内で`image.$center('contain')`を呼ぶ

### 2. 回転角度が90度ではない
**原因**: `$rotate()`は相対回転（累積）
**現在の実装**: `image.$rotate(90)` - 毎回+90度追加される
**問題**: 回転状態を追跡していないため、予期しない角度になる

### 3. 反転が機能しない
**原因**: `$scale()`の使い方が間違っている
**現在の実装**: `image.$scale(-image.scaleX, image.scaleY)`
**問題**: `image.scaleX`はプロパティではなく、`$getTransform()`で取得する必要がある

### 4. アスペクト比の動作が変
**原因**: プロパティの設定タイミングが間違っている
**問題**: Cropperインスタンス作成後すぐに設定しようとしている

---

## 📚 Cropper.js v2 API仕様

### CropperImage メソッド

| メソッド | 説明 | 使用例 |
|---------|------|--------|
| `$center(size)` | 画像を中央に配置 | `image.$center('contain')` |
| `$rotate(angle)` | 相対回転（度） | `image.$rotate(90)` |
| `$scale(x, y)` | スケール設定 | `image.$scale(-1, 1)` |
| `$getTransform()` | 現在の変換行列を取得 | `const matrix = image.$getTransform()` |
| `$setTransform(matrix)` | 変換行列を設定 | `image.$setTransform([1,0,0,1,0,0])` |

### CropperSelection プロパティ

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `aspectRatio` | number | アスペクト比（直接代入） |
| `x`, `y` | number | 位置 |
| `width`, `height` | number | サイズ |

### 重要な注意点

1. **Web Components**: `<cropper-canvas>`, `<cropper-image>`, `<cropper-selection>`が自動生成される
2. **非同期初期化**: 画像読み込み後にCropperが初期化される
3. **プロパティアクセス**: DOMプロパティとして直接アクセス可能
4. **メソッド呼び出し**: `$`プレフィックス付きメソッドを使用

---

## 🛠️ 修正方針

### 1. 初期化の改善
```javascript
img.onload = () => {
  this.cropper = new Cropper(img, {
    container: this.cropperContainerTarget
  })
  
  // 画像を中央に配置
  setTimeout(() => {
    const image = this.cropper.getCropperImage()
    if (image) {
      image.$center('contain')
    }
  }, 100)
}
```

### 2. 回転の修正
```javascript
// 回転状態を追跡
this.currentRotation = 0

rotateLeft() {
  const image = this.cropper.getCropperImage()
  if (image) {
    this.currentRotation -= 90
    // 絶対角度で設定
    image.$setTransform({
      rotate: this.currentRotation
    })
  }
}
```

### 3. 反転の修正
```javascript
flipHorizontal() {
  const image = this.cropper.getCropperImage()
  if (image) {
    const transform = image.$getTransform()
    const currentScaleX = transform.a // matrix[0]
    image.$scale(-currentScaleX, transform.d)
  }
}
```

### 4. アスペクト比の修正
```javascript
setAspectRatio(event) {
  const ratio = event.currentTarget.dataset.ratio
  
  // ボタンスタイル更新
  this.updateButtonStyles(event.currentTarget)
  
  // 少し待ってから設定
  setTimeout(() => {
    const selection = this.cropper.getCropperSelection()
    if (selection) {
      if (ratio === 'free') {
        selection.aspectRatio = NaN
      } else {
        const [w, h] = ratio.split(':').map(Number)
        selection.aspectRatio = w / h
      }
    }
  }, 50)
}
```

---

## 📊 推奨される実装

### 完全な修正版コントローラー

次のステップで実装します：

1. 回転状態の追跡変数を追加
2. スケール状態の追跡変数を追加
3. 初期化時に`$center()`を呼ぶ
4. 各メソッドで状態を正しく管理
5. `$getTransform()`と`$setTransform()`を使用

---

## 🎯 期待される動作

修正後：
- ✅ 画像が中央に表示される
- ✅ 回転が正確に90度ずつ回る
- ✅ 反転が正しく動作する
- ✅ アスペクト比が正しく適用される
- ✅ リセットで初期状態に戻る

---

**調査者**: Kiro (AI Assistant)
**次のアクション**: 修正版コントローラーの実装
