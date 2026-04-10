class TextChunker


  # chunk_size = how many words go in each chunk
  # overlap    = how many words to repeat between chunks (so we don't lose context)
  def initialize(chunk_size, overlap)
    @chunk_size = chunk_size
    @overlap    = overlap
  end

  # Does the actual cutting
  # It takes the full text and gives back a list of chunks
  def chunk_text(text)

    # Split the entire text into a list of individual words
    words = text.split

    # Start with an empty list -- we will fill it with chunks
    chunks = []
    start_index = 0

    # "step" is how far we move forward after each chunk
    # If chunk_size is 100 and overlap is 20, step is 80
    # That means 20 words are shared between every pair of neighbouring chunks
    step = @chunk_size - @overlap

    # Keep looping until start_index goes past the last word
    while start_index < words.length

      # Grab a group of words starting at start_index
      # words[start_index, @chunk_size] means:
      #   "start at position start_index and give me up to @chunk_size words"
      chunk_words = words[start_index, @chunk_size]

      # Glues the words back into a sentence with spaces between them
      # .join(" ") is the opposite of .split -- it puts words back together
      one_chunk = chunk_words.join(" ")

      # Adds the chunk to our list
      chunks.push(one_chunk)

      # Move our starting position forward by "step" words
      # NOT by chunk_size, because we want that overlap at the beginning
      start_index = start_index + step

    end

    # Give back the finished list of all chunks
    return chunks

  end

end