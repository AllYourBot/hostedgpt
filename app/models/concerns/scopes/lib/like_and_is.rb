module Scopes::Lib::LikeAndIs

    extend ActiveSupport::Concern

    included do
        text_columns = columns.select do |column|
            column.type.in? [:text, :string, :citext]
        end

        datetime_columns = columns.select do |column|
            column.type.in? [:datetime]
        end

        numeric_columns = columns.select do |column|
            column.type.in? [:integer, :float, :decimal]
        end

        def self.wrap_like_query(q)
            /%/.match?(q) ? q : "%#{q}%"
        end

        text_columns.each do |column|
            auto_scope "#{column.name}_like", -> (q) { where "lower(#{table_name}.#{column.name}) like ?", wrap_like_query(q.downcase) }, column: column.name
            auto_scope "#{column.name}_not_like", -> (q) { where "lower(coalesce(#{table_name}.#{column.name}, '')) not like ?", wrap_like_query(q.downcase) }, column: column.name
            auto_scope "#{column.name}_ilike", -> (q) { where "#{table_name}.#{column.name} ilike ?", wrap_like_query(q) }, column: column.name
            auto_scope "#{column.name}_not_ilike", -> (q) { where "coalesce(#{table_name}.#{column.name}, '') not ilike ?", wrap_like_query(q) }, column: column.name
        end

        (text_columns + numeric_columns + datetime_columns).each do |column|
            # Supports:
            #   column_is(5)
            #   column_is('5')  a column like Unit.ngss_grade_is('3') requires a string
            #   column_is(">5")
            #   column_is(">= 5")
            #   column_is(nil)
            auto_scope "#{column.name}_is", -> (*q) {
                q = q.first if q.length == 1

                if q.is_a?(Array)
                    where("#{table_name}.#{column.name}": q)
                else
                    q = "is null" if q.nil?
                    q = "=#{q}" if q.is_a?(Numeric)
                    q = "=#{ActiveRecord::Base.connection.quote(q)}" unless q =~ /[=<>]|is null/
                    where "#{table_name}.#{column.name} #{q}"
                end
            }, column: column.name

            # Supports:
            #   column_is_not(5)
            #   column_is_not(nil)
            #
            # This does not work properly, not sure how to handle:
            #   column_is_not(">5")
            # should we throw an exception if a string is passed in? except for
            # completeness, I don't think it's important to support this case.
            auto_scope "#{column.name}_is_not", -> (*q) {
                q = q.first if q.length == 1

                if q.is_a?(Array)
                    where.not("#{table_name}.#{column.name}": q)
                else
                    q = "is not null" if q.nil?
                    q = q.to_s.gsub(/^([0-9]+)/, '<>\1') if q.is_a?(Integer)
                    q = "<>#{ActiveRecord::Base.connection.quote(q)} OR #{table_name}.#{column.name} IS NULL" unless q =~ /[=<>]|is not null/
                    where "#{table_name}.#{column.name} #{q}"
                end
            }, column: column.name
        end
    end
end
