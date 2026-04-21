require "aws-sdk-s3"

class S3Service
  attr_reader :client, :bucket_name

  def initialize
    @client = Aws::S3::Client.new(
      region: ENV.fetch("AWS_BACKUP_REGION", "ap-northeast-1"),
      access_key_id: ENV.fetch("AWS_BACKUP_ACCESS_KEY_ID"),
      secret_access_key: ENV.fetch("AWS_BACKUP_SECRET_ACCESS_KEY")
    )
    @bucket_name = ENV.fetch("S3_BACKUP_BUCKET", "portfolio-backup-miyakawa-codes")
  end

  def upload(file_path:, backup_type:, category:)
    file_name = File.basename(file_path)
    timestamp = Time.current

    object_key = build_object_key(backup_type, timestamp, category, file_name)
    checksum = Digest::SHA256.file(file_path).hexdigest

    File.open(file_path, "rb") do |file|
      client.put_object(
        bucket: bucket_name,
        key: object_key,
        body: file,
        server_side_encryption: "AES256",
        metadata: {
          "backup-type" => backup_type,
          "category" => category,
          "timestamp" => timestamp.iso8601,
          "checksum" => checksum
        }
      )
    end

    Rails.logger.info("S3Service: uploaded key=#{object_key}")
    object_key
  end

  def list_backups(backup_type: nil, category: nil)
    prefix = backup_type ? "#{backup_type}/" : ""

    response = client.list_objects_v2(bucket: bucket_name, prefix: prefix)

    objects = response.contents.map do |obj|
      {
        key: obj.key,
        size: obj.size,
        last_modified: obj.last_modified,
        etag: obj.etag
      }
    end

    category ? objects.select { |obj| obj[:key].include?("/#{category}_") } : objects
  end

  def download(object_key:, destination:)
    FileUtils.mkdir_p(File.dirname(destination))

    client.get_object(
      bucket: bucket_name,
      key: object_key,
      response_target: destination
    )

    Rails.logger.info("S3Service: downloaded key=#{object_key}")
  end

  def delete(object_key:)
    client.delete_object(bucket: bucket_name, key: object_key)
    Rails.logger.info("S3Service: deleted key=#{object_key}")
  end

  def get_latest_backup_size(backup_type)
    list_backups(backup_type: backup_type).sum { |obj| obj[:size] }
  end

  private

  def build_object_key(backup_type, timestamp, category, file_name)
    [
      backup_type,
      timestamp.strftime("%Y"),
      timestamp.strftime("%m"),
      timestamp.strftime("%d"),
      "#{category}_#{file_name}"
    ].join("/")
  end
end
