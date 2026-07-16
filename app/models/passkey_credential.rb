class PasskeyCredential < ApplicationRecord
  # sign_countが逆行した = 認証器のカウンタが戻った = 秘密鍵が複製された疑い
  # （WebAuthn仕様 §6.1.1 のクローン検知）
  class CloneDetectedError < StandardError; end

  MAX_PER_USER = 10

  belongs_to :admin_user

  validates :external_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :nickname, presence: true, length: { maximum: 100 },
                       uniqueness: { scope: :admin_user_id }
  validates :sign_count, presence: true,
                         numericality: { greater_than_or_equal_to: 0 }
  validate :within_registration_limit, on: :create

  scope :recently_used_first, -> { order(last_used_at: :desc, created_at: :desc) }

  # 認証成功時に呼ぶ。カウンタ更新とクローン検知を行う
  def record_usage!(sign_count:)
    new_count = sign_count.to_i

    # 保存済みカウンタが正の値なのに増えていない場合はクローンの疑い。
    # カウンタ非対応の認証器（常に0）は保存値も0のままなので検知対象にならない
    raise CloneDetectedError if self.sign_count.positive? && new_count <= self.sign_count

    update!(sign_count: new_count, last_used_at: Time.current)
  end

  private

  def within_registration_limit
    return unless admin_user
    return if admin_user.passkey_credentials.count < MAX_PER_USER

    errors.add(:base, "パスキーの登録上限（#{MAX_PER_USER}個）に達しています")
  end
end
