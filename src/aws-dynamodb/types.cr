require "json"

module Aws::DynamoDB::Types
  struct AttributeValue
    include JSON::Serializable
    include JSON::Serializable::Unmapped

    @[JSON::Field(key: "B")]
    property b : String?

    @[JSON::Field(key: "BOOL")]
    property bool : Bool?

    @[JSON::Field(key: "BS")]
    property bs : Array(String)?

    @[JSON::Field(key: "L")]
    property l : Array(AttributeValue)?

    @[JSON::Field(key: "M")]
    property m : Hash(String, AttributeValue)?

    @[JSON::Field(key: "N", converter: Aws::DynamoDB::Types::NConverter)]
    property n : Float64?

    @[JSON::Field(key: "NS", converter: Aws::DynamoDB::Types::NNConverter)]
    property ns : Array(Float64)?

    @[JSON::Field(key: "NULL")]
    property null : Bool?

    @[JSON::Field(key: "S")]
    property s : String?

    @[JSON::Field(key: "SS")]
    property ss : Array(String)?

    def [](key : String)
      case key
      when "B"    then b
      when "BOOL" then bool
      when "BS"   then bs
      when "L"    then l
      when "M"    then m
      when "N"    then n
      when "NS"   then ns
      when "NULL" then null
      when "S"    then s
      when "SS"   then ss
      else
        raise ArgumentError.new("invalid key: #{key}")
      end
    end
  end

  module NConverter
    def self.from_json(value : JSON::PullParser) : Float64
      value.read_string.to_f64
    end

    def self.to_json(value : Float64, json : JSON::Builder)
      json.string(value.to_s)
    end
  end

  module NNConverter
    def self.from_json(value : JSON::PullParser) : Array(Float64)
      values = [] of Float64
      value.read_array do
        values << value.read_string.to_f64
      end
      values
    end

    def self.to_json(values : Array(Float64), json : JSON::Builder)
      json.array do
        values.each do |value|
          json.string(value.to_s)
        end
      end
    end
  end

  alias TableDescription = NamedTuple(
    ItemCount: Int64,
    TableArn: String,
    TableName: String,
    TableStatus: String,
    TableSizeBytes: Int64,
  )

  alias ConsumedCapacity = NamedTuple(
    TableName: String,
    CapacityUnits: Float64?,
    ReadCapacityUnits: Float64?,
    WriteCapacityUnits: Float64?,
  )

  alias ItemCollectionMetrics = NamedTuple(
    ItemCollectionKey: Hash(String, AttributeValue)?,
    SizeEstimateRangeGb: Array(Float64)?,
  )

  PutItemOutput = NamedTuple(
    Attributes: Hash(String, AttributeValue)?,
    ConsumedCapacity: ConsumedCapacity?,
    ItemCollectionMetrics: ItemCollectionMetrics?,
  )

  GetItemOutput = NamedTuple(
    Item: Hash(String, AttributeValue)?,
    ConsumedCapacity: ConsumedCapacity?,
  )

  UpdateItemOutput = NamedTuple(
    Attributes: Hash(String, AttributeValue)?,
    ConsumedCapacity: ConsumedCapacity?,
    ItemCollectionMetrics: ItemCollectionMetrics?,
  )

  QueryOutput = NamedTuple(
    Items: Array(Hash(String, AttributeValue))?,
    Count: Int32?,
    ScannedCount: Int32?,
    LastEvaluatedKey: Hash(String, AttributeValue)?,
    ConsumedCapacity: ConsumedCapacity?,
  )

  BatchGetItemOutput = NamedTuple(
    Responses: Hash(String, Array(Hash(String, AttributeValue)))?,
    UnprocessedKeys: Hash(String, Hash(String, Array(Hash(String, AttributeValue))))?,
    ConsumedCapacity: Array(ConsumedCapacity)?,
  )

  ListTablesOutput  = NamedTuple(TableNames: Array(String), LastEvaluatedTableName: String?)
  CreateTableOutput = NamedTuple(TableDescription: TableDescription)
  DeleteTableOutput = NamedTuple(TableDescription: TableDescription)
end
