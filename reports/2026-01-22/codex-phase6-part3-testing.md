# Phase 6: Part 3 - テストガイド

**Phase**: 6  
**Part**: 3/4  
**作成日**: 2026-01-22  
**担当**: Codex

---

## 📋 テストの進め方

Phase 6 のテストは、以下の順序で作成してください：

1. セキュリティヘッダーのテスト
2. 認証・認可のテスト
3. レート制限のテスト
4. 入力検証のテスト
5. CSRF・セッション管理のテスト
6. SecurityLogger のテスト
7. 統合テスト・E2Eテスト

**目標**: 100件以上のテスト、カバレッジ 90% 以上

---

## 🧪 Task 5: セキュリティヘッダーのテスト

### 5.1 ヘッダーテストの作成

**ファイル**: `spec/security/headers_spec.rb`（新規作成）

```ruby
# spec/security/headers_spec.rb

require 'rails_helper'

RSpec.describe 'Security Headers', type: :request do
  describe 'Content Security Policy' do
    it 'sets CSP header' do
      get root_path
      expect(response.headers['Content-Security-Policy']).to be_present
    end
    
    it 'includes default-src directive' do
      get root_path
      csp = response.headers['Content-Security-Policy']
      expect(csp).to include('default-src')
    end
    
    it 'includes script-src directive' do
      get root_path
      csp = response.headers['Content-Security-Policy']
      expect(csp).to include('script-src')
    end
    
    it 'includes style-src directive' do
      get root_path
      csp = response.headers['Content-Security-Policy']
      expect(csp).to include('style-src')
    end
    
    it 'sets object-src to none' do
      get root_path
      csp = response.headers['Content-Security-Policy']
      expect(csp).to include('object-src \'none\'')
    end
  end
  
  describe 'X-Frame-Options' do
    it 'sets X-Frame-Options header' do
      get root_path
      expect(response.headers['X-Frame-Options']).to eq('SAMEORIGIN')
    end
    
    it 'prevents clickjacking' do
      get admin_root_path
      expect(response.headers['X-Frame-Options']).to eq('SAMEORIGIN')
    end
  end
  
  describe 'X-Content-Type-Options' do
    it 'sets X-Content-Type-Options header' do
      get root_path
      expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
    end
    
    it 'prevents MIME sniffing' do
      get blog_path
      expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
    end
  end
  
  describe 'Referrer-Policy' do
    it 'sets Referrer-Policy header' do
      get root_path
      expect(response.headers['Referrer-Policy']).to eq('strict-origin-when-cross-origin')
    end
  end
  
  describe 'Permissions-Policy' do
    it 'sets Permissions-Policy header' do
      get root_path
      expect(response.headers['Permissions-Policy']).to be_present
    end
    
    it 'disables geolocation' do
      get root_path
      policy = response.headers['Permissions-Policy']
      expect(policy).to include('geolocation=()')
    end
    
    it 'disables microphone' do
      get root_path
      policy = response.headers['Permissions-Policy']
      expect(policy).to include('microphone=()')
    end
    
    it 'disables camera' do
      get root_path
      policy = response.headers['Permissions-Policy']
      expect(policy).to include('camera=()')
    end
  end
  
  describe 'X-XSS-Protection' do
    it 'sets X-XSS-Protection header' do
      get root_path
      expect(response.headers['X-XSS-Protection']).to eq('1; mode=block')
    end
  end
  
  # プロパティベーステスト
  describe 'Property: All responses include security headers' do
    let(:paths) { [root_path, blog_path, portfolio_path] }
    
    it 'includes required headers on all pages' do
      paths.each do |path|
        get path
        
        expect(response.headers['X-Frame-Options']).to be_present
        expect(response.headers['X-Content-Type-Options']).to be_present
        expect(response.headers['Referrer-Policy']).to be_present
        expect(response.headers['Content-Security-Policy']).to be_present
      end
    end
  end
end
```

**テストのポイント**:
- すべての推奨ヘッダーをテスト
- 複数のパスでヘッダーが設定されることを確認
- プロパティベーステストを含める

**推定テスト数**: 20件

---

## 🧪 Task 6: 認証・認可のテスト

### 6.1 認証テストの作成

**ファイル**: `spec/security/authentication_spec.rb`（新規作成）

```ruby
# spec/security/authentication_spec.rb

require 'rails_helper'

RSpec.describe 'Authentication Security', type: :request do
  let(:admin_user) { create(:admin_user, password: 'ADMIN_PASSWORD') }
  
  describe 'Login' do
    it 'allows login with valid credentials' do
      post admin_user_session_path, params: {
        admin_user: { email: admin_user.email, password: 'ADMIN_PASSWORD' }
      }
      
      expect(response).to redirect_to(admin_root_path)
    end
    
    it 'rejects login with invalid password' do
      post admin_user_session_path, params: {
        admin_user: { email: admin_user.email, password: 'wrong' }
      }
      
      expect(response).to have_http_status(:unprocessable_entity)
    end
    
    it 'rejects login with non-existent email' do
      post admin_user_session_path, params: {
        admin_user: { email: 'nonexistent@example.com', password: 'ADMIN_PASSWORD' }
      }
      
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
  
  describe 'Account Lockout' do
    it 'locks account after 5 failed attempts' do
      5.times do
        post admin_user_session_path, params: {
          admin_user: { email: admin_user.email, password: 'wrong' }
        }
      end
      
      admin_user.reload
      expect(admin_user.access_locked?).to be true
    end
    
    it 'shows lockout message' do
      admin_user.lock_access!
      
      post admin_user_session_path, params: {
        admin_user: { email: admin_user.email, password: 'ADMIN_PASSWORD' }
      }
      
      expect(response.body).to include('アカウントがロックされています')
    end
    
    it 'unlocks account after unlock period' do
      admin_user.lock_access!
      admin_user.update(locked_at: 2.hours.ago)
      
      post admin_user_session_path, params: {
        admin_user: { email: admin_user.email, password: 'ADMIN_PASSWORD' }
      }
      
      expect(response).to redirect_to(admin_root_path)
    end
  end
  
  describe 'Session Timeout' do
    before { sign_in admin_user }
    
    it 'expires session after timeout period' do
      travel 31.minutes do
        get admin_root_path
        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end
    
    it 'maintains session within timeout period' do
      travel 29.minutes do
        get admin_root_path
        expect(response).to have_http_status(:success)
      end
    end
  end
  
  describe 'Password Reset' do
    it 'sends password reset email' do
      expect {
        post admin_user_password_path, params: {
          admin_user: { email: admin_user.email }
        }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
    
    it 'does not reveal if email exists' do
      post admin_user_password_path, params: {
        admin_user: { email: 'nonexistent@example.com' }
      }
      
      expect(response).to redirect_to(new_admin_user_session_path)
      expect(flash[:notice]).to be_present
    end
  end
  
  describe 'Logout' do
    before { sign_in admin_user }
    
    it 'logs out successfully' do
      delete destroy_admin_user_session_path
      
      expect(response).to redirect_to(root_path)
    end
    
    it 'clears session' do
      delete destroy_admin_user_session_path
      
      get admin_root_path
      expect(response).to redirect_to(new_admin_user_session_path)
    end
  end
end
```

**推定テスト数**: 15件

### 6.2 認可テストの作成

**ファイル**: `spec/security/authorization_spec.rb`（新規作成）

```ruby
# spec/security/authorization_spec.rb

require 'rails_helper'

RSpec.describe 'Authorization Security', type: :request do
  let(:admin_user) { create(:admin_user) }
  
  describe 'Admin Access Control' do
    context 'when not authenticated' do
      it 'redirects to login page' do
        get admin_root_path
        expect(response).to redirect_to(new_admin_user_session_path)
      end
      
      it 'blocks access to admin articles' do
        get admin_articles_path
        expect(response).to redirect_to(new_admin_user_session_path)
      end
      
      it 'blocks access to admin settings' do
        get admin_site_settings_path
        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end
    
    context 'when authenticated' do
      before { sign_in admin_user }
      
      it 'allows access to admin dashboard' do
        get admin_root_path
        expect(response).to have_http_status(:success)
      end
      
      it 'allows access to admin articles' do
        get admin_articles_path
        expect(response).to have_http_status(:success)
      end
      
      it 'allows access to admin settings' do
        get admin_site_settings_path
        expect(response).to have_http_status(:success)
      end
    end
  end
  
  describe 'Public Access' do
    it 'allows access to public pages' do
      get root_path
      expect(response).to have_http_status(:success)
    end
    
    it 'allows access to blog' do
      get blog_path
      expect(response).to have_http_status(:success)
    end
    
    it 'allows access to portfolio' do
      get portfolio_path
      expect(response).to have_http_status(:success)
    end
  end
  
  # プロパティベーステスト
  describe 'Property: All admin routes require authentication' do
    let(:admin_routes) do
      Rails.application.routes.routes
        .select { |r| r.path.spec.to_s.start_with?('/admin') }
        .map { |r| r.path.spec.to_s.gsub(/\(.*?\)/, '') }
        .uniq
        .reject { |p| p.include?('sign_in') || p.include?('sign_out') || p.include?('password') }
    end
    
    it 'redirects unauthenticated users' do
      admin_routes.sample(5).each do |path|
        get path.gsub(':id', '1').gsub(':format', 'html')
        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end
  end
end
```

**推定テスト数**: 15件

---

## 🧪 Task 7: レート制限のテスト

### 7.1 レート制限テストの作成

**ファイル**: `spec/security/rate_limiting_spec.rb`（新規作成）

```ruby
# spec/security/rate_limiting_spec.rb

require 'rails_helper'

RSpec.describe 'Rate Limiting', type: :request do
  before do
    # Rack::Attack のキャッシュをクリア
    Rack::Attack.cache.store.clear
  end
  
  describe 'Login Rate Limiting' do
    it 'allows 5 login attempts' do
      5.times do
        post admin_user_session_path, params: {
          admin_user: { email: 'test@example.com', password: 'wrong' }
        }
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
    
    it 'blocks 6th login attempt' do
      6.times do
        post admin_user_session_path, params: {
          admin_user: { email: 'test@example.com', password: 'wrong' }
        }
      end
      
      expect(response).to have_http_status(:too_many_requests)
    end
    
    it 'includes Retry-After header' do
      6.times do
        post admin_user_session_path, params: {
          admin_user: { email: 'test@example.com', password: 'wrong' }
        }
      end
      
      expect(response.headers['Retry-After']).to be_present
    end
    
    it 'returns JSON error message' do
      6.times do
        post admin_user_session_path, params: {
          admin_user: { email: 'test@example.com', password: 'wrong' }
        }
      end
      
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Too Many Requests')
    end
  end
  
  describe 'Password Reset Rate Limiting' do
    it 'allows 5 password reset requests' do
      5.times do
        post admin_user_password_path, params: {
          admin_user: { email: 'test@example.com' }
        }
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
    
    it 'blocks 6th password reset request' do
      6.times do
        post admin_user_password_path, params: {
          admin_user: { email: 'test@example.com' }
        }
      end
      
      expect(response).to have_http_status(:too_many_requests)
    end
  end
  
  describe 'API Rate Limiting' do
    context 'unauthenticated' do
      it 'allows 60 requests per minute' do
        60.times do
          get api_v1_articles_path
          expect(response).not_to have_http_status(:too_many_requests)
        end
      end
      
      it 'blocks 61st request' do
        61.times do
          get api_v1_articles_path
        end
        
        expect(response).to have_http_status(:too_many_requests)
      end
    end
    
    context 'authenticated' do
      let(:admin_user) { create(:admin_user) }
      before { sign_in admin_user }
      
      it 'allows 300 requests per minute' do
        100.times do  # テストでは100回に制限
          get api_v1_articles_path
          expect(response).not_to have_http_status(:too_many_requests)
        end
      end
    end
  end
  
  describe 'Contact Form Rate Limiting' do
    it 'allows 5 submissions per hour' do
      5.times do
        post contacts_path, params: {
          contact: {
            name: 'Test',
            email: 'test@example.com',
            subject: 'Test',
            message: 'Test message'
          }
        }
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
    
    it 'blocks 6th submission' do
      6.times do
        post contacts_path, params: {
          contact: {
            name: 'Test',
            email: 'test@example.com',
            subject: 'Test',
            message: 'Test message'
          }
        }
      end
      
      expect(response).to have_http_status(:too_many_requests)
    end
  end
  
  # プロパティベーステスト
  describe 'Property: Rate limiting consistently blocks excessive requests' do
    it 'always returns 429 after limit exceeded' do
      10.times do
        post admin_user_session_path, params: {
          admin_user: { email: 'test@example.com', password: 'wrong' }
        }
      end
      
      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers['Retry-After']).to be_present
    end
  end
end
```

**推定テスト数**: 20件

---

## 🧪 Task 8-10: その他のテスト

### 8. 入力検証のテスト（15件）
### 9. CSRF・セッション管理のテスト（15件）
### 10. SecurityLogger のテスト（10件）

これらのテストは、Part 2 の実装に基づいて作成してください。

---

## 🧪 Task 11: 統合テスト・E2Eテスト

### 11.1 ログインセキュリティのE2Eテスト

**ファイル**: `spec/system/security/login_security_spec.rb`（新規作成）

```ruby
# spec/system/security/login_security_spec.rb

require 'rails_helper'

RSpec.describe 'Login Security', type: :system do
  let(:admin_user) { create(:admin_user, password: 'ADMIN_PASSWORD') }
  
  describe 'Login Flow' do
    it 'logs in successfully with valid credentials' do
      visit new_admin_user_session_path
      
      fill_in 'Email', with: admin_user.email
      fill_in 'Password', with: 'ADMIN_PASSWORD'
      click_button 'ログイン'
      
      expect(page).to have_current_path(admin_root_path)
      expect(page).to have_content('ログインしました')
    end
    
    it 'shows error with invalid credentials' do
      visit new_admin_user_session_path
      
      fill_in 'Email', with: admin_user.email
      fill_in 'Password', with: 'wrong'
      click_button 'ログイン'
      
      expect(page).to have_content('メールアドレスまたはパスワードが違います')
    end
  end
  
  describe 'Account Lockout' do
    it 'locks account after 5 failed attempts' do
      visit new_admin_user_session_path
      
      5.times do
        fill_in 'Email', with: admin_user.email
        fill_in 'Password', with: 'wrong'
        click_button 'ログイン'
      end
      
      expect(page).to have_content('アカウントがロックされています')
    end
  end
  
  describe 'Session Timeout' do
    it 'expires session after timeout' do
      login_as(admin_user, scope: :admin_user)
      visit admin_root_path
      
      travel 31.minutes do
        visit admin_articles_path
        expect(page).to have_current_path(new_admin_user_session_path)
      end
    end
  end
end
```

**推定テスト数**: 10件

---

## 📊 テスト目標

### テスト数の内訳

| カテゴリ | 推定テスト数 |
|---------|------------|
| セキュリティヘッダー | 20件 |
| 認証・認可 | 30件 |
| レート制限 | 20件 |
| 入力検証 | 15件 |
| CSRF・セッション | 15件 |
| SecurityLogger | 10件 |
| 統合テスト・E2E | 10件 |
| **合計** | **120件** |

**目標**: 100件以上 ✅

---

## 🚀 次のステップ

Part 3 を読み終えたら、Part 4（成果物と報告）に進んでください。

```
reports/2026-01-22/codex-phase6-part4-deliverables.md
```

---

**作成者**: Kiro（仕様管理担当）  
**作成日**: 2026-01-22  
**次のステップ**: Part 4 を読む
