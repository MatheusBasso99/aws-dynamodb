require "./spec_helper"
require "../examples/video_progress_model"

describe VideoProgress do
  describe "#initialize" do
    it "creates a progress with all required fields" do
      progress = VideoProgress.new(
        user_id: "user_123",
        video_id: "video_456",
        watch_position: 120.5,
        duration: 300.0
      )

      progress.user_id.should eq("user_123")
      progress.video_id.should eq("video_456")
      progress.watch_position.should eq(120.5)
      progress.duration.should eq(300.0)
      progress.completed.should be_false
    end

    it "calculates percentage correctly" do
      progress = VideoProgress.new(
        user_id: "user_123",
        video_id: "video_456",
        watch_position: 150.0,
        duration: 300.0
      )

      progress.percentage.should eq(50.0)
    end

    it "marks as completed when >= 95%" do
      progress = VideoProgress.new(
        user_id: "user_123",
        video_id: "video_456",
        watch_position: 285.0,
        duration: 300.0,
        completed: true
      )

      progress.percentage.should eq(95.0)
      progress.completed.should be_true
    end

    it "handles zero duration" do
      progress = VideoProgress.new(
        user_id: "user_123",
        video_id: "video_456",
        watch_position: 0.0,
        duration: 0.0
      )

      progress.percentage.should eq(0.0)
    end
  end

  describe "#to_dynamodb_item" do
    it "converts to DynamoDB item format" do
      progress = VideoProgress.new(
        user_id: "user_123",
        video_id: "video_456",
        watch_position: 120.5,
        duration: 300.0
      )

      item = progress.to_dynamodb_item

      item[:user_id][:S].should eq("user_123")
      item[:video_id][:S].should eq("video_456")
      item[:watch_position][:N].should eq(120.5)
      item[:duration][:N].should eq(300.0)
      item[:percentage][:N].should eq(40.17)
      item[:completed][:BOOL].should be_false
    end
  end

  describe ".from_dynamodb" do
    it "creates instance from DynamoDB item" do
      now = Time.utc
      item = {
        "user_id"         => Aws::DynamoDB::Types::AttributeValue.from_json({S: "user_123"}.to_json),
        "video_id"        => Aws::DynamoDB::Types::AttributeValue.from_json({S: "video_456"}.to_json),
        "watch_position"  => Aws::DynamoDB::Types::AttributeValue.from_json({N: "120.5"}.to_json),
        "duration"        => Aws::DynamoDB::Types::AttributeValue.from_json({N: "300.0"}.to_json),
        "completed"       => Aws::DynamoDB::Types::AttributeValue.from_json({BOOL: false}.to_json),
        "last_watched_at" => Aws::DynamoDB::Types::AttributeValue.from_json({S: now.to_rfc3339}.to_json),
        "created_at"      => Aws::DynamoDB::Types::AttributeValue.from_json({S: now.to_rfc3339}.to_json),
        "updated_at"      => Aws::DynamoDB::Types::AttributeValue.from_json({S: now.to_rfc3339}.to_json),
      }

      progress = VideoProgress.from_dynamodb(item)

      progress.user_id.should eq("user_123")
      progress.video_id.should eq("video_456")
      progress.watch_position.should eq(120.5)
      progress.duration.should eq(300.0)
      progress.completed.should be_false
    end
  end
end
