# プロトタイプAPI統合計画書

## 概要
Step 6として、既存の16プロトタイプにAPI機能を統合し、動的なAPI連携機能を追加する。

## 統合対象プロトタイプ

### フロントエンド（5画面）

#### 1. ポートフォリオトップ (portfolio_prototype.html)
**API統合箇所:**
- ブログセクション → `GET /api/v1/articles?limit=3`で最新記事表示
- お問い合わせフォーム → `POST /api/v1/contacts`で非同期送信
- ポートフォリオ動的コンテンツ → `GET /api/v1/portfolio`でセクション配信

**追加するJavaScript:**
```javascript
// 最新記事の動的読み込み
async function loadLatestArticles() {
    const response = await fetch('/api/v1/articles?limit=3');
    const data = await response.json();
    updateArticleSection(data.data);
}

// お問い合わせフォーム非同期送信
async function submitContactForm(formData) {
    const response = await fetch('/api/v1/contacts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
    });
    return response.json();
}
```

#### 2. ブログトップ (blog_top_prototype.html)
**API統合箇所:**
- 検索機能 → `GET /api/v1/articles/search`リアルタイム検索
- カテゴリ表示 → `GET /api/v1/categories`で動的カテゴリ読み込み
- 記事一覧 → `GET /api/v1/articles`でページネーション

**既存検索機能の強化:**
```javascript
// 現在のperformSearch関数を拡張
async function performSearch(query) {
    showResults();
    
    try {
        const response = await fetch(`/api/v1/articles/search?q=${encodeURIComponent(query)}`);
        const data = await response.json();
        
        // UI更新
        updateSearchResults(data.data);
        addToSearchHistory(query);
        
    } catch (error) {
        console.error('検索エラー:', error);
        showSearchError();
    }
}
```

#### 3. 記事詳細 (blog_article_prototype.html)
**API統合箇所:**
- 記事コンテンツ → `GET /api/v1/articles/:slug`で動的読み込み
- 関連記事 → `GET /api/v1/articles/:slug/related`で関連記事表示
- コメント表示/投稿 → `GET/POST /api/v1/articles/:slug/comments`

#### 4. カテゴリページ (blog_category_prototype.html)
**API統合箇所:**
- カテゴリ記事一覧 → `GET /api/v1/categories/:slug/articles`
- パンくず → `GET /api/v1/categories/:slug`で階層情報取得

#### 5. My Story (my_story_prototype.html)
**API統合箇所:**
- 動的コンテンツ → `GET /api/v1/portfolio/sections/my_story`でコンテンツ配信

### 管理画面（11画面）

#### 1. ダッシュボード (admin_dashboard_prototype.html)
**API統合箇所:**
- 統計データ → `GET /api/internal/analytics/dashboard`で動的統計取得
- リアルタイム通知 → WebSocket APIでリアルタイム通知
- 人気記事 → `GET /api/internal/articles/popular`
- システム状態 → `GET /api/internal/system/health`

**追加するJavaScript:**
```javascript
// ダッシュボードデータの定期更新
class DashboardAPI {
    async loadStats() {
        const response = await fetch('/api/internal/analytics/dashboard');
        return response.json();
    }
    
    async loadPopularArticles() {
        const response = await fetch('/api/internal/articles/popular?limit=5');
        return response.json();
    }
    
    initRealtimeUpdates() {
        setInterval(() => {
            this.loadStats().then(data => this.updateStats(data));
        }, 30000); // 30秒ごと更新
    }
}
```

#### 2. 記事管理 (admin_blog_prototype.html)
**API統合箇所:**
- 記事一覧 → `GET /api/internal/articles`でフィルタリング・ソート
- 一括操作 → `PATCH /api/internal/articles/bulk`で一括ステータス更新
- 検索・フィルタ → リアルタイム検索API

#### 3. 記事エディタ (admin_article_editor_prototype.html)
**API統合箇所:**
- 自動保存 → `PATCH /api/internal/articles/:id/autosave`
- AI分析 → `POST /api/internal/ai/analyze`でAI要約・SEO提案
- メディア挿入 → `GET /api/internal/media`でメディア選択
- プレビュー → `POST /api/internal/articles/preview`

**AI機能統合例:**
```javascript
class AIAssistant {
    async analyzeContent(articleId) {
        const response = await fetch(`/api/internal/ai/analyze`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ article_id: articleId })
        });
        return response.json();
    }
    
    async getSEOSuggestions(title, content) {
        const response = await fetch('/api/internal/ai/seo-suggestions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ title, content })
        });
        return response.json();
    }
}
```

#### 4. カテゴリ管理 (admin_categories_prototype.html)
**API統合箇所:**
- カテゴリツリー → `GET /api/internal/categories/tree`で階層表示
- ドラッグ&ドロップ → `PATCH /api/internal/categories/reorder`で並び替え

#### 5. メディア管理 (admin_media_prototype.html)
**API統合箇所:**
- ファイル一覧 → `GET /api/internal/media`でページネーション
- アップロード → `POST /api/internal/media`でドラッグ&ドロップ
- 使用状況 → `GET /api/internal/media/:id/usage`で利用状況表示
- WebP変換進捗 → WebSocket APIで変換進捗リアルタイム表示

#### 6-11. その他管理画面
- **コメント管理**: `GET/PATCH /api/internal/comments`でコメント承認・スパム管理
- **ユーザー管理**: `GET/POST/PATCH /api/internal/users`でユーザー管理
- **ポートフォリオCMS**: `GET/PATCH /api/internal/sections`でセクション管理
- **設定画面**: `GET/PATCH /api/internal/settings`で設定管理

## 実装手順

### Phase 1: フロントエンド統合（2日）

#### Day 1: 検索・記事機能
1. **blog_top_prototype.html更新**
   ```html
   <!-- API統合検索ボックス -->
   <script>
   class BlogSearchAPI {
       async search(query, options = {}) {
           const params = new URLSearchParams({
               q: query,
               page: options.page || 1,
               limit: options.limit || 10,
               category: options.category || '',
               sort: options.sort || 'published_at'
           });
           
           const response = await fetch(`/api/v1/articles/search?${params}`);
           return response.json();
       }
   }
   </script>
   ```

2. **portfolio_prototype.html更新**
   ```html
   <!-- ブログセクションAPI統合 -->
   <script>
   async function loadLatestBlogPosts() {
       try {
           const response = await fetch('/api/v1/articles?limit=3&status=published');
           const data = await response.json();
           renderBlogSection(data.data);
       } catch (error) {
           console.error('ブログ記事読み込みエラー:', error);
       }
   }
   </script>
   ```

#### Day 2: お問い合わせ・動的コンテンツ
1. **Contact Form API統合**
   ```html
   <!-- お問い合わせフォーム非同期化 -->
   <script>
   class ContactFormAPI {
       async submit(formData) {
           const response = await fetch('/api/v1/contacts', {
               method: 'POST',
               headers: { 
                   'Content-Type': 'application/json',
                   'X-Requested-With': 'XMLHttpRequest'
               },
               body: JSON.stringify({
                   name: formData.get('name'),
                   email: formData.get('email'),
                   subject: formData.get('subject'),
                   message: formData.get('message')
               })
           });
           
           if (!response.ok) {
               throw new Error('送信に失敗しました');
           }
           
           return response.json();
       }
   }
   </script>
   ```

### Phase 2: 管理画面統合（3日）

#### Day 1: ダッシュボード・統計API
1. **admin_dashboard_prototype.html更新**
   ```javascript
   class DashboardManager {
       constructor() {
           this.statsAPI = new StatsAPI();
           this.initRealtimeUpdates();
       }
       
       async loadDashboardData() {
           const [stats, popular, notifications] = await Promise.all([
               this.statsAPI.getDashboardStats(),
               this.statsAPI.getPopularArticles(),
               this.statsAPI.getSystemNotifications()
           ]);
           
           this.updateStatsCards(stats);
           this.updatePopularArticles(popular);
           this.updateNotifications(notifications);
       }
       
       initRealtimeUpdates() {
           // 30秒ごとに統計更新
           setInterval(() => this.loadDashboardData(), 30000);
       }
   }
   ```

#### Day 2: 記事管理・エディタ
1. **admin_article_editor_prototype.html AI機能統合**
   ```javascript
   class AIEditorAssistant {
       async analyzeContent(content) {
           const response = await fetch('/api/internal/ai/analyze', {
               method: 'POST',
               headers: { 'Content-Type': 'application/json' },
               body: JSON.stringify({ 
                   content: content,
                   analysis_type: 'full'
               })
           });
           return response.json();
       }
       
       async generateSummary(content) {
           const response = await fetch('/api/internal/ai/summarize', {
               method: 'POST',
               headers: { 'Content-Type': 'application/json' },
               body: JSON.stringify({ content })
           });
           return response.json();
       }
       
       displayAISuggestions(suggestions) {
           // AI提案をUIに表示
           const suggestionsPanel = document.getElementById('ai-suggestions');
           suggestionsPanel.innerHTML = this.renderSuggestions(suggestions);
       }
   }
   ```

#### Day 3: メディア・設定管理
1. **admin_media_prototype.html ファイル管理API**
   ```javascript
   class MediaManagerAPI {
       async uploadFiles(files) {
           const formData = new FormData();
           files.forEach(file => formData.append('files[]', file));
           
           const response = await fetch('/api/internal/media', {
               method: 'POST',
               body: formData
           });
           return response.json();
       }
       
       async getUsageInfo(mediaId) {
           const response = await fetch(`/api/internal/media/${mediaId}/usage`);
           return response.json();
       }
   }
   ```

## APIレスポンス形式の統一

### 成功レスポンス
```json
{
  "status": "success",
  "data": {
    // レスポンスデータ
  },
  "meta": {
    "pagination": {
      "page": 1,
      "per_page": 10,
      "total": 50,
      "total_pages": 5
    }
  }
}
```

### エラーレスポンス
```json
{
  "status": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "入力データに不正があります",
    "details": {
      "email": ["メールアドレスが無効です"]
    }
  }
}
```

## プロトタイプ更新チェックリスト

### フロントエンド
- [ ] blog_top_prototype.html: 検索API統合
- [ ] portfolio_prototype.html: ブログ・お問い合わせAPI統合
- [ ] blog_article_prototype.html: 記事詳細API統合
- [ ] blog_category_prototype.html: カテゴリAPI統合
- [ ] my_story_prototype.html: 動的コンテンツAPI統合

### 管理画面
- [ ] admin_dashboard_prototype.html: 統計・通知API統合
- [ ] admin_blog_prototype.html: 記事管理API統合
- [ ] admin_article_editor_prototype.html: AI・自動保存API統合
- [ ] admin_categories_prototype.html: カテゴリ管理API統合
- [ ] admin_media_prototype.html: メディア管理API統合
- [ ] admin_comments_prototype.html: コメント管理API統合
- [ ] admin_users_prototype.html: ユーザー管理API統合
- [ ] admin_portfolio_prototype.html: ポートフォリオCMS API統合
- [ ] admin_settings_prototype.html: 設定管理API統合

## エラーハンドリング・ユーザビリティ

### 共通エラーハンドリング
```javascript
class APIClient {
    async request(url, options = {}) {
        try {
            const response = await fetch(url, {
                headers: {
                    'Content-Type': 'application/json',
                    ...options.headers
                },
                ...options
            });
            
            if (!response.ok) {
                throw new APIError(response.status, await response.json());
            }
            
            return response.json();
        } catch (error) {
            this.handleError(error);
            throw error;
        }
    }
    
    handleError(error) {
        if (error instanceof APIError) {
            this.showUserMessage(error.message, 'error');
        } else {
            this.showUserMessage('ネットワークエラーが発生しました', 'error');
        }
    }
}
```

### ローディング状態管理
```javascript
class LoadingManager {
    show(element) {
        element.classList.add('loading');
        element.setAttribute('data-original-text', element.textContent);
        element.textContent = '読み込み中...';
        element.disabled = true;
    }
    
    hide(element) {
        element.classList.remove('loading');
        element.textContent = element.getAttribute('data-original-text');
        element.disabled = false;
    }
}
```

## 完成イメージ

### フロントエンド
- **リアルタイム検索**: 入力と同時に検索結果表示
- **非同期お問い合わせ**: ページ遷移なしでフォーム送信
- **動的コンテンツ**: APIから取得したデータでページ構築

### 管理画面
- **リアルタイムダッシュボード**: 30秒ごとに統計自動更新
- **AI支援エディタ**: リアルタイム要約・SEO提案
- **自動保存**: 編集中のデータを自動保存
- **進捗表示**: ファイルアップロード・AI処理の進捗表示

このAPI統合により、静的プロトタイプが動的なWebアプリケーションとして機能し、Phase 4のAPI実装に向けた明確な設計指針が完成します。