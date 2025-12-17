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