class AdminPathHistory < ApplicationRecord
  belongs_to :admin_user

  enum :change_type, {
    manual: "manual",
    auto_rotation: "auto_rotation",
    emergency: "emergency"
  }

  validates :old_path, presence: true
  validates :new_path, presence: true
  validates :change_type, presence: true

  scope :recent, -> { order(created_at: :desc).limit(10) }
  scope :by_type, ->(type) { where(change_type: type) }
end
