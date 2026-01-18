import { Controller } from "@hotwired/stimulus"

// AI Assistant Controller for Article Editing
// Provides AI-powered suggestions for summary, tags, slug, and SEO meta
export default class extends Controller {
  static targets = [
    // Form fields
    "title", "excerpt", "slug", "tagNames", "body",
    "metaDescription", "metaKeywords", "ogTitle", "ogDescription",
    // Structure suggestion fields
    "structureTopic", "structureDetailLevel",
    // Result display areas
    "titleResults", "summaryResults", "slugResults", "tagResults", "seoResults", "structureResults",
    // Loading indicators
    "titleLoading", "summaryLoading", "slugLoading", "tagLoading", "seoLoading", "structureLoading",
    // Buttons
    "titleButton", "summaryButton", "slugButton", "tagButton", "seoButton", "structureButton"
  ]

  static values = {
    articleId: Number,
    baseUrl: String
  }

  connect() {
    console.log("AI Assistant controller connected")
  }

  // ===== Title Suggestions =====
  async suggestTitle(event) {
    event.preventDefault()

    if (!this.articleIdValue) {
      this.showError("titleResults", "記事を保存してからAI機能を使用してください。")
      return
    }

    this.setLoading("title", true)
    this.clearResults("titleResults")

    try {
      const response = await fetch(`${this.baseUrlValue}/articles/${this.articleIdValue}/ai/suggest_title`, {
        method: "POST",
        headers: this.headers,
        body: JSON.stringify({ count: 3 })
      })

      const data = await response.json()

      if (data.success) {
        this.displayTitleResults(data.data)
      } else {
        this.showError("titleResults", data.error || "タイトル提案の取得に失敗しました")
      }
    } catch (error) {
      console.error("Title suggestion error:", error)
      this.showError("titleResults", "通信エラーが発生しました")
    } finally {
      this.setLoading("title", false)
    }
  }

  displayTitleResults(data) {
    if (!this.hasTitleResultsTarget) return

    const descriptiveTitles = data.descriptive_titles || []
    const engagingTitles = data.engaging_titles || []

    let html = '<div class="space-y-4">'

    // Descriptive titles section
    if (descriptiveTitles.length > 0) {
      html += `
        <div>
          <h4 class="text-xs font-semibold text-gray-700 mb-2 flex items-center">
            <svg class="w-4 h-4 mr-1 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            わかりやすいタイトル
          </h4>
          <div class="space-y-2">
      `

      descriptiveTitles.forEach(item => {
        html += `
          <div class="p-3 bg-blue-50 rounded-md hover:bg-blue-100 cursor-pointer border border-transparent hover:border-blue-300 transition-colors"
               data-action="click->ai-assistant#applyTitle"
               data-title="${this.escapeHtml(item.title)}">
            <div class="flex justify-between items-start mb-1">
              <span class="text-sm font-medium text-gray-900 flex-1">${this.escapeHtml(item.title)}</span>
              <span class="text-xs text-blue-600 ml-2 whitespace-nowrap">選択</span>
            </div>
            <p class="text-xs text-gray-600">${this.escapeHtml(item.reason)}</p>
          </div>
        `
      })

      html += '</div></div>'
    }

    // Engaging titles section
    if (engagingTitles.length > 0) {
      html += `
        <div>
          <h4 class="text-xs font-semibold text-gray-700 mb-2 flex items-center">
            <svg class="w-4 h-4 mr-1 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
            SNS映えするタイトル
          </h4>
          <div class="space-y-2">
      `

      engagingTitles.forEach(item => {
        html += `
          <div class="p-3 bg-purple-50 rounded-md hover:bg-purple-100 cursor-pointer border border-transparent hover:border-purple-300 transition-colors"
               data-action="click->ai-assistant#applyTitle"
               data-title="${this.escapeHtml(item.title)}">
            <div class="flex justify-between items-start mb-1">
              <span class="text-sm font-medium text-gray-900 flex-1">${this.escapeHtml(item.title)}</span>
              <span class="text-xs text-purple-600 ml-2 whitespace-nowrap">選択</span>
            </div>
            <p class="text-xs text-gray-600">${this.escapeHtml(item.reason)}</p>
          </div>
        `
      })

      html += '</div></div>'
    }

    html += '</div>'
    this.titleResultsTarget.innerHTML = html
  }

  applyTitle(event) {
    const title = event.currentTarget.dataset.title
    if (this.hasTitleTarget) {
      this.titleTarget.value = title
      this.highlightField(this.titleTarget)
    }
    this.clearResults("titleResults")
  }

  // Get CSRF token from meta tag
  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }

  // Common headers for API requests
  get headers() {
    return {
      "Content-Type": "application/json",
      "X-CSRF-Token": this.csrfToken,
      "Accept": "application/json"
    }
  }

  // ===== Summary Generation =====
  async generateSummary(event) {
    event.preventDefault()

    if (!this.articleIdValue) {
      this.showError("summaryResults", "記事を保存してからAI機能を使用してください。")
      return
    }

    this.setLoading("summary", true)
    this.clearResults("summaryResults")

    try {
      const response = await fetch(`${this.baseUrlValue}/articles/${this.articleIdValue}/ai/generate_summary`, {
        method: "POST",
        headers: this.headers,
        body: JSON.stringify({ length: "medium", count: 3 })
      })

      const data = await response.json()

      if (data.success) {
        this.displaySummaryResults(data.data.summaries)
      } else {
        this.showError("summaryResults", data.error || "要約の生成に失敗しました")
      }
    } catch (error) {
      console.error("Summary generation error:", error)
      this.showError("summaryResults", "通信エラーが発生しました")
    } finally {
      this.setLoading("summary", false)
    }
  }

  displaySummaryResults(summaries) {
    if (!this.hasSummaryResultsTarget) return

    const html = summaries.map((summary, index) => {
      // Handle both object format {text: "..."} and string format
      const text = typeof summary === 'object' ? summary.text : summary
      return `
      <div class="p-3 bg-gray-50 rounded-md mb-2 hover:bg-gray-100 cursor-pointer border border-transparent hover:border-blue-300"
           data-action="click->ai-assistant#applySummary"
           data-summary="${this.escapeHtml(text)}">
        <div class="flex justify-between items-start">
          <span class="text-sm text-gray-700 flex-1">${this.escapeHtml(text)}</span>
          <span class="text-xs text-blue-600 ml-2 whitespace-nowrap">選択</span>
        </div>
      </div>
    `
    }).join("")

    this.summaryResultsTarget.innerHTML = html
  }

  applySummary(event) {
    const summary = event.currentTarget.dataset.summary
    if (this.hasExcerptTarget) {
      this.excerptTarget.value = summary
      this.highlightField(this.excerptTarget)
    }
    this.clearResults("summaryResults")
  }

  // ===== Slug Generation =====
  async generateSlug(event) {
    event.preventDefault()

    if (!this.articleIdValue) {
      this.showError("slugResults", "記事を保存してからAI機能を使用してください。")
      return
    }

    this.setLoading("slug", true)
    this.clearResults("slugResults")

    try {
      const response = await fetch(`${this.baseUrlValue}/articles/${this.articleIdValue}/ai/generate_slug`, {
        method: "POST",
        headers: this.headers,
        body: JSON.stringify({ count: 3 })
      })

      const data = await response.json()

      if (data.success) {
        this.displaySlugResults(data.data.slugs)
      } else {
        this.showError("slugResults", data.error || "スラッグの生成に失敗しました")
      }
    } catch (error) {
      console.error("Slug generation error:", error)
      this.showError("slugResults", "通信エラーが発生しました")
    } finally {
      this.setLoading("slug", false)
    }
  }

  displaySlugResults(slugs) {
    if (!this.hasSlugResultsTarget) return

    const html = slugs.map((slugItem, index) => {
      // Handle both object format {slug: "...", seo_score: 95} and string format
      const slug = typeof slugItem === 'object' ? slugItem.slug : slugItem
      const score = typeof slugItem === 'object' && slugItem.seo_score ? ` (${slugItem.seo_score}点)` : ''
      return `
      <div class="inline-block px-3 py-1 bg-gray-100 rounded-full text-sm mr-2 mb-2 hover:bg-blue-100 cursor-pointer"
           data-action="click->ai-assistant#applySlug"
           data-slug="${this.escapeHtml(slug)}">
        ${this.escapeHtml(slug)}${score}
      </div>
    `
    }).join("")

    this.slugResultsTarget.innerHTML = html
  }

  applySlug(event) {
    const slug = event.currentTarget.dataset.slug
    if (this.hasSlugTarget) {
      this.slugTarget.value = slug
      this.highlightField(this.slugTarget)
    }
    this.clearResults("slugResults")
  }

  // ===== Tag Suggestions =====
  async suggestTags(event) {
    event.preventDefault()

    if (!this.articleIdValue) {
      this.showError("tagResults", "記事を保存してからAI機能を使用してください。")
      return
    }

    this.setLoading("tag", true)
    this.clearResults("tagResults")

    try {
      const response = await fetch(`${this.baseUrlValue}/articles/${this.articleIdValue}/ai/suggest_tags`, {
        method: "POST",
        headers: this.headers,
        body: JSON.stringify({ max_tags: 6, include_existing: true })
      })

      const data = await response.json()

      if (data.success) {
        this.displayTagResults(data.data.suggested_tags, data.data.existing_tags)
      } else {
        this.showError("tagResults", data.error || "タグ提案の取得に失敗しました")
      }
    } catch (error) {
      console.error("Tag suggestion error:", error)
      this.showError("tagResults", "通信エラーが発生しました")
    } finally {
      this.setLoading("tag", false)
    }
  }

  displayTagResults(suggestedTags, existingTags) {
    if (!this.hasTagResultsTarget) return

    const suggested = suggestedTags || []
    const existing = existingTags || []
    const existingNames = existing.map(t => typeof t === 'object' ? t.name : t)

    let html = '<div class="flex flex-wrap gap-2">'

    // Suggested tags (new)
    suggested.forEach(tagItem => {
      // Handle both object format {name: "...", confidence: 0.95} and string format
      const tagName = typeof tagItem === 'object' ? tagItem.name : tagItem
      const confidence = typeof tagItem === 'object' && tagItem.confidence
        ? ` (${Math.round(tagItem.confidence * 100)}%)` : ''

      if (!existingNames.includes(tagName)) {
        html += `
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 cursor-pointer hover:bg-blue-200"
                data-action="click->ai-assistant#addTag"
                data-tag="${this.escapeHtml(tagName)}">
            + ${this.escapeHtml(tagName)}${confidence}
          </span>
        `
      }
    })

    html += '</div>'
    this.tagResultsTarget.innerHTML = html
  }

  addTag(event) {
    const tag = event.currentTarget.dataset.tag
    if (this.hasTagNamesTarget) {
      const currentTags = this.tagNamesTarget.value.split(",").map(t => t.trim()).filter(t => t)
      if (!currentTags.includes(tag)) {
        currentTags.push(tag)
        this.tagNamesTarget.value = currentTags.join(", ")
        this.highlightField(this.tagNamesTarget)
      }
    }
    // Remove the clicked tag from suggestions
    event.currentTarget.remove()
  }

  // ===== SEO Meta Generation =====
  async generateSeoMeta(event) {
    event.preventDefault()

    if (!this.articleIdValue) {
      this.showError("seoResults", "記事を保存してからAI機能を使用してください。")
      return
    }

    this.setLoading("seo", true)
    this.clearResults("seoResults")

    try {
      const response = await fetch(`${this.baseUrlValue}/articles/${this.articleIdValue}/ai/generate_seo_meta`, {
        method: "POST",
        headers: this.headers,
        body: JSON.stringify({ fields: ["meta_description", "meta_keywords", "og_title", "og_description"] })
      })

      const data = await response.json()

      if (data.success) {
        this.displaySeoResults(data.data)
      } else {
        this.showError("seoResults", data.error || "SEOメタの生成に失敗しました")
      }
    } catch (error) {
      console.error("SEO meta generation error:", error)
      this.showError("seoResults", "通信エラーが発生しました")
    } finally {
      this.setLoading("seo", false)
    }
  }

  displaySeoResults(data) {
    if (!this.hasSeoResultsTarget) return

    const fields = [
      { key: "meta_description", label: "メタディスクリプション", target: "metaDescription" },
      { key: "meta_keywords", label: "メタキーワード", target: "metaKeywords" },
      { key: "og_title", label: "OGタイトル", target: "ogTitle" },
      { key: "og_description", label: "OG説明文", target: "ogDescription" }
    ]

    let html = '<div class="space-y-3">'

    fields.forEach(field => {
      if (data[field.key]) {
        html += `
          <div class="p-3 bg-gray-50 rounded-md">
            <div class="flex justify-between items-start mb-1">
              <span class="text-xs font-medium text-gray-500">${field.label}</span>
              <button type="button"
                      class="text-xs text-blue-600 hover:text-blue-800"
                      data-action="click->ai-assistant#applySeoField"
                      data-field="${field.target}"
                      data-value="${this.escapeHtml(data[field.key])}">
                適用
              </button>
            </div>
            <p class="text-sm text-gray-700">${this.escapeHtml(data[field.key])}</p>
          </div>
        `
      }
    })

    // Apply All button
    html += `
      <button type="button"
              class="w-full mt-2 py-2 px-4 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700"
              data-action="click->ai-assistant#applyAllSeoFields"
              data-seo='${JSON.stringify(data)}'>
        すべて適用
      </button>
    `

    html += '</div>'
    this.seoResultsTarget.innerHTML = html
  }

  applySeoField(event) {
    const field = event.currentTarget.dataset.field
    const value = event.currentTarget.dataset.value
    const targetName = `has${field.charAt(0).toUpperCase() + field.slice(1)}Target`

    if (this[targetName]) {
      const target = this[`${field}Target`]
      target.value = value
      this.highlightField(target)
    }
  }

  applyAllSeoFields(event) {
    const seoData = JSON.parse(event.currentTarget.dataset.seo)

    const mapping = {
      meta_description: "metaDescription",
      meta_keywords: "metaKeywords",
      og_title: "ogTitle",
      og_description: "ogDescription"
    }

    Object.entries(mapping).forEach(([key, target]) => {
      const targetName = `has${target.charAt(0).toUpperCase() + target.slice(1)}Target`
      if (seoData[key] && this[targetName]) {
        this[`${target}Target`].value = seoData[key]
        this.highlightField(this[`${target}Target`])
      }
    })

    this.clearResults("seoResults")
  }

  // ===== Structure Suggestion =====
  async suggestStructure(event) {
    event.preventDefault()

    const topic = this.hasStructureTopicTarget ? this.structureTopicTarget.value : ""
    if (!topic.trim()) {
      this.showError("structureResults", "トピックを入力してください")
      return
    }

    const detailLevel = this.hasStructureDetailLevelTarget
      ? this.structureDetailLevelTarget.value
      : "detailed"

    this.setLoading("structure", true)
    this.clearResults("structureResults")

    try {
      const response = await fetch(`${this.baseUrlValue}/ai/suggest_structure`, {
        method: "POST",
        headers: this.headers,
        body: JSON.stringify({
          topic: topic,
          detail_level: detailLevel,
          format: "markdown"
        })
      })

      const data = await response.json()

      if (data.success) {
        this.displayStructureResults(data.data.structure)
      } else {
        this.showError("structureResults", data.error || "構成提案の取得に失敗しました")
      }
    } catch (error) {
      console.error("Structure suggestion error:", error)
      this.showError("structureResults", "通信エラーが発生しました")
    } finally {
      this.setLoading("structure", false)
    }
  }

  displayStructureResults(structure) {
    if (!this.hasStructureResultsTarget) return

    const html = `
      <div class="space-y-3">
        <div class="bg-gray-50 rounded-md p-4 border border-gray-200">
          <pre class="text-sm text-gray-800 whitespace-pre-wrap font-mono">${this.escapeHtml(structure)}</pre>
        </div>
        <div class="flex gap-2">
          <button type="button"
                  class="flex-1 py-2 px-4 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700"
                  data-action="click->ai-assistant#applyStructure"
                  data-structure="${this.escapeHtml(structure)}">
            本文に挿入
          </button>
          <button type="button"
                  class="py-2 px-4 bg-gray-200 text-gray-700 text-sm font-medium rounded-md hover:bg-gray-300"
                  data-action="click->ai-assistant#copyStructure"
                  data-structure="${this.escapeHtml(structure)}">
            コピー
          </button>
        </div>
      </div>
    `
    this.structureResultsTarget.innerHTML = html
  }

  applyStructure(event) {
    const structure = event.currentTarget.dataset.structure
    if (this.hasBodyTarget) {
      // Insert at cursor position or at the beginning if no body content
      const currentContent = this.bodyTarget.value
      if (currentContent.trim()) {
        this.bodyTarget.value = structure + "\n\n" + currentContent
      } else {
        this.bodyTarget.value = structure
      }
      this.highlightField(this.bodyTarget)
    }
    this.clearResults("structureResults")
  }

  copyStructure(event) {
    const structure = event.currentTarget.dataset.structure
    navigator.clipboard.writeText(structure).then(() => {
      // Show brief confirmation
      const originalText = event.currentTarget.textContent
      event.currentTarget.textContent = "コピーしました"
      setTimeout(() => {
        event.currentTarget.textContent = originalText
      }, 1500)
    }).catch(err => {
      console.error("Copy failed:", err)
    })
  }

  // ===== Helper Methods =====
  setLoading(type, isLoading) {
    const buttonTarget = `${type}ButtonTarget`
    const loadingTarget = `${type}LoadingTarget`

    if (this[`has${type.charAt(0).toUpperCase() + type.slice(1)}ButtonTarget`]) {
      this[buttonTarget].disabled = isLoading
      this[buttonTarget].classList.toggle("opacity-50", isLoading)
    }

    if (this[`has${type.charAt(0).toUpperCase() + type.slice(1)}LoadingTarget`]) {
      this[loadingTarget].classList.toggle("hidden", !isLoading)
    }
  }

  clearResults(targetName) {
    const hasTarget = `has${targetName.charAt(0).toUpperCase() + targetName.slice(1)}Target`
    if (this[hasTarget]) {
      this[`${targetName}Target`].innerHTML = ""
    }
  }

  showError(targetName, message) {
    const hasTarget = `has${targetName.charAt(0).toUpperCase() + targetName.slice(1)}Target`
    if (this[hasTarget]) {
      this[`${targetName}Target`].innerHTML = `
        <div class="p-3 bg-red-50 border border-red-200 rounded-md">
          <p class="text-sm text-red-600">${this.escapeHtml(message)}</p>
        </div>
      `
    }
  }

  highlightField(element) {
    element.classList.add("ring-2", "ring-green-500", "ring-opacity-50")
    setTimeout(() => {
      element.classList.remove("ring-2", "ring-green-500", "ring-opacity-50")
    }, 2000)
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
