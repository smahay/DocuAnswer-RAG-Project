class TextChunker
  def initialize(chunk_size, overlap)
    @chunk_size = chunk_size
    @overlap = overlap
  end

  def chunk_text(text)
    words = text.split
    chunks = []
    start_index = 0
    step = @chunk_size - @overlap

    while start_index < words.length
      chunk_words = words[start_index, @chunk_size]
      chunk_text = chunk_words.join(" ")
      chunks.push(chunk_text)
      start_index = start_index + step
    end

    return chunks
  end
end