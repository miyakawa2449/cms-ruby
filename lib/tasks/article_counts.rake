namespace :article_counts do
  desc "カテゴリ・タグのarticle_countを実データ（公開記事数）から再計算する"
  task recalculate: :environment do
    puts "Recalculating article counts..."
    Category.find_each(&:refresh_article_count!)
    Tag.find_each(&:refresh_article_count!)
    puts "Done: #{Category.count} categories, #{Tag.count} tags"
  end
end
