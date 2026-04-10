# require and require_relative load code so we can use classes from other files.
require "json"
require_relative "document_loader"
require_relative "text_cleaner"
require_relative "text_chunker"
require_relative "embedding_generator"
require_relative "vector_store"
require_relative "../similarity_retriever"
require_relative "../prompt_builder"
require_relative "llm_client"

class CLICommands

  # data_dir = "data" means:
  # if no value is passed in, use "data" as default.
  # output = $stdout means:
  # write output to the terminal by default.
  def initialize(data_dir = "data", output = $stdout)
    # Variables that start with @ are instance variables.
    # They belong to this object and can be used by other methods in this class.
    @data_dir = data_dir
    @output = output

    # Create helper objects used by the RAG pipeline.
    @document_loader = DocumentLoader.new
    @text_cleaner = TextCleaner.new
    @text_chunker = TextChunker.new(100, 20)
  end

  # run is the main router for command-line arguments.
  # args is an array from ARGV in main.rb.
  def run(args)
    # args[0] is the command name typed by user.
    command = args[0]

    # if / elsif / else chooses one branch.
    if command == "ingest"
      # args[1] is file name after command.
      ingest(args[1])
    elsif command == "ask"
      file_name = args[1]

      # args[2..-1] means:
      # start at position 2 and go to the end of the array.
      # We use this because the question can contain many words.
      question_parts = args[2..-1]
      question = ""

      # nil means "no value".
      # This check avoids calling .join on nil.
      if question_parts != nil
        # join(" ") turns array elements into one string with spaces.
        question = question_parts.join(" ")
      end

      ask(file_name, question)
    elsif command == "sources"
      sources(args[1])
    elsif command == "reset"
      reset(args[1])
    else
      print_usage
    end

  # rescue => error catches the exceptions raised in this method.
  # It prevents crashing and prints a friendly message.
  rescue => error
    @output.puts "Error: #{error.message}"
  end

  # Ingest command:
  # 1) load file text
  # 2) clean text
  # 3) chunk text
  # 4) create embeddings
  # 5) save chunk + embedding + metadata
  def ingest(file_name)
    # raise stops execution and throws an error.
    raise "Usage: ruby main.rb ingest <file_name>" if blank_text?(file_name)

    file_path = document_path_for(file_name)

    # Load and prepare text.
    raw_text = @document_loader.load_document(file_path)
    clean_text = @text_cleaner.clean_text(raw_text)
    chunks = @text_chunker.chunk_text(clean_text)

    raise "No chunks were generated from the document." if chunks.empty?

    # Create a vector store file for this document.
    vector_store = VectorStore.new(store_path_for(file_name))

    # We clear old entries so re-ingest replaces old data.
    vector_store.clear

    # Create embedding client with real API key from environment variables.
    api_key = fetch_api_key
    embedding_generator = EmbeddingGenerator.new(api_key)

    # each_with_index loops through each chunk and also gives its index.
    # Block syntax: do |chunk, index| ... end
    chunks.each_with_index do |chunk, index|
      chunk_number = index + 1
      embedding = embedding_generator.generate_embedding(chunk)

      # Save chunk + embedding + metadata.
      vector_store.add(
        chunk,
        embedding,
        {
          # Build chunk id like: notes.txt_chunk_0001
          # File.basename(path) returns file name without folder path.
          # to_s converts number to string.
          # rjust(4, "0") pads left with zeros to length 4.
          "id" => "#{File.basename(file_name)}_chunk_#{chunk_number.to_s.rjust(4, "0")}",

          # Save source file name.
          "source" => File.basename(file_name),

          # Save chunk number in that file.
          "chunk_index" => chunk_number
        }
      )
    end

    # Write all entries to disk.
    vector_store.save_to_file
    @output.puts "Ingest complete: #{chunks.length} chunks indexed for #{file_name}."
  end

  # Ask command:
  # 1) load indexed vectors
  # 2) retrieve top chunks by similarity
  # 3) build prompt with context
  # 4) ask LLM for final grounded answer
  def ask(file_name, question)
    raise "Usage: ruby main.rb ask <file_name> \"<question>\"" if blank_text?(file_name)
    raise "Question cannot be empty." if blank_text?(question)

    vector_store = VectorStore.new(store_path_for(file_name))

    # unless means "if not".
    raise "No index found for #{file_name}. Run ingest first." unless vector_store.has_data?

    api_key = fetch_api_key
    embedding_generator = EmbeddingGenerator.new(api_key)

    retriever = SimilarityRetriever.new(embedding_generator, vector_store)
    top_chunks = retriever.find_top_k_chunks(question, 3)

    prompt_builder = PromptBuilder.new
    prompt = prompt_builder.build_grounded_prompt(question, top_chunks)

    llm_client = LLMClient.new(api_key)
    answer = llm_client.generate_answer(prompt)

    # Print answer.
    @output.puts "Answer:"
    @output.puts answer
    @output.puts "-" * 50
    @output.puts "Sources used:"

    # Print which chunks were used as evidence.
    top_chunks.each do |chunk|
      # || means "or".
      # If left side is nil/false, Ruby uses right side.
      source_name = chunk["source"] || "unknown_source"
      chunk_id = chunk["chunk_index"] || "?"
      score = format("%.4f", chunk["score"].to_f)
      @output.puts "- #{source_name}#chunk_#{chunk_id} (similarity=#{score})"
    end
  end

  # Sources command:
  # - with file name: show sources for one vector store
  # - without file name: list all vector stores
  def sources(file_name = nil)
    if !blank_text?(file_name)
      show_sources_for_one_file(file_name)
      return
    end

    # Find all *_vectors.json files in data directory.
    store_files = Dir.glob(File.join(@data_dir, "*_vectors.json")).sort

    if store_files.empty?
      @output.puts "No vector stores found in #{@data_dir}."
      return
    end

    @output.puts "Indexed vector stores:"
    store_files.each do |path|
      entries = JSON.parse(File.read(path))
      @output.puts "- #{File.basename(path)} (#{entries.length} chunks)"
    end
  end

  # Reset command:
  # remove all entries for one file's vector store.
  def reset(file_name)
    raise "Usage: ruby main.rb reset <file_name>" if blank_text?(file_name)

    vector_store = VectorStore.new(store_path_for(file_name))
    vector_store.clear
    vector_store.save_to_file
    @output.puts "Index reset complete for #{file_name}."
  end

  # Helper that prints all supported commands.
  def print_usage
    @output.puts "Usage:"
    @output.puts "  ruby main.rb ingest <file_name>"
    @output.puts "  ruby main.rb ask <file_name> \"<question>\""
    @output.puts "  ruby main.rb sources [file_name]"
    @output.puts "  ruby main.rb reset <file_name>"
  end

  # private means methods below are internal helpers.
  # They should only be called from inside this class.
  private

  # Show source list for one file's vector store.
  def show_sources_for_one_file(file_name)
    store_path = store_path_for(file_name)

    if !File.exist?(store_path)
      @output.puts "No vector store found for #{file_name}."
      return
    end

    vector_store = VectorStore.new(store_path)
    if !vector_store.has_data?
      @output.puts "No indexed sources yet for #{file_name}."
      return
    end

    @output.puts "Indexed sources for #{file_name}:"
    vector_store.list_sources.each do |source|
      @output.puts "- #{source}"
    end
  end

  # Build full path to the input document.
  # File.join safely joins folder + file name.
  def document_path_for(file_name)
    File.join(@data_dir, File.basename(file_name))
  end

  # Build full path for vector store JSON file.
  def store_path_for(file_name)
    File.join(@data_dir, "#{File.basename(file_name)}_vectors.json")
  end

  # Return true if value is nil or only spaces.
  def blank_text?(value)
    value.nil? || value.strip.empty?
  end

  # Read API key from environment variable GEMINI_API_KEY.
  # ENV is Ruby's built-in hash for environment variables.
  def fetch_api_key
    api_key = ENV["GEMINI_API_KEY"]
    raise "Set GEMINI_API_KEY before running this command." if blank_text?(api_key)
    api_key
  end

end
