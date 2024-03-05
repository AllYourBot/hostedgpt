module Scopes::Lib
  module TimeRelated
    extend ActiveSupport::Concern

    included do
      def self.add_time_scopes
        ::Scopes::Lib::AddTimeRelated.new(self).add_scopes_to
      end

      add_time_scopes

      def self.add_time_scopes_to_association(assoc)
        ::Scopes::Lib::AddTimeRelated.new(self).add_scopes_to_association(assoc)
      end
    end
  end

  class AddTimeRelated
    def initialize(ar_class)
      @ar_class = ar_class
    end

    def add_scopes_to
      @klass_with_fields = @ar_class
      @column_prefix = ""
      add_input_to_time
      add_time_related_column_scopes
      add_date_related_column_scopes
      add_date_and_time_related_column_scopes
      add_date_and_time_helper_methods
    end

    def add_scopes_to_association(association)
      @klass_with_fields = @ar_class.reflect_on_association(association).klass
      @column_prefix = "#{association}_"
      add_date_related_column_scopes
    end

    def add_input_to_time
      @ar_class.define_singleton_method "input_to_time" do |t|
        t.is_a?(String) ? Time.zone.parse(t) : t
      end
    end

    def add_time_related_column_scopes
      time_related_columns.each do |column|
        label = column.name.gsub(/(_at)$/, "")
        table_column = "#{@ar_class.table_name}.#{column.name}"

        @ar_class.auto_scope "#{label}_on", -> (d) {
          d = d.to_date
          send("#{label}_between", d.beginning_of_day, d.end_of_day)
        }, column: column.name
        @ar_class.auto_scope "#{label}_after", -> (t) {
          where("#{table_column} > ?", input_to_time(t)).where("#{table_column} IS NOT NULL")
        }, column: column.name
        @ar_class.auto_scope "#{label}_less_than_this_long_ago", -> (t) {
          where("#{table_column} > ?", input_to_time(t)).where("#{table_column} IS NOT NULL")
        }, column: column.name
        @ar_class.auto_scope "#{label}_less_than", -> (t) {
          where("#{table_column} > ?", input_to_time(t)).where("#{table_column} IS NOT NULL")
        }, column: column.name
        @ar_class.auto_scope "#{label}_after_or_equal", -> (t) {
          where("#{table_column} >= ?", input_to_time(t)).where("#{table_column} IS NOT NULL")
        }, column: column.name
        @ar_class.auto_scope "#{label}_less_than_or_equal_to_this_long_ago", -> (t) {
          where("#{table_column} >= ?", input_to_time(t)).where("#{table_column} IS NOT NULL")
        }, column: column.name
        @ar_class.auto_scope "#{label}_less_than_or_equal_to", -> (t) {
          where("#{table_column} >= ?", input_to_time(t)).where("#{table_column} IS NOT NULL")
        }, column: column.name
        @ar_class.auto_scope "#{label}_before", -> (t) {
          where("#{table_column} < ?", input_to_time(t)).
            where("#{table_column} IS NOT NULL")
        }, column: column.name
        @ar_class.auto_scope "#{label}_more_than_this_long_ago", -> (t) {
          where("#{table_column} < ?", input_to_time(t)).
            where("#{table_column} IS NOT NULL")
        }, column: column.name
        @ar_class.auto_scope "#{label}_more_than", -> (t) {
          where("#{table_column} < ?", input_to_time(t)).
            where("#{table_column} IS NOT NULL")
        }, column: column.name
        @ar_class.auto_scope "#{label}_before_or_equal", -> (t) {
          where("#{table_column} <= ?", input_to_time(t)).
            where("#{table_column} IS NOT NULL")
        }, column: column.name
        @ar_class.auto_scope "#{label}_more_than_or_equal_to_this_long_ago", -> (t) {
          where("#{table_column} <= ?", input_to_time(t)).
            where("#{table_column} IS NOT NULL")
        }, column: column.name
        @ar_class.auto_scope "#{label}_more_than_or_equal_to", -> (t) {
          where("#{table_column} <= ?", input_to_time(t)).
            where("#{table_column} IS NOT NULL")
        }, column: column.name
        @ar_class.auto_scope "#{label}_between", -> (a, b) {
          where("#{table_column} >= ?", input_to_time(a)).
            where("#{table_column} <= ?", input_to_time(b)).
            where("#{table_column} IS NOT NULL")
        }, column: column.name
        @ar_class.auto_scope "#{label}_on_or_before", -> (d) {
          send("#{label}_before_or_equal", d.to_date.end_of_day)
        }, column: column.name
        @ar_class.auto_scope "#{label}_on_or_after", -> (d) {
          send("#{label}_after_or_equal", d.to_date.beginning_of_day)
        }, column: column.name
      end
    end

    def add_date_related_column_scopes
      date_related_columns(@klass_with_fields).each do |column|
        # Local variables are required for these to survive lexical scope
        # requirements of the lambdas being generated.
        label = @column_prefix + column.name.gsub(/(_on)$/, "")
        table_column = "#{@klass_with_fields.table_name}.#{column.name}"

        @ar_class.auto_scope "#{label}_on", -> (d) {
          where("#{table_column} = ?", d.to_date)
        }, column: column.name
        @ar_class.auto_scope "#{label}_after", -> (d) {
          where("#{table_column} > ?", d.to_date)
        }, column: column.name
        @ar_class.auto_scope "#{label}_after_or_equal", -> (d) {
          where("#{table_column} >= ?", d.to_date)
        }, column: column.name
        @ar_class.auto_scope "#{label}_before", -> (d) {
          where("#{table_column} < ?", d.to_date)
        }, column: column.name
        @ar_class.auto_scope "#{label}_before_or_equal", -> (d) {
          where("#{table_column} <= ?", d.to_date)
        }, column: column.name
        @ar_class.auto_scope "#{label}_between", -> (a, b) {
          where("#{table_column} between ? AND ?", a.to_date, b.to_date)
        }, column: column.name
        @ar_class.auto_scope "#{label}_on_or_before", -> (d) {
          send("#{label}_before_or_equal", d) #alias
        }, column: column.name
        @ar_class.auto_scope "#{label}_on_or_after", -> (d) {
          send("#{label}_after_or_equal", d) #alias
        }, column: column.name
      end
    end

    def add_date_and_time_related_column_scopes
      date_and_time_columns.each do |column|
        label = column.name.gsub(/(_at|_on)$/, "")
        table_column = "#{@ar_class.table_name}.#{column.name}"

        @ar_class.auto_scope "#{label}", -> {
          now = column.type == :date ? Date.today : Time.current
          where("#{table_column} is not null and #{table_column} <= ?", now)
        }, column: column.name
        @ar_class.auto_scope "not_#{label}", -> {
          now = column.type == :date ? Date.today : Time.current
          where("#{table_column} is null or #{table_column} > ?", now)
        }, column: column.name

        # .less_than(5.days.ago)
        @ar_class.auto_scope "#{label}_less_than", -> (d) { send("#{label}_after", d) }
        # .more_than(5.days.ago)
        @ar_class.auto_scope "#{label}_more_than", -> (d) { send("#{label}_before", d) }

        @ar_class.auto_scope "by_#{column.name}", -> { order("#{table_column} asc") }, priority: 100, column: column.name
        @ar_class.auto_scope "by_#{column.name}_desc", -> { order("#{table_column} desc") }, priority: 101, column: column.name
      end
    end

    def add_date_and_time_helper_methods
      date_and_time_columns.each do |column|
        label = column.name.gsub(/(_at|_on)$/, "")

        @ar_class.define_method "#{label}?" do
          now = column.type == :date ? Date.today : Time.current
          send(column.name).present? && send(column.name) <= now
        end

        @ar_class.define_method "not_#{label}?" do
          now = column.type == :date ? Date.today : Time.current
          send(column.name).blank? || send(column.name) > now
        end

        @ar_class.define_method "#{label}!" do
          return if send(column.name)

          now = column.type == :date ? Date.today : Time.current
          update!(column.name => now)
        end
      end
    end

    def time_related_columns(klass=nil)
      (klass || @ar_class).columns.select do |column|
        column.type == :datetime && column.name =~ /_at$/
      end
    end

    def date_related_columns(klass=nil)
      (klass || @ar_class).columns.select do |column|
        column.type == :date && (column.name =~ /_on$/ || column.name == "date" || column.name =~ /_date$/)
      end
    end

    def date_and_time_columns
      time_related_columns + date_related_columns
    end

    def self.scope_usage(name)
      case
        when name.match?(/_(?:less|more)_than/)
          "#{name}(5.days.ago)"
        when name.match?(/by_\w+desc/)
          "No arguments (newest to oldest)"
        when name.match?(/by_/)
          "No arguments (oldest to newest)"
        when name.match?(/_during/)
          "#{name}('16-17')"
        when name.match?(/_after|_on|_before/)
          "#{name}('2015-03-01')"
        when name.match?(/_between/)
          "#{name}('2015-03-01', '2015-03-31')"
      end
    end
  end
end
