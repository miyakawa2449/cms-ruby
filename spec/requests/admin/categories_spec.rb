require 'rails_helper'

RSpec.describe 'Admin::Categories', type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    host! "localhost"
    sign_in admin_user, scope: :admin_user
  end

  it 'renders index' do
    get admin_categories_path

    expect(response).to have_http_status(:success)
  end

  it 'shows a category' do
    category = create(:category)

    get admin_category_path(category)

    expect(response).to have_http_status(:success)
  end

  it 'creates a category' do
    expect {
      post admin_categories_path, params: { category: attributes_for(:category) }
    }.to change(Category, :count).by(1)
  end

  it 'updates a category' do
    category = create(:category)

    patch admin_category_path(category), params: { category: { name: 'Updated' } }

    expect(category.reload.name).to eq('Updated')
  end

  it 'prevents deletion when category has articles' do
    category = create(:category)
    article = create(:article)
    article.categories << category

    delete admin_category_path(category)

    expect(response).to redirect_to(admin_categories_path)
    expect(Category.exists?(category.id)).to eq(true)
  end

  it 'deletes category without articles' do
    category = create(:category)

    expect {
      delete admin_category_path(category)
    }.to change(Category, :count).by(-1)
  end

  it 'moves category up and down' do
    other = create(:category, position: 0)
    category = create(:category, position: 1)

    patch move_up_admin_category_path(category)
    expect(category.reload.position).to eq(0)

    patch move_down_admin_category_path(category)
    expect(category.reload.position).to eq(1)
  end

  it 'does nothing when there is no neighbor to swap with' do
    # 隣が存在しない（最上位/最下位）場合は位置を変えない
    category = create(:category, position: 1)

    patch move_up_admin_category_path(category)

    expect(category.reload.position).to eq(1)
  end

  it 'swaps positions with the neighboring category (no duplicates)' do
    # 監査M-16の回帰テスト: 旧実装は隣とスワップせず position を±1するだけで、
    # 同じpositionを持つカテゴリが複数できてしまっていた
    first = create(:category, position: 0)
    second = create(:category, position: 1)

    patch move_up_admin_category_path(second)

    expect(second.reload.position).to eq(0)
    expect(first.reload.position).to eq(1)
    expect(Category.pluck(:position).tally.values.max).to eq(1)
  end
end
