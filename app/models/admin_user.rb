class AdminUser < ApplicationRecord
  # NOTE: :registerable is intentionally disabled for security
  # Future: Re-enable when implementing multi-tenant CMS sales version
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable,
         :lockable, :timeoutable
  
  has_many :published_section_contents, class_name: "SectionContent", foreign_key: :published_by, dependent: :nullify
  has_many :articles, dependent: :destroy
  has_many :ai_generations, dependent: :nullify
  
  validates :email, presence: true, uniqueness: true
end
