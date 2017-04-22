require 'json'
require 'net/http'
require 'uri'

class Fetcher
  class Unauthorized < StandardError; end

  attr_reader :base_url, :token, :response_code, :logger

  def initialize(base_url, token, logger:)
    @base_url = base_url
    @token = token
    @logger = logger
  end

  protected

  def get_headers
    {}
  end

  def get(path, headers: {}, &block)
    make_request(Net::HTTP::Get, path, headers: headers, &block)
  end

  # Will make a POST request to the given path. Yields the request
  # so the request body can be set.
  def post(path, headers: {}, &block)
    make_request(Net::HTTP::Post, path, headers: headers, &block)
  end

  # Will make a PUT request to the given path. Yields the request
  # so the request body can be set.
  def put(path, headers: {})
    make_request(Net::HTTP::Put, path, headers: headers, &block)
  end

  private

  def make_request(req_class, path, headers:)
    uri = get_uri(path)
    @logger.info "#{req_class::METHOD} #{uri}"

    http = get_http(uri)
    all_headers = get_headers.merge(headers)
    req = req_class.new(uri.request_uri, all_headers)
    yield req if block_given?

    res = http.request(req)
    @response_code = res.code

    if res.kind_of? Net::HTTPSuccess
      if res.body.size > 0
        begin
          JSON.parse(res.body)
        rescue JSON::ParserError
          @logger.error "Failed to parse JSON response: #{res.body}"
          nil
        end
      end
    elsif res.code == '401'
      raise Unauthorized, res.message
    else
      @logger.error res.body
      nil
    end
  end

  def get_uri(path)
    URI.parse("#{@base_url}#{path}")
  end

  def get_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http
  end
end
