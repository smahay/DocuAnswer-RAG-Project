# require loads Ruby libraries so we can use them in this file.
# "net/http" gives us tools to make HTTP web requests.
# "json" gives us tools to convert Ruby data <-> JSON text.
require "net/http"
require "json"

# Requests embeddings from the Gemini API.
class EmbeddingGenerator
  def initialize(api_key)
    # nil? means "is there no value?".
    # strip removes spaces around text.
    # empty? means "is the string length zero?".
    # raise stops the program flow and throws an error message.
    if api_key.nil? || api_key.strip.empty?
      raise "Gemini API key is missing."
    end

    # @api_key, @url, and @model are instance variables.
    # Instance variables belong to this object and can be used
    # later in other methods in the same class.
    @api_key = api_key
    @url = URI("https://generativelanguage.googleapis.com/v1beta/openai/embeddings")
    @model = "gemini-embedding-001"
  end

  # This method sends one text string to the API and returns
  # one embedding (an array of numbers).
  def generate_embedding(text)
    # Validate input before making a network call.
    if text.nil? || text.strip.empty?
      raise "Text for embedding cannot be empty."
    end

    # Creates an HTTP connection object.
    # Net::HTTP.new(host, port) needs the host and port.
    http = Net::HTTP.new(@url.host, @url.port)

    # use_ssl = true means we use HTTPS (secure connection).
    http.use_ssl = true

    # Build a POST request object for this URL.
    request = Net::HTTP::Post.new(@url)

    # Set headers. Headers are metadata sent with the request.
    # Content-Type tells server we are sending JSON.
    # Authorization sends our API key as a Bearer token.
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{@api_key}"

    # Builds a request body which is a Ruby hash, then converts it to JSON.
    # to_json turns the Ruby hash/array/string/number into JSON text.
    request.body = {
      input: text,
      model: @model
    }.to_json

    # Send request to server and wait for response.
    response = http.request(request)

    # to_i converts string status code (like "200") to integer 200.
    # 200 means success. Any other code means failure.
    if response.code.to_i != 200
      raise "Embedding request failed: #{response.body}"
    end

    # Parse JSON response text into Ruby hash/array objects.
    parsed_response = JSON.parse(response.body)

    # Return the embedding array from the response structure.
    # The API format is: data -> first item -> embedding
    parsed_response["data"][0]["embedding"]
  end

end
