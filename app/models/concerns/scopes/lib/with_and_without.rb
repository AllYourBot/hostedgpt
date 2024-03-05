module Scopes::Lib::WithAndWithout

    extend ActiveSupport::Concern

    included do
        text_columns = columns.select do |column|
            column.type.in? [:string, :text, :citext]
        end

        text_columns.each do |column|
            auto_scope "with_#{column.name}", -> { where("#{table_name}.#{column.name} is not null and length(#{table_name}.#{column.name}) > 0") }, column: column.name
            auto_scope "without_#{column.name}", -> { where("#{table_name}.#{column.name} is null or length(#{table_name}.#{column.name}) = 0") }, column: column.name
        end

        other_columns = columns.select do |column|
            column.type.in? [:integer, :datetime, :date]
        end

        other_columns.each do |column|
            auto_scope "with_#{column.name}", -> { where("#{table_name}.#{column.name} is not null") }, column: column.name
            auto_scope "without_#{column.name}", -> { where("#{table_name}.#{column.name} is null") }, column: column.name
        end
    end
end
