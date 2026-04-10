# - "net/http" is used to send web requests.
# - "json" is used to convert Ruby data into JSON text (and back).
require "net/http"
require "json"

# class defines a blueprint for objects.
# This class talks to the Gemini Chat API and returns the final answer text.
class LLMClient
  # model = "gemini-2.0-flash" means:
  # this argument has a default value.
  def initialize(api_key, model = "gemini-2.0-flash")
    # nil? means "no value".
    # strip removes spaces at the start and end of text.
    # empty? means "string has zero characters".
    # raise stops the method and throws an error message.
    if api_key.nil? || api_key.strip.empty?
      raise "Gemini API key is missing."
    end

    # Variables starting with @ are instance variables.
    # They belong to this object and are available in other methods.
    @api_key = api_key
    @model = model
    @url = URI("https://generativelanguage.googleapis.com/v1beta/openai/chat/completions")
  end

  # Sends one prompt to the API and returns one answer string.
  # temperature = 0.2 sets a default value.
  # Lower values usually make responses more consistent.
  def generate_answer(prompt, temperature = 0.2)
    # Validate prompt before making a network request.
    if prompt.nil? || prompt.strip.empty?
      raise "Prompt cannot be empty."
    end

    # Create HTTP connection object using host + port from the URL.
    http = Net::HTTP.new(@url.host, @url.port)

    # Use HTTPS (secure encrypted connection).
    http.use_ssl = true

    # Build a POST request object for this URL.
    request = Net::HTTP::Post.new(@url)

    # Content-Type tells server our body is JSON.
    # Authorization sends API key as Bearer token.
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{@api_key}"

    # Build request body as a Ruby hash.
    # Then convert that hash to JSON with to_json.
    request.body = {
      model: @model,
      temperature: temperature,
      messages: [
        {
          role: "system",
          content: "Answer questions using only provided context and cite sources."
        },
        {
          role: "user",
          content: prompt
        }
      ]
    }.to_json

    # Send request and wait for response.
    response = http.request(request)

    # response.code is often a string like "200".
    # to_i converts it to an integer so we can compare numbers.
    if response.code.to_i != 200
      raise "LLM request failed: #{response.body}"
    end

    # Parse response JSON string into Ruby hash/array objects.
    parsed_response = JSON.parse(response.body)

    # API returns answers inside "choices" array.
    choices = parsed_response["choices"]
    if choices.nil? || choices.empty?
      raise "LLM response did not include choices."
    end

    # Read first choice from array.
    first_choice = choices[0]
    if first_choice.nil?
      raise "LLM response did not include a first choice."
    end

    # Read "message" object from first choice.
    message = first_choice["message"]
    if message.nil?
      raise "LLM response did not include a message."
    end

    # Read answer text from message["content"].
    content = message["content"]
    if content.nil? || content.strip.empty?
      raise "LLM response did not include an answer."
    end
    content
  end

end
