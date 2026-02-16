require "./spec_helper"
require "../examples/video_progress_model"
require "../examples/video_progress_repository"

describe VideoProgressRepository do
  Spec.before_each &->WebMock.reset

  describe "#save" do
    it "saves progress to DynamoDB" do
      client = new_client
      repo = VideoProgressRepository.new(client)

      progress = VideoProgress.new(
        user_id: "user_123",
        video_id: "video_456",
        watch_position: 120.5,
        duration: 300.0
      )

      WebMock.stub(:post, DEFAULT_ENDPOINT).to_return(
        status: 200,
        body: "{}"
      )

      result = repo.save(progress)
      result.should be_a(VideoProgress)
    end
  end

  describe "#find" do
    it "finds progress by user_id and video_id" do
      client = new_client
      repo = VideoProgressRepository.new(client)

      now = Time.utc
      response = {
        Item: {
          user_id:         {S: "user_123"},
          video_id:        {S: "video_456"},
          watch_position:  {N: "120.5"},
          duration:        {N: "300.0"},
          percentage:      {N: "40.17"},
          completed:       {BOOL: false},
          last_watched_at: {S: now.to_rfc3339},
          created_at:      {S: now.to_rfc3339},
          updated_at:      {S: now.to_rfc3339},
        },
      }

      WebMock.stub(:post, DEFAULT_ENDPOINT).to_return(
        status: 200,
        body: response.to_json
      )

      progress = repo.find("user_123", "video_456")
      progress.should_not be_nil
      progress.not_nil!.user_id.should eq("user_123")
      progress.not_nil!.video_id.should eq("video_456")
      progress.not_nil!.watch_position.should eq(120.5)
    end

    it "returns nil when not found" do
      client = new_client
      repo = VideoProgressRepository.new(client)

      WebMock.stub(:post, DEFAULT_ENDPOINT).to_return(
        status: 200,
        body: "{}"
      )

      progress = repo.find("user_123", "nonexistent")
      progress.should be_nil
    end

    it "returns nil on error" do
      client = new_client
      repo = VideoProgressRepository.new(client)

      stub_client_error(status: 404)

      progress = repo.find("user_123", "video_456")
      progress.should be_nil
    end
  end

  describe "#update_position" do
    it "updates position and calculates percentage" do
      client = new_client
      repo = VideoProgressRepository.new(client)

      now = Time.utc

      update_response = {
        Attributes: {
          user_id:         {S: "user_123"},
          video_id:        {S: "video_456"},
          watch_position:  {N: "150.0"},
          duration:        {N: "300.0"},
          percentage:      {N: "50.0"},
          completed:       {BOOL: false},
          last_watched_at: {S: now.to_rfc3339},
          created_at:      {S: now.to_rfc3339},
          updated_at:      {S: now.to_rfc3339},
        },
      }

      get_response = {
        Item: {
          user_id:         {S: "user_123"},
          video_id:        {S: "video_456"},
          watch_position:  {N: "150.0"},
          duration:        {N: "300.0"},
          percentage:      {N: "50.0"},
          completed:       {BOOL: false},
          last_watched_at: {S: now.to_rfc3339},
          created_at:      {S: now.to_rfc3339},
          updated_at:      {S: now.to_rfc3339},
        },
      }

      WebMock.stub(:post, DEFAULT_ENDPOINT)
        .with(headers: {"X-Amz-Target" => "DynamoDB_20120810.UpdateItem"})
        .to_return(status: 200, body: update_response.to_json)

      WebMock.stub(:post, DEFAULT_ENDPOINT)
        .with(headers: {"X-Amz-Target" => "DynamoDB_20120810.GetItem"})
        .to_return(status: 200, body: get_response.to_json)

      progress = repo.update_position("user_123", "video_456", 150.0, 300.0)
      progress.watch_position.should eq(150.0)
      progress.percentage.should eq(50.0)
      progress.completed.should be_false
    end

    it "marks as completed when >= 95%" do
      client = new_client
      repo = VideoProgressRepository.new(client)

      now = Time.utc

      update_response = {
        Attributes: {
          user_id:         {S: "user_123"},
          video_id:        {S: "video_456"},
          watch_position:  {N: "290.0"},
          duration:        {N: "300.0"},
          percentage:      {N: "96.67"},
          completed:       {BOOL: true},
          last_watched_at: {S: now.to_rfc3339},
          created_at:      {S: now.to_rfc3339},
          updated_at:      {S: now.to_rfc3339},
        },
      }

      get_response = {
        Item: update_response[:Attributes],
      }

      WebMock.stub(:post, DEFAULT_ENDPOINT)
        .with(headers: {"X-Amz-Target" => "DynamoDB_20120810.UpdateItem"})
        .to_return(status: 200, body: update_response.to_json)

      WebMock.stub(:post, DEFAULT_ENDPOINT)
        .with(headers: {"X-Amz-Target" => "DynamoDB_20120810.GetItem"})
        .to_return(status: 200, body: get_response.to_json)

      progress = repo.update_position("user_123", "video_456", 290.0, 300.0)
      progress.percentage.should eq(96.67)
      progress.completed.should be_true
    end
  end

  describe "#find_all_by_user" do
    it "returns all videos for a user" do
      client = new_client
      repo = VideoProgressRepository.new(client)

      now = Time.utc
      response = {
        Items: [
          {
            user_id:         {S: "user_123"},
            video_id:        {S: "video_1"},
            watch_position:  {N: "50.0"},
            duration:        {N: "100.0"},
            percentage:      {N: "50.0"},
            completed:       {BOOL: false},
            last_watched_at: {S: now.to_rfc3339},
            created_at:      {S: now.to_rfc3339},
            updated_at:      {S: now.to_rfc3339},
          },
          {
            user_id:         {S: "user_123"},
            video_id:        {S: "video_2"},
            watch_position:  {N: "180.0"},
            duration:        {N: "200.0"},
            percentage:      {N: "90.0"},
            completed:       {BOOL: false},
            last_watched_at: {S: now.to_rfc3339},
            created_at:      {S: now.to_rfc3339},
            updated_at:      {S: now.to_rfc3339},
          },
        ],
        Count: 2,
      }

      WebMock.stub(:post, DEFAULT_ENDPOINT).to_return(
        status: 200,
        body: response.to_json
      )

      videos = repo.find_all_by_user("user_123")
      videos.size.should eq(2)
      videos[0].video_id.should eq("video_1")
      videos[1].video_id.should eq("video_2")
    end

    it "returns empty array when no videos found" do
      client = new_client
      repo = VideoProgressRepository.new(client)

      empty_response = {Items: [] of Nil, Count: 0}

      WebMock.stub(:post, DEFAULT_ENDPOINT).to_return(
        status: 200,
        body: empty_response.to_json
      )

      videos = repo.find_all_by_user("user_123")
      videos.should be_empty
    end
  end

  describe "#find_incomplete_by_user" do
    it "returns only incomplete videos" do
      client = new_client
      repo = VideoProgressRepository.new(client)

      now = Time.utc
      response = {
        Items: [
          {
            user_id:         {S: "user_123"},
            video_id:        {S: "video_1"},
            watch_position:  {N: "50.0"},
            duration:        {N: "100.0"},
            percentage:      {N: "50.0"},
            completed:       {BOOL: false},
            last_watched_at: {S: now.to_rfc3339},
            created_at:      {S: now.to_rfc3339},
            updated_at:      {S: now.to_rfc3339},
          },
        ],
        Count: 1,
      }

      WebMock.stub(:post, DEFAULT_ENDPOINT).to_return(
        status: 200,
        body: response.to_json
      )

      videos = repo.find_incomplete_by_user("user_123")
      videos.size.should eq(1)
      videos[0].completed.should be_false
    end
  end

  describe "#delete" do
    it "deletes a progress entry" do
      client = new_client
      repo = VideoProgressRepository.new(client)

      # CORREÇÃO: Usar "{}" em vez de [""]
      WebMock.stub(:post, DEFAULT_ENDPOINT).to_return(
        status: 200,
        body: "{}"
      )

      repo.delete("user_123", "video_456")
    end
  end

  describe ".create_table" do
    it "creates the video_progress table" do
      client = new_client

      response = {
        TableDescription: {
          ItemCount:      0,
          TableArn:       "arn:aws:dynamodb:us-east-1:123456789:table/video_progress",
          TableName:      "video_progress",
          TableStatus:    "CREATING",
          TableSizeBytes: 0,
        },
      }

      WebMock.stub(:post, DEFAULT_ENDPOINT).to_return(
        status: 200,
        body: response.to_json
      )

      VideoProgressRepository.create_table(client)
    end
  end
end
