require "../src/aws-dynamodb"

class DynamoDBSetup
  def self.run
    puts "🚀 Configurando DynamoDB..."

    client = create_client

    if table_exists?(client, "video_progress")
      puts "✅ Tabela 'video_progress' já existe"
    else
      puts "📦 Criando tabela 'video_progress'..."
      create_video_progress_table(client)
      puts "✅ Tabela criada com sucesso!"
    end

    puts "\n📊 Informações das tabelas:"
    list_tables(client)
  end

  private def self.create_client : Aws::DynamoDB::Client
    Aws::DynamoDB::Client.new(
      region: ENV["AWS_REGION"]? || "us-east-1",
      aws_access_key_id: ENV["AWS_ACCESS_KEY_ID"]? || "",
      aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]? || "",
      endpoint: ENV["DYNAMODB_ENDPOINT"]?
    )
  end

  private def self.table_exists?(client : Aws::DynamoDB::Client, table_name : String) : Bool
    response = client.list_tables
    response[:TableNames].includes?(table_name)
  rescue
    false
  end

  private def self.create_video_progress_table(client : Aws::DynamoDB::Client)
    client.create_table(
      TableName: "video_progress",
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

  private def self.list_tables(client : Aws::DynamoDB::Client)
    response = client.list_tables
    response[:TableNames].each do |table_name|
      puts "  - #{table_name}"
    end
  end
end

if ARGV.includes?("--run")
  DynamoDBSetup.run
end
