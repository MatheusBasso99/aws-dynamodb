require "../src/aws-dynamodb"
require "json"

class VideoProgress
  include JSON::Serializable

  property user_id : String
  property video_id : String
  property watch_position : Float64
  property duration : Float64
  property percentage : Float64
  property? completed : Bool
  property last_watched_at : Time
  property created_at : Time
  property updated_at : Time

  def initialize(
    @user_id : String,
    @video_id : String,
    @watch_position : Float64,
    @duration : Float64,
    @completed : Bool = false,
    @last_watched_at : Time = Time.utc,
    @created_at : Time = Time.utc,
    @updated_at : Time = Time.utc,
  )
    @percentage = calculate_percentage
  end

  def self.from_dynamodb(item : Hash(String, Aws::DynamoDB::Types::AttributeValue))
    new(
      user_id: string_at(item, "user_id"),
      video_id: string_at(item, "video_id"),
      watch_position: number_at(item, "watch_position"),
      duration: number_at(item, "duration"),
      completed: item["completed"]?.try(&.bool) || false,
      last_watched_at: Time.parse_iso8601(string_at(item, "last_watched_at")),
      created_at: Time.parse_iso8601(string_at(item, "created_at")),
      updated_at: Time.parse_iso8601(string_at(item, "updated_at"))
    )
  end

  private def self.string_at(item : Hash(String, Aws::DynamoDB::Types::AttributeValue), key : String) : String
    item[key]?.try(&.s) || raise ArgumentError.new("missing string attribute #{key.inspect}")
  end

  private def self.number_at(item : Hash(String, Aws::DynamoDB::Types::AttributeValue), key : String) : Float64
    item[key]?.try(&.n) || raise ArgumentError.new("missing number attribute #{key.inspect}")
  end

  def to_dynamodb_item
    {
      user_id:         {S: @user_id},
      video_id:        {S: @video_id},
      watch_position:  {N: @watch_position},
      duration:        {N: @duration},
      percentage:      {N: @percentage},
      completed:       {BOOL: @completed},
      last_watched_at: {S: @last_watched_at.to_rfc3339},
      created_at:      {S: @created_at.to_rfc3339},
      updated_at:      {S: @updated_at.to_rfc3339},
    }
  end

  private def calculate_percentage : Float64
    return 0.0 if @duration.zero?
    ((@watch_position / @duration) * 100).round(2)
  end
end
