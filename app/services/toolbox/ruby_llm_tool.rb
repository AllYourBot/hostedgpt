# One Toolbox function as a real RubyLLM::Tool. The name, description and JSON
# schema come straight from the Toolbox descriptor (Toolbox.tools), so the model
# sees the same tools as before; execute runs the function through Toolbox.call,
# which maps the model's arguments onto the method's typed parameters
# (name -> name_s) and drops any it made up.
class Toolbox::RubyLLMTool < ::RubyLLM::Tool
  def initialize(descriptor)
    @name = descriptor.dig(:function, :name)
    @description = descriptor.dig(:function, :description)
    @parameters_schema = descriptor.dig(:function, :parameters)
  end

  # Overrides are required: the base class otherwise derives these from the
  # class, collapsing every tool into one.
  def name = @name

  def description = @description

  def parameters_schema = @parameters_schema

  def execute(**arguments)
    Toolbox.call(name, arguments).to_json
  rescue => e
    Rails.logger.info "## Handled error calling tools: #{e.message}" unless Rails.env.test?
    Rails.logger.info e.backtrace.join("\n") unless Rails.env.test?

    <<~STR.gsub("\n", " ").to_json
      An unexpected error occurred (#{e.message}). You were querying information to help you answer a users question. Because this information
      is not available at this time, DO NOT MAKE ANY GUESSES as you attempt to answer the users questions. Instead, consider attempting a
      different query OR let the user know you attempted to retrieve some information but the website is having difficulties at this time.
    STR
  end
end
