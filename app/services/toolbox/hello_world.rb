class Toolbox::HelloWorld < Toolbox
  def self.hi(name_s:)
    "Hello, #{name_s}!"
  end

  def self.bad
    raise "The HTTP call failed because of a network issue"
  end
end
