require_relative "classes/document_loader"
require_relative "classes/text_cleaner"
require_relative "classes/text_chunker"
require_relative "classes/embedding_generator"
require_relative "classes/vector_store"
require_relative "classes/similarity_retriever"
require_relative "classes/prompt_builder"
require_relative "classes/llm_client"
require_relative "classes/cli_commands"

cli = CLICommands.new
cli.run(ARGV)
