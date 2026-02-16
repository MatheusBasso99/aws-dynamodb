require "../src/aws-dynamodb"
require "./video_progress_model"

class VideoProgressRepository
  TABLE_NAME = "video_progress"

  def initialize(@client : Aws::DynamoDB::Client)
  end

  def save(progress : VideoProgress) : VideoProgress
    progress.updated_at = Time.utc

    @client.put_item(
      TableName: TABLE_NAME,
      Item: progress.to_dynamodb_item
    )

    progress
  end

  def find(user_id : String, video_id : String) : VideoProgress?
    response = @client.get_item(
      TableName: TABLE_NAME,
      Key: {
        user_id:  {S: user_id},
        video_id: {S: video_id},
      }
    )

    if item = response[:Item]
      VideoProgress.from_dynamodb(item)
    end
  rescue Aws::DynamoDB::Http::ServerError
    nil
  end

  def update_position(user_id : String, video_id : String, position : Float64, duration : Float64) : VideoProgress
    now = Time.utc
    percentage = duration > 0 ? ((position / duration) * 100).round(2) : 0.0
    completed = percentage >= 95.0

    @client.update_item(
      TableName: TABLE_NAME,
      Key: {
        user_id:  {S: user_id},
        video_id: {S: video_id},
      },
      UpdateExpression: "SET watch_position = :pos, duration = :dur, percentage = :pct, completed = :comp, last_watched_at = :lwa, updated_at = :ua",
      ExpressionAttributeValues: {
        ":pos":  {N: position},
        ":dur":  {N: duration},
        ":pct":  {N: percentage},
        ":comp": {BOOL: completed},
        ":lwa":  {S: now.to_rfc3339},
        ":ua":   {S: now.to_rfc3339},
      },
      ReturnValues: "ALL_NEW"
    )

    find(user_id, video_id).not_nil!
  end

  def find_all_by_user(user_id : String, limit : Int32 = 50) : Array(VideoProgress)
    response = @client.query(
      TableName: TABLE_NAME,
      KeyConditionExpression: "user_id = :uid",
      ExpressionAttributeValues: {
        ":uid": {S: user_id},
      },
      Limit: limit,
      ScanIndexForward: false
    )

    items = response[:Items]
    return [] of VideoProgress unless items

    items.map { |item| VideoProgress.from_dynamodb(item) }
  end

  def find_incomplete_by_user(user_id : String, limit : Int32 = 50) : Array(VideoProgress)
    response = @client.query(
      TableName: TABLE_NAME,
      KeyConditionExpression: "user_id = :uid",
      FilterExpression: "completed = :comp",
      ExpressionAttributeValues: {
        ":uid":  {S: user_id},
        ":comp": {BOOL: false},
      },
      Limit: limit,
      ScanIndexForward: false
    )

    items = response[:Items]
    return [] of VideoProgress unless items

    items.map { |item| VideoProgress.from_dynamodb(item) }
  end

  def delete(user_id : String, video_id : String) : Nil
    @client.delete_item(
      TableName: TABLE_NAME,
      Key: {
        user_id:  {S: user_id},
        video_id: {S: video_id},
      }
    )
  end

  def self.create_table(client : Aws::DynamoDB::Client) : Nil
    client.create_table(
      TableName: TABLE_NAME,
      AttributeDefinitions: [
        {
          AttributeName: "user_id",
          AttributeType: "S",
        },
        {
          AttributeName: "video_id",
          AttributeType: "S",
        },
        {
          AttributeName: "last_watched_at",
          AttributeType: "S",
        },
      ],
      KeySchema: [
        {
          AttributeName: "user_id",
          KeyType:       "HASH",
        },
        {
          AttributeName: "video_id",
          KeyType:       "RANGE",
        },
      ],
      LocalSecondaryIndexes: [
        {
          IndexName: "UserRecentIndex",
          KeySchema: [
            {
              AttributeName: "user_id",
              KeyType:       "HASH",
            },
            {
              AttributeName: "last_watched_at",
              KeyType:       "RANGE",
            },
          ],
          Projection: {
            ProjectionType: "ALL",
          },
        },
      ],
      BillingMode: "PAY_PER_REQUEST"
    )
  end
end
