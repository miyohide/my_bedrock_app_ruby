#!/usr/bin/env ruby

require 'aws-sdk-bedrockruntime'
require 'json'

class BedrockNovaConsole
  def initialize
    @client = Aws::BedrockRuntime::Client.new(
      region: ENV['AWS_REGION'] || 'us-east-1'
    )
    @model_id = 'amazon.nova-lite-v1:0'
    @max_tokens = 3000
    @temperature = 0.7
  end

  def run
    puts "AWS Bedrock Amazon Nova Console"
    puts "================================"
    puts "Enter 'quit' or 'exit' to terminate"
    puts "Enter 'help' for available commands"
    puts "Current model: #{@model_id}"
    puts

    loop do
      print "> "
      input = gets&.chomp

      break if input.nil? || ['quit', 'exit'].include?(input.downcase)

      case input.downcase
      when 'help'
        show_help
      when ''
        next
      else
        send_message(input)
      end
    end

    puts "\nGoodbye!"
  end

  private

  def show_help
    puts <<~HELP
      Available commands:
        help           - Show this help message
        quit/exit      - Exit the application

      Or simply type a message to chat with the model.
    HELP
  end

  def send_message(message)
    begin
      puts "Sending message to #{@model_id}..."

      request_body = {
        messages: [
          {
            role: "user",
            content: [
              {
                text: message,
                cache_point: {
                  type: "default"
                }
              }
            ]
          }
        ]
      }

      response = @client.converse({
        model_id: @model_id,
        messages: request_body[:messages],
        inference_config: request_body[:inferenceConfig]
      })

      # レスポンスの処理
      if response.output && response.output.message
        content = response.output.message.content
        if content && content.first && content.first.text
          puts "\nResponse:"
          puts content.first.text
        else
          puts "No text content in response"
        end
      else
        puts "Unexpected response format"
      end

      # 使用量情報の表示
      if response.usage
        puts "\nUsage:"
        puts "  Input tokens: #{response.usage.input_tokens}"
        puts "  Output tokens: #{response.usage.output_tokens}"
        puts "  Total tokens: #{response.usage.total_tokens}"
      end

    rescue Aws::BedrockRuntime::Errors::ServiceError => e
      puts "AWS Bedrock Error: #{e.message}"
      puts "Error code: #{e.code}" if e.respond_to?(:code)
    rescue Aws::Errors::NoSuchEndpointError => e
      puts "Endpoint Error: #{e.message}"
      puts "Make sure the model ID is correct and available in your region"
    rescue Aws::Errors::MissingCredentialsError => e
      puts "Credentials Error: #{e.message}"
      puts "Please configure your AWS credentials"
    rescue StandardError => e
      puts "Error: #{e.message}"
      puts "#{e.class}: #{e.backtrace.first}" if ENV['DEBUG']
    end

    puts
  end
end

# アプリケーションの実行
console = BedrockNovaConsole.new

console.run
