class DynamoDBConfig
  Habitat.create do
    setting region : String = ENV["AWS_REGION"]? || "us-east-1"
    setting access_key_id : String = ENV["AWS_ACCESS_KEY_ID"]? || ""
    setting secret_access_key : String = ENV["AWS_SECRET_ACCESS_KEY"]? || ""
    setting endpoint : String? = ENV["DYNAMODB_ENDPOINT"]?
    setting video_progress_table : String = ENV["DYNAMODB_VIDEO_PROGRESS_TABLE"]? || "video_progress"
  end
end

module DynamoDBClient
  extend self

  @@client : Aws::DynamoDB::Client?

  def client : Aws::DynamoDB::Client
    @@client ||= Aws::DynamoDB::Client.new(
      region: settings.region,
      aws_access_key_id: settings.access_key_id,
      aws_secret_access_key: settings.secret_access_key,
      endpoint: settings.endpoint
    )
  end

  def reset_client
    @@client = nil
  end

  private def settings
    DynamoDBConfig.settings
  end
end
