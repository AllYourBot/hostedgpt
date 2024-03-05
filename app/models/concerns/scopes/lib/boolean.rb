module Scopes::Lib::Boolean
  extend ActiveSupport::Concern

  included do
    boolean_columns = columns.select do |column|
      column.type == :boolean
    end

    boolean_columns.each do |column|
      auto_scope "#{column.name}", -> { where(column.name => true) }, column: column.name
      auto_scope "not_#{column.name}", -> { where(column.name => false) }, column: column.name
    end
  end
end
