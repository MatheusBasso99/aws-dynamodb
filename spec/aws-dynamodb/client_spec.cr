require "../spec_helper"

module Aws::DynamoDB
  describe Client do
    Spec.before_each &->WebMock.reset

    describe "#initialize" do
      it "creates signed http client" do
        new_client.http.should_not be_nil
      end

      it "raises if version is not valid" do
        expect_raises(ArgumentError, "Unknown signer version: v1") do
          new_client(version: :v1)
        end
      end
    end

    describe "#list_tables" do
      it "sends a valid request and returns response" do
        request = {} of String => String
        response = {
          TableNames:             ["Table1", "Table2"],
          LastEvaluatedTableName: "Table3",
        }

        stub_client(request, response, op: "ListTables")
        new_client.list_tables.should eq(response)
      end

      it "raises in case of error" do
        stub_client_error

        expect_raises(Http::ServerError) do
          new_client.list_tables
        end
      end
    end

    describe "#create_table" do
      it "sends a valid request and returns response" do
        request = {
          TableName:            "Table1",
          AttributeDefinitions: [
            {
              AttributeName: "ForumName",
              AttributeType: "S",
            },
            {
              AttributeName: "Subject",
              AttributeType: "S",
            },
            {
              AttributeName: "LastPostDateTime",
              AttributeType: "S",
            },
          ],
        }

        response = {
          TableDescription: {
            ItemCount:      3,
            TableArn:       "arn",
            TableName:      "Table1",
            TableStatus:    "ACTIVE",
            TableSizeBytes: 338_943_234,
          },
        }

        stub_client(request, response, op: "CreateTable")
        new_client.create_table(**request).should eq(response)
      end

      it "raises in case of error" do
        stub_client_error
        expect_raises(Http::ServerError) do
          new_client.create_table(TableName: "Doe")
        end
      end
    end

    describe "#delete_table" do
      it "sends a valid request and returns response" do
        request = {
          TableName: "Table1",
        }

        response = {
          TableDescription: {
            ItemCount:      3,
            TableArn:       "arn",
            TableName:      "Table1",
            TableStatus:    "ACTIVE",
            TableSizeBytes: 338_943_234,
          },
        }

        stub_client(request, response, "DeleteTable")
        new_client.delete_table(**request).should eq(response)
      end

      it "raises in case of error" do
        stub_client_error
        expect_raises(Http::ServerError) do
          new_client.delete_table(TableName: "Doe")
        end
      end
    end

    describe "#put_item" do
      it "sends a valid request and returns response" do
        request = {
          TableName: "Table1",
          Item:      {
            AttributeName: "value",
          },
        }

        response = {
          Attributes: {
            AttributeName: {
              Value: "value",
            },
          },
        }

        stub_client(request, response, "PutItem")
        resp = new_client.put_item(**request)
        resp[:Attributes].should_not be_nil
      end

      it "raises in case of error" do
        stub_client_error
        expect_raises(Http::ServerError) do
          new_client.put_item(TableName: "Doe")
        end
      end
    end

    describe "#get_item" do
      it "sends a valid request and returns response" do
        request = {
          TableName: "Table1",
          Key:       {
            ForumName: {
              S: "Amazon DynamoDB",
            },
            Subject: {
              S: "How do I update multiple items?",
            },
          },
          ProjectionExpression:   "LastPostDateTime, Message, Tags",
          ConsistentRead:         true,
          ReturnConsumedCapacity: "TOTAL",
        }

        response = {
          ConsumedCapacity: {
            CapacityUnits:      1.0,
            TableName:          "Thread",
            ReadCapacityUnits:  nil,
            WriteCapacityUnits: nil,
          },
          Item: {
            Tags: {
              SS: ["Update", "Multiple Items", "HelpMe"],
            },
            Message: {
              S: "Message",
            },
          },
        }

        stub_client(request, response, "GetItem")
        resp = new_client.get_item(**request)
        resp[:ConsumedCapacity].should eq response[:ConsumedCapacity]
        resp[:Item].try &.["Tags"]["SS"].should eq response[:Item]["Tags"]["SS"]
        resp[:Item].try &.["Message"]["S"].should eq response[:Item]["Message"]["S"]
      end

      it "raises in case of error" do
        stub_client_error
        expect_raises(Http::ServerError) do
          new_client.get_item(TableName: "Doe")
        end
      end
    end

    describe "#batch_get_item" do
      it "sends a valid request and returns response" do
        request = {
          RequestItems: {
            "Table1" => {
              Keys: [
                {
                  user_id: {S: "user_123"},
                  sk:      {S: "VIDEO#video_1"},
                },
                {
                  user_id: {S: "user_123"},
                  sk:      {S: "VIDEO#video_2"},
                },
              ],
            },
          },
        }

        response = {
          Responses: {
            "Table1" => [
              {
                user_id:     {S: "user_123"},
                sk:          {S: "VIDEO#video_1"},
                video_id:    {S: "video_1"},
                position_ms: {N: "100"},
                duration_ms: {N: "1000"},
              },
              {
                user_id:     {S: "user_123"},
                sk:          {S: "VIDEO#video_2"},
                video_id:    {S: "video_2"},
                position_ms: {N: "200"},
                duration_ms: {N: "1000"},
              },
            ],
          },
          UnprocessedKeys: nil,
        }

        stub_client(request, response, "BatchGetItem")
        resp = new_client.batch_get_item(**request)
        resp[:Responses].should_not be_nil
        resp[:Responses].try &.["Table1"].size.should eq 2
      end

      it "raises in case of error" do
        stub_client_error
        expect_raises(Http::ServerError) do
          new_client.batch_get_item(RequestItems: {"Table1" => {Keys: [] of Hash(String, String)}})
        end
      end
    end

    describe "#update_item" do
      it "sends a valid request and returns response" do
        request = {
          TableName: "Table1",
          Key:       {
            id: {S: "123"},
          },
          UpdateExpression:          "SET age = :age",
          ExpressionAttributeValues: {
            ":age": {N: 31},
          },
        }

        response = {
          Attributes: {
            id:  {S: "123"},
            age: {N: "31"},
          },
        }

        stub_client(request, response, "UpdateItem")
        resp = new_client.update_item(**request)
        resp[:Attributes].should_not be_nil
      end

      it "raises in case of error" do
        stub_client_error
        expect_raises(Http::ServerError) do
          new_client.update_item(TableName: "Doe")
        end
      end
    end

    describe "#query" do
      it "sends a valid request and returns response" do
        request = {
          TableName:                 "Table1",
          KeyConditionExpression:    "user_id = :uid",
          ExpressionAttributeValues: {
            ":uid": {S: "user_123"},
          },
        }

        response = {
          Items: [
            {
              user_id:  {S: "user_123"},
              video_id: {S: "video_456"},
            },
          ],
          Count:        1,
          ScannedCount: 1,
        }

        stub_client(request, response, "Query")
        resp = new_client.query(**request)
        resp[:Count].should eq 1
        resp[:Items].should_not be_nil
      end

      it "raises in case of error" do
        stub_client_error
        expect_raises(Http::ServerError) do
          new_client.query(TableName: "Doe")
        end
      end
    end

    describe "#delete_item" do
      it "sends a valid request and returns response" do
        request = {
          TableName: "Table1",
          Key:       {
            id: {S: "123"},
          },
        }

        response = {} of String => String

        stub_client(request, response, "DeleteItem")
        new_client.delete_item(**request)
      end

      it "raises in case of error" do
        stub_client_error
        expect_raises(Http::ServerError) do
          new_client.delete_item(TableName: "Doe")
        end
      end
    end
  end
end
