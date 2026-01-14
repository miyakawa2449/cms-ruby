# Claude Code 指示書: My Story フォームのStimulusコントローラー化

## 問題
セクションタイプ（第1章〜第3章など）を選択しても、章専用フィールドが即座に表示されない。リロードすると表示される。

## 原因
インラインJSが `DOMContentLoaded` のみを使っており、Rails 7のTurbo Driveに非対応。

## 解決策
インラインJSをStimulusコントローラーに置き換える（プロジェクトの既存パターンに合わせる）。

---

## 修正1: Stimulusコントローラー新規作成

**ファイル**: `app/javascript/controllers/my_story_form_controller.js`（新規作成）

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sectionType", "chapterFields", "dynamicFields"]

  connect() {
    this.updateFields()
  }

  updateFields() {
    const selectedType = this.sectionTypeTarget.value
    
    // 章専用フィールドの表示制御
    if (this.hasChapterFieldsTarget) {
      if (['chapter_1', 'chapter_2', 'chapter_3'].includes(selectedType)) {
        this.chapterFieldsTarget.style.display = 'block'
      } else {
        this.chapterFieldsTarget.style.display = 'none'
      }
    }
    
    // 動的フィールドの更新
    if (this.hasDynamicFieldsTarget) {
      this.dynamicFieldsTarget.innerHTML = this.generateDynamicFields(selectedType)
    }
  }

  generateDynamicFields(selectedType) {
    if (!selectedType) {
      return '<p class="text-sm text-gray-500 italic">セクションタイプを選択すると、対応する追加フィールドが表示されます。</p>'
    }

    switch (selectedType) {
      case 'timeline':
        return `
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700">タイムライン年代</label>
              <input type="text" placeholder="例: 1994, 2005, 2022" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm">
              <p class="mt-1 text-xs text-gray-500">カンマ区切りで年代を入力</p>
            </div>
          </div>
        `

      case 'chapter_1':
      case 'chapter_2':
      case 'chapter_3':
        return '<p class="text-sm text-gray-500 italic">章の詳細情報は上記の専用フィールドで入力してください。</p>'

      case 'projects':
        return `
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700">プロジェクト一覧（JSON形式）</label>
              <textarea rows="6" placeholder='[{"title": "プロジェクト名", "description": "説明", "period": "期間", "scale": "規模", "technologies": ["技術1", "技術2"]}]' class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm font-mono"></textarea>
              <p class="mt-1 text-xs text-gray-500">プロジェクト情報をJSON配列で入力</p>
            </div>
          </div>
        `

      case 'cta':
        return `
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700">CTAボタン設定（JSON形式）</label>
              <textarea rows="4" placeholder='[{"text": "ボタンテキスト", "url": "リンク先URL", "style": "primary"}]' class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm font-mono"></textarea>
              <p class="mt-1 text-xs text-gray-500">CTAボタン情報をJSON配列で入力</p>
            </div>
          </div>
        `

      default:
        return '<p class="text-sm text-gray-500 italic">このセクションタイプには追加設定項目はありません。</p>'
    }
  }
}
```

---

## 修正2: コントローラーを登録

**ファイル**: `app/javascript/controllers/index.js`

```diff
  import { application } from "./application"
  import ConfirmDialogController from "./confirm_dialog_controller"
  import ContactFormController from "./contact_form_controller"
+ import MyStoryFormController from "./my_story_form_controller"

  application.register("confirm-dialog", ConfirmDialogController)
  application.register("contact-form", ContactFormController)
+ application.register("my-story-form", MyStoryFormController)
```

---

## 修正3: ビューをStimulusコントローラーに接続

**ファイル**: `app/views/admin/my_story_sections/_form.html.erb`

### 3-1: フォームタグに data-controller を追加（1行目）

```diff
- <%= form_with model: [:admin, @my_story_section], local: true, multipart: true, class: "space-y-6" do |form| %>
+ <%= form_with model: [:admin, @my_story_section], local: true, multipart: true, class: "space-y-6", data: { controller: "my-story-form" } do |form| %>
```

### 3-2: セクションタイプselectに data-target と data-action を追加（35-38行目付近）

```diff
          <%= form.select :section_type, 
              options_for_select(@available_section_types, @my_story_section.section_type),
              { prompt: "セクションタイプを選択してください" },
-             { class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm" } %>
+             { class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm",
+               data: { my_story_form_target: "sectionType", action: "change->my-story-form#updateFields" } } %>
```

### 3-3: 章専用フィールドに data-target を追加（80行目付近）

```diff
- <div class="bg-white shadow sm:rounded-lg" id="chapter-fields" style="display: none;">
+ <div class="bg-white shadow sm:rounded-lg" id="chapter-fields" style="display: none;" data-my-story-form-target="chapterFields">
```

### 3-4: 動的フィールドコンテナに data-target を追加

`id="dynamic-additional-fields"` を検索して修正：

```diff
- <div id="dynamic-additional-fields">
+ <div id="dynamic-additional-fields" data-my-story-form-target="dynamicFields">
```

### 3-5: インラインJavaScriptを削除（276行目〜361行目付近）

ファイル末尾の `<script>` タグ全体を削除：

```diff
- <script>
- document.addEventListener('DOMContentLoaded', function() {
-   const sectionTypeSelect = document.querySelector('#my_story_section_section_type');
-   ... (省略)
- });
- </script>
```

---

## デプロイ

```bash
./scripts/deploy.sh --keep-ssl --recreate
```

---

## 動作確認

1. `/admin/my_story_sections` にアクセス
2. 「新規セクション追加」をクリック
3. セクションタイプで「第1章」を選択 → **即座に**章専用フィールドが表示されること
4. 他のセクションタイプに切り替え → 章専用フィールドが非表示になること
5. ページをリロードせずに複数回切り替えても正常動作すること

---

## 修正ファイル一覧

| ファイル | 操作 |
|---------|------|
| `app/javascript/controllers/my_story_form_controller.js` | **新規作成** |
| `app/javascript/controllers/index.js` | 修正（2行追加） |
| `app/views/admin/my_story_sections/_form.html.erb` | 修正（4箇所変更、インラインJS削除） |
