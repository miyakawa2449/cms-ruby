class AdminUser < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  has_many :published_section_contents, class_name: "SectionContent", foreign_key: :published_by, dependent: :nullify
  has_many :articles, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true
end
