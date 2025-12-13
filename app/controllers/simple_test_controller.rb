class SimpleTestController < ApplicationController
  def index
    begin
      @test_items = TestItem.all
      
      response_text = [
        "✅ Rails Web Request SUCCESS!",
        "📊 Database Connection: OK", 
        "🗃️ Test Items Count: #{@test_items.count}",
        "📝 Items: #{@test_items.map(&:name).join(', ')}"
      ].join("\n")
      
      render plain: response_text
    rescue => e
      error_text = [
        "❌ Error occurred:",
        "🔍 Class: #{e.class}",
        "💬 Message: #{e.message}",
        "📍 Backtrace: #{e.backtrace&.first}"
      ].join("\n")
      
      render plain: error_text
    end
  end
end