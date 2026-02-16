require "uri"
require "http/client"

module Aws::DynamoDB
  class Http
    class ServerError < Exception
      getter status_code : Int32
      getter body : String

      def initialize(@status_code, @body)
        super("server error (#{@status_code}): #{@body}")
      end
    end

    def initialize(
      @signer : Awscr::Signer::Signers::Interface,
      @service_name : String,
      @region : String,
      @custom_endpoint : String? = nil,
    )
      @http = HTTP::Client.new(endpoint)
      @http.before_request { |request| @signer.sign(request) }
    end

    def post(path : String, body : String, op : String) : HTTP::Client::Response
      headers = HTTP::Headers{
        "X-Amz-Target" => "#{DynamoDB::METADATA[:target_prefix]}.#{op}",
        "Content-Type" => "application/x-amz-json-1.0",
      }
      resp = @http.post(path, headers: headers, body: body)
      handle_response!(resp)
    end

    private def handle_response!(response : HTTP::Client::Response) : HTTP::Client::Response
      return response if (200..299).includes?(response.status_code)
      raise ServerError.new(response.status_code, response.body)
    end

    private def endpoint : URI
      return URI.parse(@custom_endpoint.not_nil!) if @custom_endpoint
      URI.parse("https://#{@service_name}.#{@region}.amazonaws.com")
    end
  end
end
