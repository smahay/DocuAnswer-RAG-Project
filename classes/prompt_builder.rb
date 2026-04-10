# This class builds the final prompt sent to the LLM.
class PromptBuilder
  # 1) question -> the user's question text
  # 2) retrieved_chunks -> an array of chunk hashes from retriever
  def build_grounded_prompt(question, retrieved_chunks)

    if question.nil? || question.strip.empty?
      raise "Question cannot be empty."
    end

    # Check that we received at least one retrieved chunk.
    if retrieved_chunks.nil? || retrieved_chunks.empty?
      raise "No retrieved chunks were provided."
    end

    # Start with an empty string. We will add context lines to it.
    context_text = ""

    # Index counter for citation labels like [1], [2], [3].
    index = 0

    # each loops through every item in the array.
    # chunk is the item in each loop pass.
    retrieved_chunks.each do |chunk|
      # Human-friendly chunk number starts from 1 (not 0).
      chunk_number = index + 1

      source_name = chunk["source"] || "unknown_source"
      chunk_id = chunk["chunk_index"] || chunk_number

      # Convert score to float and format to 4 decimal places.
      score = format("%.4f", chunk["score"].to_f)

      # Pull actual chunk text.
      chunk_text = chunk["chunk"]

      # Build one context block line by line.
      context_text += "[#{chunk_number}] #{source_name}#chunk_#{chunk_id} (similarity=#{score})\n"
      context_text += "#{chunk_text}\n\n"

      # Move to next index for next chunk.
      index += 1
    end

    # <<~PROMPT starts a multi-line string.
    # It makes it easy to write long prompt text clearly.
    # The last expression in a Ruby method is returned automatically.
    <<~PROMPT
      You are DocuAnswer, a grounded document QA assistant.
      Use only the context chunks below to answer the question.
      If the answer is not present in the context, respond:
      "I could not find that in the provided documents."

      Always include source citations using bracket numbers like [1], [2].

      Context Chunks:
      #{context_text}
      Question:
      #{question}

      Output format:
      Answer: <concise answer>
      Sources: <comma-separated citation brackets used>
    PROMPT
  end

end
