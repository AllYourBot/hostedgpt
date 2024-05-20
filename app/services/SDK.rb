class SDK
  def self.key
    raise "self.key is undefined. You need to override this method."
  end

  def self.get(url)
    response = Faraday.get(url)
    binding.pry if response.status != 200
    raise "Unexpected response: #{response.status} - #{response.body}" if response.status != 200
    JSON.parse(response.body, object_class: OpenStruct)
  end

  def self.call(name, args)
    raise "'#{name} does not exist on this class" if self.method(name).nil?

    allowed_args = formatted_function_parameters_with_types(name).keys
    args.slice(*allowed_args)
    parameters = {}
    args.each do |arg, val|
      parameters[ argument_to_parameter(name, arg) ] = val
    end

    self.send(name, **parameters)
  end

  class << self
    def method_descriptions
      (@method_descriptions ||= {}).symbolize_keys
    end

    def describe(method_name, description)
      method_descriptions[method_name] = description
    end

    def description(method_name)
      method_descriptions[method_name] || default_description_for(method_name)
    end

    def default_description_for(name)
      name.to_s.split("_").join(" ").capitalize + " given " +
        self.method(name).parameters.reject { |p| p.first == :opt }.map(&:second).to_sentence
    end
  end

  def self.tools
    functions.map do |name|
      {
        type: "function",
        function: {
          name: name,
          description: description(name),
          parameters: {
            type: "object",
            properties: formatted_function_parameters_with_types(name),
            required: formatted_function_required_parameters(name),
          }
        }
      }
    end
  end

  def self.functions
    self.methods(false) - SDK.methods(false)
  end

  def self.function_parameters(name)
    self.method(name).parameters.map(&:second)
  end

  def self.formatted_function_parameters_with_types(name)
    function_parameters(name).map { |param| formatted_param_properties(param) }.to_h
  end

  def self.formatted_param_properties(param)
    raise "The param '#{param}' is not properly named for the type to be inferred (e.g. is_child, age_num, name_str)" if param.to_s.exclude?('_')

    case param.to_s.split('_')
    in first, *name  if first == "is"
      [ name.join('_'), { type: "boolean" } ]
    in name, "enum", *values
      if values.first.to_i.to_s == values.first
        type = "number"
        values = values.map(&:to_i)
      else
        type = "string"
      end

      [ name, { type: type, enum: values } ]
    in *name, last  if last == "s"
      [ name.join('_'), { type: "string" } ]
    in *name, last  if last == "i"
      [ name.join('_'), { type: "integer" } ]
    in *name, last  if last == "f"
      [ name.join('_'), { type: "number" } ]
    else
      raise "Unable to infer type for parameter '#{param}'"
    end
  end

  def self.formatted_function_required_parameters(name)
    params = self.method(name).parameters
    not_named = params.map(&:first) - [:keyreq, :key]
    raise "You must use named parameters and #{name} does not." if not_named.present?

    params.select { |p| p.first == :keyreq }.map do |_, param|
      formatted_param_properties(param).first
    end
  end

  def self.argument_to_parameter(method, argument)
    @@argument_to_parameter ||= {}
    @@argument_to_parameter[method] ||= {}
    if @@argument_to_parameter[method].empty?
      @@argument_to_parameter[method]

      self.method(method).parameters.map(&:second).each do |param|
        arg = formatted_param_properties(param).first
        @@argument_to_parameter[method][arg] = param
      end
    end
    @@argument_to_parameter[method][argument]
  end
end
