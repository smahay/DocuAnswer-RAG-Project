# We need "json" so we can save our data to a file and load it back later
# JSON is a very common format for storing data -- it looks like this:
# { "name": "Ruby", "version": 3 }
require "json"

# This class is like a filing cabinet for our chunks and their embeddings
# It does three main jobs:
#   1. Remember chunks and their embeddings while the program is running
#   2. Save them to a file on the computer so we don't lose them
#   3. Load them back from that file the next time the program runs
#
# This is important because generating embeddings costs API calls
# Without a vector store, we would have to regenerate every embedding every single run
class VectorStore

  # initialize runs automatically when we create a new VectorStore
  # It takes one thing: the path to the file where we will save our data
  # For example: "data/vector_store.json"
  def initialize(file_path)

    # Save the file path so our other methods know where to read and write
    @file_path = file_path

    # @entries is our in-memory filing cabinet
    # It is a list of entries, and each entry looks like this:
    # { "chunk" => "some text...", "embedding" => [0.12, -0.34, 0.88, ...] }
    # We start with an empty list and fill it up as we add chunks
    @entries = []

    # When the program starts, try to load any data that was saved before
    # This way we do not have to regenerate embeddings we already have
    load_from_file

  end

  # This method adds one chunk and its embedding to our in-memory list.
  # metadata can include extra fields such as id, source, and chunk_index.
  def add(chunk, embedding, metadata = {})

    # Build one entry as a Ruby hash (a collection of labelled values)
    # Think of it like a small form with two fields filled in
    entry = {
      "chunk"     => chunk,
      "embedding" => embedding
    }

    metadata_hash = metadata.is_a?(Hash) ? metadata : {}
    metadata_hash.each do |key, value|
      entry[key.to_s] = value
    end

    # Add that entry to the end of our list
    @entries.push(entry)

  end

  # This method saves everything in @entries to a JSON file on the computer
  # We call this after we have finished adding all our chunks
  def save_to_file

    # File.open opens the file at @file_path ready for writing
    # "w" means "write mode" -- it creates the file if it does not exist
    # and replaces it if it does
    # The file and the block of code are connected by "do |file|"
    File.open(@file_path, "w") do |file|

      # JSON.pretty_generate turns our @entries list into a nicely formatted
      # JSON string and file.write saves that string into the file
      # "pretty" means it adds spacing so a human can read the file easily
      file.write(JSON.pretty_generate(@entries))

    end

    # Let the user know the save worked
    puts "Vector store saved to #{@file_path}"

  end

  # This method loads saved entries from the JSON file back into @entries
  # It runs automatically when we create a new VectorStore (see initialize above)
  def load_from_file

    # First check if the file actually exists yet
    # The very first time the program runs there will be no file, and that is okay
    if File.exist?(@file_path)

      # File.read opens the file and gives us back everything inside it as a string
      raw_text = File.read(@file_path)

      # JSON.parse turns that string back into a real Ruby list of hashes
      # Now @entries is filled with everything we saved last time
      @entries = JSON.parse(raw_text)

      # Let the user know how many entries we loaded
      puts "Loaded #{@entries.length} entries from vector store."

    else

      # No file found, so we just start with an empty list
      # This is normal the first time the program runs
      puts "No existing vector store found. Starting fresh."

    end

  end

  # This method checks if the vector store already has data saved in it
  # It gives back true if there are entries, false if the list is empty
  # We use this in main.rb to decide whether to generate embeddings or skip that step
  def has_data?
    @entries.length > 0
  end

  # This method gives back the full list of entries
  # Other parts of the program (like the similarity calculator) will need this
  # to compare the question embedding against every stored chunk embedding
  def get_all_entries
    return @entries
  end

  # Returns a unique list of source names currently in the index.
  def list_sources
    @entries
      .map { |entry| entry["source"] }
      .compact
      .uniq
  end

  # Returns all entries that came from a specific source.
  def find_by_source(source_name)
    @entries.select { |entry| entry["source"] == source_name }
  end

  # This method wipes everything and starts fresh
  # Useful if you load a completely new document and need to replace the old data
  def clear
    @entries = []
    puts "Vector store cleared."
  end

end
