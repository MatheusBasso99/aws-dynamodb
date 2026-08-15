require "./spec_helper"
require "../examples/lucky_integration/dynamodb_config"

# Deliberately not DEFAULT_ENDPOINT: WebMock's registry returns the first
# matching stub, so a broad stub on the shared endpoint would shadow the
# stubs registered by the other spec files.
CONFIG_ENDPOINT = "http://localhost:9001"

describe DynamoDBConfig do
  it "overrides a setting for the duration of temp_config" do
    DynamoDBConfig.temp_config(video_progress_table: "custom_table") do
      DynamoDBConfig.settings.video_progress_table.should eq("custom_table")
    end
  end

  it "restores the setting after temp_config" do
    original = DynamoDBConfig.settings.video_progress_table

    DynamoDBConfig.temp_config(video_progress_table: "custom_table") do
      DynamoDBConfig.settings.video_progress_table.should eq("custom_table")
    end

    DynamoDBConfig.settings.video_progress_table.should eq(original)
  end
end

describe DynamoDBClient do
  it "memoizes the client" do
    DynamoDBClient.reset_client

    DynamoDBClient.client.should be(DynamoDBClient.client)

    DynamoDBClient.reset_client
  end

  it "builds a fresh client after reset_client" do
    DynamoDBClient.reset_client
    first = DynamoDBClient.client

    DynamoDBClient.reset_client
    second = DynamoDBClient.client

    first.should_not be(second)

    DynamoDBClient.reset_client
  end

  it "builds the client from the configured endpoint" do
    DynamoDBConfig.temp_config(endpoint: CONFIG_ENDPOINT) do
      DynamoDBClient.reset_client

      WebMock.stub(:post, CONFIG_ENDPOINT).to_return(
        status: 200,
        body: {TableNames: ["video_progress"], LastEvaluatedTableName: nil}.to_json
      )

      DynamoDBClient.client.list_tables[:TableNames].should eq(["video_progress"])
    end

    DynamoDBClient.reset_client
  end
end
