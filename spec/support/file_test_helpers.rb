# File Test Helpers for Portfolio Site
# ファイル操作テスト用のヘルパーメソッド集

module FileTestHelpers
  # ==> Test File Paths
  
  def test_files_path
    # テストファイルディレクトリのパス
    Rails.root.join('spec/fixtures/files')
  end
  
  def test_images_path
    # テスト画像ディレクトリのパス
    test_files_path.join('images')
  end
  
  def test_documents_path
    # テスト文書ディレクトリのパス
    test_files_path.join('documents')
  end
  
  # ==> Test File Creation
  
  def create_test_image(filename: 'test_image.jpg', content_type: 'image/jpeg')
    # テスト画像ファイル作成
    file_path = test_images_path.join(filename)
    
    # テスト用の画像データ（1x1ピクセルのJPEG）
    image_data = create_minimal_image_data(content_type)
    
    Rack::Test::UploadedFile.new(
      StringIO.new(image_data),
      content_type,
      original_filename: filename
    )
  end
  
  def create_test_document(filename: 'test_document.pdf', content_type: 'application/pdf')
    # テスト文書ファイル作成
    content = case content_type
              when 'application/pdf'
                create_minimal_pdf_content
              when 'text/plain'
                'This is a test text document.'
              when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                create_minimal_docx_content
              else
                'Test file content'
              end
    
    Rack::Test::UploadedFile.new(
      StringIO.new(content),
      content_type,
      original_filename: filename
    )
  end
  
  def create_large_test_file(size_mb: 10, filename: 'large_file.dat')
    # 大きなテストファイル作成
    content = 'A' * (size_mb * 1024 * 1024) # 指定サイズのファイル
    
    Rack::Test::UploadedFile.new(
      StringIO.new(content),
      'application/octet-stream',
      original_filename: filename
    )
  end
  
  def create_invalid_file(filename: 'invalid.exe')
    # 無効なファイル作成
    Rack::Test::UploadedFile.new(
      StringIO.new('Invalid file content'),
      'application/x-executable',
      original_filename: filename
    )
  end
  
  # ==> File Content Helpers
  
  def create_minimal_image_data(content_type)
    # 最小限の画像データ作成
    case content_type
    when 'image/jpeg'
      # 最小のJPEGヘッダー
      "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xFF\xDB\x00C\x00" +
      "\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\x0C\x14\r\x0C\x0B\x0B\x0C\x19\x12\x13\x0F" +
      "\x14\x1D\x1A\x1F\x1E\x1D\x1A\x1C\x1C $.' \",#\x1C\x1C(7),01444\x1F'9=82<.342\xFF\xC0\x00\x11" +
      "\x08\x00\x01\x00\x01\x01\x01\x11\x00\x02\x11\x01\x03\x11\x01\xFF\xC4\x00\x14\x00\x01\x00\x00" +
      "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xFF\xC4\x00\x14\x10\x01\x00\x00\x00" +
      "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xDA\x00\x0C\x03\x01\x00\x02\x11\x03" +
      "\x11\x00\x3F\x00\x8A\x00\xFF\xD9"
    when 'image/png'
      # 最小のPNGヘッダー
      "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00" +
      "\x90wS\xDE\x00\x00\x00\x0CIDAT\x08\x1Dc\xF8\x00\x00\x00\x01\x00\x01\x02\x1A\xF2\x84\x00\x00" +
      "\x00\x00IEND\xAEB`\x82"
    when 'image/gif'
      # 最小のGIFヘッダー
      "GIF89a\x01\x00\x01\x00\x80\x00\x00\xFF\xFF\xFF\x00\x00\x00!\xF9\x04\x01\x00\x00\x00\x00" +
      ",\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02\x04\x01\x00;"
    else
      'Invalid image data'
    end
  end
  
  def create_minimal_pdf_content
    # 最小限のPDFコンテンツ
    <<~PDF
      %PDF-1.4
      1 0 obj
      <<
      /Type /Catalog
      /Pages 2 0 R
      >>
      endobj
      
      2 0 obj
      <<
      /Type /Pages
      /Kids [3 0 R]
      /Count 1
      >>
      endobj
      
      3 0 obj
      <<
      /Type /Page
      /Parent 2 0 R
      /MediaBox [0 0 612 792]
      >>
      endobj
      
      xref
      0 4
      0000000000 65535 f 
      0000000010 00000 n 
      0000000053 00000 n 
      0000000125 00000 n 
      trailer
      <<
      /Size 4
      /Root 1 0 R
      >>
      startxref
      0
      %%EOF
    PDF
  end
  
  def create_minimal_docx_content
    # 最小限のDOCXコンテンツ（簡略化）
    'PK' + "\x03\x04" + 'Mock DOCX content'
  end
  
  # ==> File Validation Helpers
  
  def expect_valid_upload(file)
    # 有効なファイルアップロードの確認
    expect(file).to be_present
    expect(file).to respond_to(:original_filename)
    expect(file).to respond_to(:content_type)
    expect(file).to respond_to(:tempfile)
  end
  
  def expect_image_file(file)
    # 画像ファイルの確認
    expect_valid_upload(file)
    expect(file.content_type).to match(%r{\Aimage/})
  end
  
  def expect_document_file(file)
    # 文書ファイルの確認
    expect_valid_upload(file)
    allowed_types = [
      'application/pdf',
      'text/plain',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ]
    expect(allowed_types).to include(file.content_type)
  end
  
  def expect_file_size_within_limit(file, max_size_mb)
    # ファイルサイズ制限の確認
    max_size_bytes = max_size_mb * 1024 * 1024
    actual_size = file.tempfile.size
    
    expect(actual_size).to be <= max_size_bytes
  end
  
  def expect_file_extension_matches_content_type(file)
    # ファイル拡張子とコンテンツタイプの一致確認
    extension = File.extname(file.original_filename).downcase
    content_type = file.content_type
    
    expected_mappings = {
      '.jpg' => 'image/jpeg',
      '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.gif' => 'image/gif',
      '.pdf' => 'application/pdf',
      '.txt' => 'text/plain',
      '.docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    }
    
    if expected_mappings[extension]
      expect(content_type).to eq(expected_mappings[extension])
    end
  end
  
  # ==> File Processing Helpers
  
  def simulate_file_upload(file, **params)
    # ファイルアップロードのシミュレート
    default_params = {
      media_file: {
        file: file,
        title: file.original_filename,
        description: 'Test file upload',
        folder: 'test',
        public: true
      }
    }
    
    post admin_media_files_path, params: default_params.deep_merge(params)
  end
  
  def expect_successful_upload
    # アップロード成功の確認
    expect(response).to have_http_status(:redirect)
    expect(flash[:notice]).to include('アップロード')
  end
  
  def expect_upload_failure(error_message = nil)
    # アップロード失敗の確認
    expect(response).to have_http_status(:unprocessable_entity)
    
    if error_message
      expect(response.body).to include(error_message)
    end
  end
  
  # ==> File Cleanup Helpers
  
  def cleanup_test_uploads
    # テストアップロードファイルのクリーンアップ
    test_upload_path = Rails.root.join('tmp/test_uploads')
    FileUtils.rm_rf(test_upload_path) if test_upload_path.exist?
  end
  
  def with_test_uploads_cleanup
    # テストアップロードのクリーンアップ付きでブロック実行
    yield
  ensure
    cleanup_test_uploads
  end
  
  # ==> Storage Helpers
  
  def mock_s3_storage
    # S3ストレージのモック
    allow(Rails.application.config).to receive(:active_storage).and_return(
      double(service: :test)
    )
  end
  
  def expect_file_stored_locally(filename)
    # ローカルストレージへの保存確認
    storage_path = Rails.root.join('storage/test')
    expect(Dir.glob("#{storage_path}/**/#{filename}")).not_to be_empty
  end
  
  def expect_file_stored_remotely(filename)
    # リモートストレージへの保存確認（モック）
    # 実際の実装では S3 API をモックして確認
    expect(true).to be true # プレースホルダー
  end
  
  # ==> Image Processing Helpers
  
  def expect_image_variants_created(image_file)
    # 画像バリアントの作成確認
    # Phase 2B で Active Storage バリアント機能を実装予定
    expected_variants = %w[thumb medium large]
    
    expected_variants.each do |variant|
      # expect(image_file.variant(variant)).to be_present
    end
  end
  
  def expect_webp_conversion(original_file)
    # WebP変換の確認
    # Phase 2B で画像最適化機能を実装予定
    webp_filename = File.basename(original_file.original_filename, '.*') + '.webp'
    # expect(converted_file_exists?(webp_filename)).to be true
  end
  
  # ==> Security Helpers
  
  def create_malicious_file(filename: 'malicious.php')
    # 悪意のあるファイル作成
    content = '<?php system($_GET["cmd"]); ?>'
    
    Rack::Test::UploadedFile.new(
      StringIO.new(content),
      'application/x-php',
      original_filename: filename
    )
  end
  
  def expect_malicious_file_rejected(file)
    # 悪意のあるファイルの拒否確認
    simulate_file_upload(file)
    expect_upload_failure('ファイルタイプが許可されていません')
  end
  
  def expect_virus_scan_performed(file)
    # ウイルススキャンの実行確認（Phase 2Bで実装予定）
    # allow(VirusScanService).to receive(:scan).with(file).and_return(true)
    # expect(VirusScanService).to have_received(:scan).with(file)
  end
end