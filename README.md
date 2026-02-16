# AWS DynamoDB Client - Crystal 1.16+

**Warning: This shard has been almost entirely updated using Claude Opus 4.6 and has not been tested in a production environment yet. Use with caution.**

## Project Overview

Generic DynamoDB client for Crystal 1.16+. Provides complete AWS DynamoDB operations with optional Lucky Framework integration patterns.

## Core Features

The shard provides:

```crystal
client.list_tables
client.create_table
client.delete_table
client.put_item
client.get_item
client.batch_get_item
client.update_item
client.query
client.delete_item
```

## Installation

Add to your `shard.yml`:

```yaml
dependencies:
  aws-dynamodb:
    github: MatheusBasso99/aws-dynamodb
    version: ~> 0.1.0
```

Run:

```bash
shards install
```

## Quick Start

```crystal
require "aws-dynamodb"

client = Aws::DynamoDB::Client.new(
  region: "us-east-1",
  aws_access_key_id: ENV["AWS_ACCESS_KEY_ID"],
  aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
  endpoint: ENV["DYNAMODB_ENDPOINT"]?
)

client.put_item(
  TableName: "my_table",
  Item: {
    id: {S: "123"},
    name: {S: "John Doe"},
    age: {N: 30}
  }
)

response = client.get_item(
  TableName: "my_table",
  Key: {id: {S: "123"}}
)
```

## Example Implementation: Video Progress System

The `examples/` directory contains a complete real-world implementation of a Video Progress tracking system. This demonstrates:

- Domain model with DynamoDB serialization
- Repository pattern
- Lucky Framework Actions
- Configuration management
- Testing strategies

**Note:** This is an example implementation. Copy and adapt it to your specific needs rather than importing it directly.

### Example Structure

```text
examples/
├── video_progress_model.cr       # Example domain model
├── video_progress_repository.cr  # Example repository
├── usage_example.cr              # Standalone usage
├── lucky_actions/                # Example Lucky Actions
└── lucky_integration/            # Example configuration
```

## Lucky Framework Integration

### Generic Configuration Pattern

Create a configuration module for your project:

```crystal
# config/dynamo_db.cr
AwsDynamoDB.configure do |settings|
  settings.region = ENV["AWS_REGION"]? || "us-east-1"
  settings.access_key_id = ENV["AWS_ACCESS_KEY_ID"]? || "local"
  settings.secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"]? || "local"
  settings.endpoint = ENV["DYNAMODB_ENDPOINT"]? || "http://localhost:8000"
end


# src/models/dynamo_db.cr
class AwsDynamoDB
  Habitat.create do
    setting region : String
    setting access_key_id : String
    setting secret_access_key : String
    setting endpoint : String
  end
end
```

### Sample Task to Create table

```crystal
class Db::Seed::GenerateDynamoDbTable < LuckyTask::Task
  summary "Generate DynamoDB table"

  def call
    if table_exists?
      puts "video_progress already exists" unless LuckyEnv.test?
    else
      puts "creating video_progress table..." unless LuckyEnv.test?
      create_table
      puts "table created successfully!" unless LuckyEnv.test?
    end
  end

  private def table_exists? : Bool
    response = Aws::DynamoDB::Client.list_tables
    response[:TableNames].includes?("video_progress")
  end

  private def create_table
    Aws::DynamoDB::Client.create_table(
      TableName: "video_progress",
      AttributeDefinitions: [
        {AttributeName: "user_id", AttributeType: "S"},
        {AttributeName: "sk", AttributeType: "S"},
      ],
      KeySchema: [
        {AttributeName: "user_id", KeyType: "HASH"},
        {AttributeName: "sk", KeyType: "RANGE"},
      ],
      TimeToLiveSpecification: {
        Enabled:       true,
        AttributeName: "ttl",
      },
      BillingMode: "PAY_PER_REQUEST"
    )
  end
end

```

## Local Development Setup

```bash
docker-compose up -d
cp .env.example .env
crystal examples/setup_dynamodb.cr -- --run
```

Access DynamoDB Admin UI at http://localhost:8001

## Production Deployment

### IAM Policy Template

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem"
      ],
      "Resource": [
        "arn:aws:dynamodb:REGION:ACCOUNT_ID:table/YOUR_TABLE",
        "arn:aws:dynamodb:REGION:ACCOUNT_ID:table/YOUR_TABLE/index/*"
      ]
    }
  ]
}
```

### Performance Patterns

#### Connection Pool

```crystal
class DynamoDBClientPool
  def initialize(@size : Int32 = 10)
    @clients = Array(Aws::DynamoDB::Client).new(@size) { create_client }
    @index = 0
  end

  def client : Aws::DynamoDB::Client
    @clients[@index % @size].tap { @index += 1 }
  end

  private def create_client
    Aws::DynamoDB::Client.new(region: ENV["AWS_REGION"]? || "us-east-1")
  end
end
```

#### Redis Caching Pattern

```crystal
class CachedRepository(T)
  def initialize(@client : Aws::DynamoDB::Client, @redis : Redis, @table : String)
  end

  def find(key : Hash) : T?
    cache_key = "#{@table}:#{key.to_json}"

    if cached = @redis.get(cache_key)
      return T.from_json(cached)
    end

    response = @client.get_item(TableName: @table, Key: key)
    if item = response[:Item]
      result = T.from_dynamodb(item)
      @redis.setex(cache_key, 300, result.to_json)
      result
    end
  end
end
```

## Monitoring

Key CloudWatch Metrics:

- `ConsumedReadCapacityUnits`
- `ConsumedWriteCapacityUnits`
- `ThrottledRequests`
- `UserErrors`
- `SuccessfulRequestLatency`

## Testing

Run the test suite:

```bash
crystal spec
```

The test suite includes:

- Client operation tests
- Type serialization tests
- Example implementation tests (VideoProgress)

## Roadmap

- Batch operations (`BatchWriteItem`)
- Global Secondary Index (GSI) support
- DynamoDB Streams integration
- Circuit breaker pattern

## Contributing

Contributions are welcome! Please ensure:

- Tests pass
- Code follows Crystal style guide
- Examples remain generic and reusable

## License

MIT
