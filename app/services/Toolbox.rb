class Toolbox < SDK
  def self.call(name, args)
    kname, method = name.split("_", 2)
    klass = Toolbox.descendants.find { |k| k.to_s.downcase == kname }
    raise "'#{kname}' does not match a class which is a descendant of SDK" if klass.nil?
    raise "'#{method} does not exist on this class" if klass.method(method).nil?

    # arguments are what OpenAI calls them, parameters are what the ruby method expects
    parameters = {}
    allowed_args = klass.formatted_function_parameters_with_types(method).keys # args may include hallucinations

    args.slice(*allowed_args).each do |arg, val|
      parameters[ klass.argument_to_parameter(method, arg) ] = val
    end

    klass.send(method, **parameters)
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
          name: "#{self.to_s.downcase}_#{name}",
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
