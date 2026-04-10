# This compares the question embedding to each chunk embedding.
class SimilarityRetriever
  # Initializes with:
  # - `embedding_generator`: object that can create embeddings
  # - `vector_store`: object that stores chunks and embeddings
  def initialize(embedding_generator, vector_store)
    @embedding_generator = embedding_generator
    @vector_store = vector_store
  end

  # Finds the top matching chunks for one question.

  # top_k = 3 means default value is 3 if caller does not provide it.
  def find_top_k_chunks(question, top_k = 3)
    if question.nil? || question.strip.empty?
      raise "Question cannot be empty."
    end

    # Load all saved entries from vector store.
    entries = @vector_store.get_all_entries
    if entries.empty?
      raise "No indexed chunks found. Run ingest first."
    end

    # Create one embedding for the question text.
    question_embedding = @embedding_generator.generate_embedding(question)

    # We will fill this array with hashes:
    # { "chunk" => "...", "score" => 0.87, ... }
    scored_entries = []

    # each loops through every entry in `entries`.
    entries.each do |entry|
      # Compute similarity score between question and this chunk.
      score = cosine_similarity(question_embedding, entry["embedding"])

      # Add one scored result to output array.
      scored_entries.push(
        {
          "chunk" => entry["chunk"],
          "score" => score,

          # If source is nil/false, use "unknown_source".
          "source" => entry["source"] || "unknown_source",
          "chunk_index" => entry["chunk_index"],
          "id" => entry["id"]
        }
      )
    end

    # Sort results by score descending (highest first).
    # sort_by! changes the array in place.
    scored_entries.sort_by! { |item| -item["score"] }

    # Make sure top_k is at least 1.
    # to_i converts text/numbers to integer.
    limit = top_k.to_i
    if limit < 1
      limit = 1
    end

    # Return only the first "limit" results.
    scored_entries.first(limit)
  end

  # Cosine similarity compares direction of 2 vectors.
  # Result range:
  # - 1.0 = very similar
  # - 0.0 = unrelated
  # - -1.0 = opposite direction
  def cosine_similarity(vector_a, vector_b)
    # Validate vectors before math.
    return 0.0 unless valid_vector?(vector_a)
    return 0.0 unless valid_vector?(vector_b)
    return 0.0 unless vector_a.length == vector_b.length

    # dot_product = sum(a_i * b_i)
    dot_product = 0.0

    # norm_a and norm_b are vector lengths (magnitudes) squared.
    norm_a = 0.0
    norm_b = 0.0

    # We loop index 0...length-1
    index = 0
    while index < vector_a.length
      # to_f converts values to float numbers.
      a = vector_a[index].to_f
      b = vector_b[index].to_f

      dot_product += a * b
      norm_a += a * a
      norm_b += b * b

      # Move to next position.
      index += 1
    end

    # If any norm is zero, similarity is undefined.
    # We return 0.0 to avoid division by zero.
    if norm_a == 0.0 || norm_b == 0.0
      return 0.0
    end

    # Math.sqrt(x) returns square root of x.
    dot_product / (Math.sqrt(norm_a) * Math.sqrt(norm_b))
  end

  # private means helper methods below should only be called
  # from inside this class.
  private

  # Returns true only when value is a non-empty Array.
  def valid_vector?(value)
    value.is_a?(Array) && !value.empty?
  end

end
