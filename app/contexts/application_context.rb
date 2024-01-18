class ApplicationContext
  extend ActiveModel::Naming

  attr_reader :errors

  def initialize
    @errors = ActiveModel::Errors.new self
  end

  # helper methods for ActiveModel::Errors
  def read_attribute_for_validation(attr)
    send(attr)
  end

  def self.human_attribute_name(attr, options = {})
    attr.titleize
  end

  def self.lookup_ancestors
    [self]
  end
end
