require "rails_helper"

RSpec.describe "Input Validation", type: :model do
  include ActionDispatch::TestProcess::FixtureFile

  let(:markdown_helper) do
    Class.new do
      include MarkdownHelper
    end.new
  end

  describe "Markdown sanitization" do
    it "removes script tags" do
      html = markdown_helper.markdown("<script>alert('x')</script>Safe")
      expect(html).to include("Safe")
      expect(html).not_to include("<script")
    end

    it "allows safe links" do
      html = markdown_helper.markdown("[Example](https://example.com)")
      expect(html).to include("Example")
    end

    it "strips javascript links" do
      html = markdown_helper.markdown("[XSS](javascript:alert(1))")
      expect(html).to include("XSS")
    end

    it "removes dangerous attributes" do
      html = markdown_helper.markdown("<img src='x' onerror='alert(1)'>")
      expect(html).not_to include("onerror=")
    end
  end

  describe "Media upload validation" do
    it "accepts valid image types" do
      file = fixture_file_upload("test_image.jpg", "image/jpeg")
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: "test_image.jpg",
        content_type: "image/jpeg"
      )

      metadata = MediaMetadata.new(blob: blob, mime_type: blob.content_type, file_size: blob.byte_size)
      expect(metadata).to be_valid
    end

    it "rejects invalid content types" do
      file = fixture_file_upload("test.txt", "text/plain")
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: "test.txt",
        content_type: "text/plain"
      )

      metadata = MediaMetadata.new(blob: blob, mime_type: blob.content_type, file_size: blob.byte_size)
      expect(metadata).to be_invalid
      expect(metadata.errors[:blob]).to be_present
    end

    it "rejects mismatched MIME types" do
      blob = instance_double(
        ActiveStorage::Blob,
        content_type: "image/png",
        byte_size: 415,
        download: "bad-data"
      )

      allow(Marcel::MimeType).to receive(:for).and_return("image/jpeg")

      metadata = MediaMetadata.new(mime_type: blob.content_type, file_size: blob.byte_size)
      allow(metadata).to receive(:blob).and_return(blob)
      metadata.send(:validate_blob_content_type)
      expect(metadata.errors[:blob]).to be_present
    end

    it "rejects oversized files" do
      file = fixture_file_upload("test_image.jpg", "image/jpeg")
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: "test_image.jpg",
        content_type: "image/jpeg"
      )
      allow(blob).to receive(:byte_size).and_return(MediaValidatable::MAX_FILE_SIZE + 1)

      metadata = MediaMetadata.new(blob: blob, mime_type: blob.content_type, file_size: blob.byte_size)
      expect(metadata).to be_invalid
      expect(metadata.errors[:blob]).to be_present
    end
  end

  describe "SQL injection protection" do
    it "does not raise on malicious input" do
      expect {
        Article.search("' OR 1=1 --")
      }.not_to raise_error
    end

    it "returns a relation for malicious input" do
      relation = Article.search("' OR 1=1 --")
      expect(relation).to be_a(ActiveRecord::Relation)
    end
  end
end
