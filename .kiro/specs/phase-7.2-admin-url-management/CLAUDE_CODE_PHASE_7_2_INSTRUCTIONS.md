# Phase 7.2: 管理画面URL管理 - Claude Code実装指示書

## 📋 概要

**Phase**: 7.2 管理画面URL管理  
**実装担当**: Claude Code  
**検証担当**: Codex  
**レビュー担当**: Kiro  
**作成日**: 2026-01-23

---

## 🎯 実装目標

管理画面のURLを動的に変更できる機能を実装します。自動ローテーション機能により、定期的にURLを変更してセキュリティを強化します。

### 主要機能
1. **URL変更機能**: 管理画面のURLを手動で変更
2. **自動ローテーション**: 定期的に自動でURL変更
3. **緊急ローテーション**: 不正アクセス検知時に即座にURL変更
4. **変更履歴管理**: URL変更履歴の記録・表示
5. **通知機能**: URL変更時にメール・Slack通知

---

## 📦 実装範囲

### Phase 7.2タスク（11タスク）

#### URL変更機能（Day 1-2）
- ✅ 2.1 AdminPathHistoryモデル作成
- ✅ 2.2 AdminPath::Updaterサービス実装
- ✅ 2.3 URL変更画面UI実装
- ✅ 2.4 環境変数更新機能実装

#### 自動ローテーション（Day 3-4）
- ✅ 2.5 AdminPath::RotationJob実装
- ✅ 2.6 Sidekiq-cronスケジュール設定
- ✅ 2.7 ローテーション設定画面UI実装
- ✅ 2.8 緊急ローテーション機能実装

#### テスト・ドキュメント（Day 5）
- ✅ 2.9 RSpecテスト実装（15件）
- ⚠️ 2.10 E2Eテスト実装（2件）※オプション
- ⚠️ 2.11 ドキュメント作成 ※オプション

---

## 🚀 実装手順


### Step 1: AdminPathHistoryモデル作成

```bash
# マイグレーション作成
docker compose exec web bin/rails generate model AdminPathHistory \
  old_path:string \
  new_path:string \
  change_type:string \
  admin_user:references \
  ip_address:string \
  reason:text \
  notified_at:datetime

# マイグレーション実行
docker compose exec web bin/rails db:migrate
```

**モデル実装**: `app/models/admin_path_history.rb`

```ruby
class AdminPathHistory < ApplicationRecord
  belongs_to :admin_user

  enum change_type: {
    manual: 'manual',
    auto_rotation: 'auto_rotation',
    emergency: 'emergency'
  }

  validates :old_path, presence: true
  validates :new_path, presence: true, uniqueness: true
  validates :change_type, presence: true

  scope :recent, -> { order(created_at: :desc).limit(10) }
  scope :by_type, ->(type) { where(change_type: type) }
end
```

---

### Step 2: AdminPath::Updaterサービス実装

**ファイル**: `app/services/admin_path/updater.rb`

```ruby
module AdminPath
  class Updater
    RESERVED_PATHS = %w[
      admin administrator root system api health
      login logout signin signout register signup
    ].freeze

    def initialize(admin_user:, new_path:, change_type: :manual, reason: nil)
      @admin_user = admin_user
      @new_path = new_path.to_s.strip.downcase
      @change_type = change_type
      @reason = reason
      @old_path = ENV.fetch('ADMIN_PATH', 'admin')
    end

    def call
      validate!
      update_env_file!
      create_history!
      reload_routes!
      send_notifications!
      
      { success: true, new_path: @new_path }
    rescue StandardError => e
      Rails.logger.error("AdminPath::Updater failed: #{e.message}")
      { success: false, error: e.message }
    end

    private

    def validate!
      raise ArgumentError, 'New path cannot be empty' if @new_path.blank?
      raise ArgumentError, 'New path is reserved' if RESERVED_PATHS.include?(@new_path)
      raise ArgumentError, 'New path must be alphanumeric with hyphens' unless @new_path.match?(/\A[a-z0-9\-]+\z/)
      raise ArgumentError, 'New path is same as current' if @new_path == @old_path
    end

    def update_env_file!
      env_file = Rails.root.join('.env.production')
      content = File.read(env_file)
      
      if content.match?(/^ADMIN_PATH=/)
        content.gsub!(/^ADMIN_PATH=.*$/, "ADMIN_PATH=#{@new_path}")
      else
        content += "\nADMIN_PATH=#{@new_path}\n"
      end
      
      File.write(env_file, content)
      ENV['ADMIN_PATH'] = @new_path
    end

    def create_history!
      AdminPathHistory.create!(
        admin_user: @admin_user,
        old_path: @old_path,
        new_path: @new_path,
        change_type: @change_type,
        ip_address: @admin_user.current_sign_in_ip,
        reason: @reason,
        notified_at: Time.current
      )
    end

    def reload_routes!
      Rails.application.reload_routes!
    end

    def send_notifications!
      AdminPathMailer.path_changed(
        admin_user: @admin_user,
        old_path: @old_path,
        new_path: @new_path,
        change_type: @change_type
      ).deliver_later

      SlackNotifier.notify_admin_path_changed(
        old_path: @old_path,
        new_path: @new_path,
        change_type: @change_type,
        admin_user: @admin_user
      )
    end
  end
end
```

---

### Step 3: Admin::AdminPathSettingsController実装

**ファイル**: `app/controllers/admin/admin_path_settings_controller.rb`

```ruby
module Admin
  class AdminPathSettingsController < Admin::BaseController
    def edit
      @current_path = ENV.fetch('ADMIN_PATH', 'admin')
      @histories = AdminPathHistory.recent.includes(:admin_user)
      @rotation_enabled = ENV.fetch('ADMIN_PATH_ROTATION_ENABLED', 'false') == 'true'
      @rotation_frequency = ENV.fetch('ADMIN_PATH_ROTATION_FREQUENCY', 'monthly')
      @next_rotation_at = calculate_next_rotation
    end

    def update
      result = AdminPath::Updater.new(
        admin_user: current_admin_user,
        new_path: params[:new_path],
        change_type: :manual,
        reason: params[:reason]
      ).call

      if result[:success]
        flash[:notice] = "管理画面URLを変更しました: #{result[:new_path]}"
        redirect_to edit_admin_admin_path_settings_path
      else
        flash[:alert] = "URL変更に失敗しました: #{result[:error]}"
        redirect_to edit_admin_admin_path_settings_path
      end
    end

    def emergency_rotation
      new_path = generate_emergency_path
      result = AdminPath::Updater.new(
        admin_user: current_admin_user,
        new_path: new_path,
        change_type: :emergency,
        reason: params[:reason] || '緊急ローテーション'
      ).call

      if result[:success]
        flash[:notice] = "緊急ローテーションを実行しました: #{result[:new_path]}"
        redirect_to edit_admin_admin_path_settings_path
      else
        flash[:alert] = "緊急ローテーションに失敗しました: #{result[:error]}"
        redirect_to edit_admin_admin_path_settings_path
      end
    end

    private

    def calculate_next_rotation
      return nil unless ENV.fetch('ADMIN_PATH_ROTATION_ENABLED', 'false') == 'true'
      
      frequency = ENV.fetch('ADMIN_PATH_ROTATION_FREQUENCY', 'monthly')
      case frequency
      when 'weekly'
        1.week.from_now
      when 'monthly'
        1.month.from_now
      when 'quarterly'
        3.months.from_now
      else
        1.month.from_now
      end
    end

    def generate_emergency_path
      "emergency-admin-#{SecureRandom.hex(6)}"
    end
  end
end
```

---

### Step 4: ルーティング設定

**ファイル**: `config/routes.rb`

```ruby
# 動的管理画面パス
admin_path = ENV.fetch('ADMIN_PATH', 'admin')

namespace :admin, path: admin_path do
  # 既存のルーティング...
  
  # 管理画面URL管理
  resource :admin_path_settings, only: [:edit, :update] do
    post :emergency_rotation, on: :collection
  end
end
```

---

### Step 5: ビュー実装

**ファイル**: `app/views/admin/admin_path_settings/edit.html.erb`

```erb
<div class="max-w-4xl mx-auto p-6">
  <h1 class="text-3xl font-bold mb-6">管理画面URL管理</h1>

  <!-- 現在のURL -->
  <div class="bg-white rounded-lg shadow p-6 mb-6">
    <h2 class="text-xl font-semibold mb-4">現在のURL</h2>
    <div class="bg-gray-100 p-4 rounded">
      <code class="text-lg">/<%= @current_path %></code>
    </div>
  </div>

  <!-- URL変更フォーム -->
  <div class="bg-white rounded-lg shadow p-6 mb-6">
    <h2 class="text-xl font-semibold mb-4">URL変更</h2>
    <%= form_with url: admin_admin_path_settings_path, method: :put, data: { turbo: false } do |f| %>
      <div class="mb-4">
        <%= f.label :new_path, '新しいURL', class: 'block text-sm font-medium mb-2' %>
        <%= f.text_field :new_path, 
            placeholder: 'admin-secure-panel-2026',
            class: 'w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500',
            pattern: '[a-z0-9\-]+',
            required: true %>
        <p class="text-sm text-gray-600 mt-1">
          英小文字、数字、ハイフンのみ使用可能
        </p>
      </div>

      <div class="mb-4">
        <%= f.label :reason, '変更理由', class: 'block text-sm font-medium mb-2' %>
        <%= f.text_area :reason,
            placeholder: 'セキュリティ強化のため',
            class: 'w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500',
            rows: 3 %>
      </div>

      <%= f.submit 'URL変更', 
          class: 'bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700',
          data: { confirm: '管理画面URLを変更しますか？変更後は新しいURLでアクセスしてください。' } %>
    <% end %>
  </div>

  <!-- 緊急ローテーション -->
  <div class="bg-red-50 rounded-lg shadow p-6 mb-6">
    <h2 class="text-xl font-semibold mb-4 text-red-700">緊急ローテーション</h2>
    <p class="text-sm text-gray-700 mb-4">
      不正アクセスを検知した場合、即座にURLを変更します。
    </p>
    <%= button_to '緊急ローテーション実行',
        emergency_rotation_admin_admin_path_settings_path,
        method: :post,
        class: 'bg-red-600 text-white px-6 py-2 rounded-lg hover:bg-red-700',
        data: { 
          turbo: false,
          confirm: '緊急ローテーションを実行しますか？URLはランダムに生成されます。' 
        } %>
  </div>

  <!-- 自動ローテーション設定 -->
  <div class="bg-white rounded-lg shadow p-6 mb-6">
    <h2 class="text-xl font-semibold mb-4">自動ローテーション設定</h2>
    <div class="space-y-2">
      <p><strong>有効/無効:</strong> <%= @rotation_enabled ? '有効' : '無効' %></p>
      <p><strong>頻度:</strong> <%= @rotation_frequency %></p>
      <% if @next_rotation_at %>
        <p><strong>次回実行:</strong> <%= l(@next_rotation_at, format: :long) %></p>
      <% end %>
    </div>
    <p class="text-sm text-gray-600 mt-4">
      ※自動ローテーション設定は環境変数で管理されます
    </p>
  </div>

  <!-- 変更履歴 -->
  <div class="bg-white rounded-lg shadow p-6">
    <h2 class="text-xl font-semibold mb-4">変更履歴</h2>
    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">変更日時</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">変更前</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">変更後</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">種別</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">変更者</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <% @histories.each do |history| %>
            <tr>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                <%= l(history.created_at, format: :short) %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                <code><%= history.old_path %></code>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                <code><%= history.new_path %></code>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                <span class="px-2 py-1 text-xs rounded <%= history.emergency? ? 'bg-red-100 text-red-800' : 'bg-blue-100 text-blue-800' %>">
                  <%= history.change_type %>
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                <%= history.admin_user.email %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
  </div>
</div>
```

---

### Step 6: AdminPath::RotationJob実装

**ファイル**: `app/jobs/admin_path/rotation_job.rb`

```ruby
module AdminPath
  class RotationJob < ApplicationJob
    queue_as :default

    def perform
      return unless rotation_enabled?
      return unless rotation_due?

      admin_user = AdminUser.first # システム管理者
      new_path = generate_rotation_path

      result = AdminPath::Updater.new(
        admin_user: admin_user,
        new_path: new_path,
        change_type: :auto_rotation,
        reason: '自動ローテーション'
      ).call

      if result[:success]
        Rails.logger.info("Admin path auto-rotated: #{result[:new_path]}")
      else
        Rails.logger.error("Admin path auto-rotation failed: #{result[:error]}")
      end
    end

    private

    def rotation_enabled?
      ENV.fetch('ADMIN_PATH_ROTATION_ENABLED', 'false') == 'true'
    end

    def rotation_due?
      last_rotation = AdminPathHistory.order(created_at: :desc).first
      return true unless last_rotation

      frequency = ENV.fetch('ADMIN_PATH_ROTATION_FREQUENCY', 'monthly')
      case frequency
      when 'weekly'
        last_rotation.created_at < 1.week.ago
      when 'monthly'
        last_rotation.created_at < 1.month.ago
      when 'quarterly'
        last_rotation.created_at < 3.months.ago
      else
        false
      end
    end

    def generate_rotation_path
      timestamp = Time.current.strftime('%Y%m%d')
      random = SecureRandom.hex(4)
      "admin-secure-#{timestamp}-#{random}"
    end
  end
end
```

---

### Step 7: Sidekiq-cronスケジュール設定

**ファイル**: `config/schedule.yml`（新規作成または追加）

```yaml
# 管理画面URL自動ローテーション（6時間ごとにチェック）
admin_path_rotation:
  cron: "0 */6 * * *"
  class: "AdminPath::RotationJob"
  queue: default
  description: "管理画面URL自動ローテーション"
```

**環境変数設定**: `.env.production`

```bash
# 管理画面URL自動ローテーション設定
ADMIN_PATH_ROTATION_ENABLED=true
ADMIN_PATH_ROTATION_FREQUENCY=monthly  # weekly, monthly, quarterly
```

---

### Step 8: テスト実装

**ファイル**: `spec/models/admin_path_history_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe AdminPathHistory, type: :model do
  describe 'associations' do
    it { should belong_to(:admin_user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:old_path) }
    it { should validate_presence_of(:new_path) }
    it { should validate_presence_of(:change_type) }
  end

  describe 'enums' do
    it { should define_enum_for(:change_type).with_values(manual: 'manual', auto_rotation: 'auto_rotation', emergency: 'emergency') }
  end

  describe 'scopes' do
    let!(:history1) { create(:admin_path_history, created_at: 1.day.ago) }
    let!(:history2) { create(:admin_path_history, created_at: 2.days.ago) }

    it 'returns recent histories' do
      expect(AdminPathHistory.recent).to eq([history1, history2])
    end
  end
end
```

**ファイル**: `spec/services/admin_path/updater_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe AdminPath::Updater do
  let(:admin_user) { create(:admin_user) }
  let(:new_path) { 'new-admin-path-2026' }

  describe '#call' do
    context 'with valid parameters' do
      it 'updates admin path successfully' do
        result = described_class.new(
          admin_user: admin_user,
          new_path: new_path,
          change_type: :manual
        ).call

        expect(result[:success]).to be true
        expect(result[:new_path]).to eq(new_path)
      end

      it 'creates history record' do
        expect {
          described_class.new(
            admin_user: admin_user,
            new_path: new_path,
            change_type: :manual
          ).call
        }.to change(AdminPathHistory, :count).by(1)
      end
    end

    context 'with invalid parameters' do
      it 'raises error for reserved path' do
        expect {
          described_class.new(
            admin_user: admin_user,
            new_path: 'admin',
            change_type: :manual
          ).call
        }.to raise_error(ArgumentError, 'New path is reserved')
      end

      it 'raises error for invalid format' do
        expect {
          described_class.new(
            admin_user: admin_user,
            new_path: 'Admin_Path!',
            change_type: :manual
          ).call
        }.to raise_error(ArgumentError, 'New path must be alphanumeric with hyphens')
      end
    end
  end
end
```

**ファイル**: `spec/jobs/admin_path/rotation_job_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe AdminPath::RotationJob, type: :job do
  let(:admin_user) { create(:admin_user) }

  before do
    allow(ENV).to receive(:fetch).with('ADMIN_PATH_ROTATION_ENABLED', 'false').and_return('true')
    allow(ENV).to receive(:fetch).with('ADMIN_PATH_ROTATION_FREQUENCY', 'monthly').and_return('monthly')
  end

  describe '#perform' do
    context 'when rotation is due' do
      before do
        create(:admin_path_history, created_at: 2.months.ago)
      end

      it 'performs rotation' do
        expect {
          described_class.new.perform
        }.to change(AdminPathHistory, :count).by(1)
      end
    end

    context 'when rotation is not due' do
      before do
        create(:admin_path_history, created_at: 1.day.ago)
      end

      it 'does not perform rotation' do
        expect {
          described_class.new.perform
        }.not_to change(AdminPathHistory, :count)
      end
    end
  end
end
```

---

## 🔧 Phase 7.8統合（通知機能）

Phase 7.8で実装済みの通知機能を使用します。

### 使用するMailer
- `AdminPathMailer#path_changed` - URL変更通知
- `AdminPathMailer#rotation_notification` - 自動ローテーション通知

### 使用するSlackNotifier
- `SlackNotifier#notify_admin_path_changed` - Slack通知

**これらは既に実装済みなので、呼び出すだけでOKです。**

---

## ⚠️ 重要な注意事項

### 1. 環境変数の扱い
- `.env.production` ファイルを直接編集します
- 本番環境では慎重に扱ってください
- バックアップを取ってから変更してください

### 2. ルーティングの再読み込み
- `Rails.application.reload_routes!` を使用します
- 本番環境では影響範囲を確認してください

### 3. セキュリティ
- 予約語チェックを必ず実装してください
- URL形式のバリデーションを厳格に行ってください
- 変更履歴を必ず記録してください

### 4. 通知
- URL変更時は必ず通知を送信してください
- 緊急ローテーション時は即座に通知してください

---

## 🎯 実装のポイント

### 基本実装に集中
- 設計書の実装例をそのまま使用してください
- 過剰な機能追加は避けてください
- シンプルで確実な実装を心がけてください

### Phase 7.1の経験を活かす
- Turbo対応（`data: { turbo: false }`）
- CSP対応（インラインJS排除）
- 確認ダイアログ（`data: { confirm: '...' }`）

### テストは最小限
- 目標15件のテストを実装してください
- エッジケースは後でCodexが追加します
- 基本的な動作確認に集中してください

---

## 📝 実装チェックリスト

### モデル・マイグレーション
- [ ] AdminPathHistoryモデル作成
- [ ] マイグレーション実行
- [ ] バリデーション実装
- [ ] enum設定

### サービス
- [ ] AdminPath::Updater実装
- [ ] バリデーション実装
- [ ] 環境変数更新実装
- [ ] 通知送信実装

### コントローラ
- [ ] Admin::AdminPathSettingsController実装
- [ ] edit アクション実装
- [ ] update アクション実装
- [ ] emergency_rotation アクション実装

### ビュー
- [ ] edit.html.erb実装
- [ ] URL変更フォーム実装
- [ ] 緊急ローテーションボタン実装
- [ ] 変更履歴表示実装

### ジョブ
- [ ] AdminPath::RotationJob実装
- [ ] ローテーション判定ロジック実装
- [ ] パス生成ロジック実装

### 設定
- [ ] ルーティング設定
- [ ] Sidekiq-cronスケジュール設定
- [ ] 環境変数設定

### テスト
- [ ] AdminPathHistory specテスト（5件）
- [ ] AdminPath::Updater specテスト（5件）
- [ ] AdminPath::RotationJob specテスト（5件）

---

## 🤝 Codexとの協働

### 実装完了後
1. 全テストを実行してください
2. 開発環境で動作確認してください
3. Codexに検証を依頼してください

### Codexへの依頼内容
- セキュリティチェック（予約語、バリデーション）
- エッジケーステスト追加
- 本番環境での動作確認
- 既存機能への影響確認

---

## 📚 参考資料

### 設計書
- `.kiro/specs/phase-7-security-operations/design.md`
- Phase 7.2の詳細設計を参照してください

### タスクリスト
- `.kiro/specs/phase-7-security-operations/tasks.md`
- Phase 7.2のタスク一覧を参照してください

### Phase 7.8（通知機能）
- `app/mailers/admin_path_mailer.rb`
- `app/services/slack_notifier.rb`

### Phase 7.1（2FA）の実装例
- `app/controllers/admin/two_factor_auth_controller.rb`
- `app/views/admin/two_factor_auth/`

---

## 🚀 開始方法

### 1. 設計書を確認
```bash
cat .kiro/specs/phase-7-security-operations/design.md
```

### 2. タスクリストを確認
```bash
cat .kiro/specs/phase-7-security-operations/tasks.md
```

### 3. 実装開始
```bash
# Step 1から順番に実装してください
docker compose exec web bin/rails generate model AdminPathHistory ...
```

### 4. テスト実行
```bash
docker compose exec web bundle exec rspec spec/models/admin_path_history_spec.rb
docker compose exec web bundle exec rspec spec/services/admin_path/updater_spec.rb
docker compose exec web bundle exec rspec spec/jobs/admin_path/rotation_job_spec.rb
```

### 5. 動作確認
```bash
# 開発環境で確認
docker compose up
# http://localhost:3000/admin/admin_path_settings/edit にアクセス
```

---

## ✅ 完了条件

### 必須
- [ ] 全11タスク完了
- [ ] 全テスト成功（15件以上）
- [ ] 開発環境での動作確認完了

### オプション
- [ ] E2Eテスト実装（2件）
- [ ] ドキュメント作成

---

**📝 作成者**: Kiro（仕様管理担当）  
**📅 作成日**: 2026-01-23  
**🎯 Phase**: 7.2 管理画面URL管理  
**👨‍💻 実装担当**: Claude Code  
**🔍 検証担当**: Codex  
**📋 レビュー担当**: Kiro

---

## 💬 質問がある場合

仕様の解釈が曖昧な場合や、実装方針の判断が必要な場合は、必ずユーザーに確認してください。

**頑張ってください！Phase 7.1の経験を活かして、高品質な実装を期待しています。**
