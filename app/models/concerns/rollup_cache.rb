module RollupCache
  extend ActiveSupport::Concern

  # Rails supports counter_cache on associations, e.g.
  #
  # Book.rb
  #   belongs_to :author, counter_cache: true
  #
  # And this keeps author.books_count updatd each time a new author is created, updated, or destroyed.
  # However, this option on belongs_to does not support conditional counter caches. For example,
  # if we only want to cache the published books. rollup_cache was created for this purpose and also
  # to support other rollups such as sums.
  #
  # Example count: book.rb:
  #
  # belongs_to :author, inverse_of: :books
  # rollup_cache :published_books_count, belongs_to: :author, if: :published?
  # rollup_cache :total_sales, sum: :sales, belongs_to: :author
  #
  # if the cache rollup name is _sum then it will be a sum instead of a count.
  #
  # Note: if an inverse_of is defined on the belongs_to then the referenced model will get a reset, e.g.:
  # book.reset_published_books_count!

  class_methods do
      def rollup_cache(name, opts = {})
          @_rollup_cache ||= []
          raise "#{self} defines a rollup_cache #{name} but it's missing a 'belongs_to'" if opts[:belongs_to].nil?

          multiple_belongs_to_models = Array(opts[:belongs_to])
          multiple_belongs_to_models.each do |model|
              @_rollup_cache << [ name.to_sym, opts.except(:belongs_to).merge(belongs_to: model) ]

              cache_onto_association = self.reflect_on_all_associations.find { |a| a.name == model }
              binding.pry if cache_onto_association.nil?
              raise "#{self} defines a rollup_cache #{name} which references #{model} but that association cannot be found" if cache_onto_association.nil?

              cache_onto_obj = cache_onto_association.klass

              if opts[:sum] && self.columns.find { |c| c.name == opts[:sum].to_s }.nil?
                raise "#{self} defines a rollup_cache #{name} which references #{opts[:sum]} but that column does not exist on #{self}"
              end

              # If we don't have an inverse_of, should we raise or simply not create a reset method? For now, let's just not create a reset method.
              next  if cache_onto_association.inverse_of.nil?
              # raise "#{self.to_s} has a rollup_cache :#{name} to :#{model} but the inverse_of :#{model} could not be determined, add inverse_of to :#{model}" if cache_onto_association.inverse_of.nil?

              cache_onto_obj.module_eval <<-STR
                def reset_#{name}!
                  if #{opts[:sum].present?}
                    if #{opts[:if].present?}
                      new_value = self.send(:#{cache_onto_association.inverse_of.name}).select { |record| record.send(:#{opts[:if] || "object_id"}) }.sum
                    else
                      new_value = self.send(:#{cache_onto_association.inverse_of.name}).sum(:#{opts[:sum]})
                    end
                  else
                    if #{opts[:if].present?}
                      new_value = self.send(:#{cache_onto_association.inverse_of.name}).select { |record| record.send(:#{opts[:if] || "object_id"}) }.length
                    else
                      new_value = self.send(:#{cache_onto_association.inverse_of.name}).count
                    end
                  end

                  self.update_column(:#{name}, new_value)
                end
              STR
          end
      end

      def _rollup_cache
          @_rollup_cache
      end
  end

  included do
    before_update :_check_rollup_cache_conditions_before_update
    after_update :_update_rollup_cache_for_update
    after_create :_update_rollup_cache_for_create
    after_destroy :_update_rollup_cache_for_destroy

    def _check_rollup_cache_conditions_before_update
      return unless self.class._rollup_cache

      saved_changes = _revert_changes # so conditions can be checked

      self.class._rollup_cache.each do |name, opts|
        obj, obj_id, passes_if_now = _rollup_cache_config_for(name, opts)
        next if obj.nil? || obj_id.nil?

        @_passes_if_before_update ||= {}
        @_passes_if_before_update[name] = passes_if_now
      end

      _reapply_changes(saved_changes)
    end

    def _revert_changes
      saved_changes = changes
      changes.each do |key, pair|
        before, after = pair

        self.send("#{key}=", before)
      end
      saved_changes
    end

    def _reapply_changes(chgs)
      chgs.each do |key, pair|
        before, after = pair

        self.send("#{key}=", after)
      end
    end

    def _update_rollup_cache_for_update
      _update_rollup_cache(:update)
    end

    def _update_rollup_cache_for_create
      _update_rollup_cache(:create)
    end

    def _update_rollup_cache_for_destroy
      _update_rollup_cache(:destroy)
    end

    def _update_rollup_cache(mode)
      return unless self.class._rollup_cache

      is_creating = mode == :create
      is_updating = mode == :update
      is_destroying = mode == :destroy

      self.class._rollup_cache.each do |name, opts|
        obj, obj_id, passes_if_now, passes_if_before_update = _rollup_cache_config_for(name, opts)
        next if obj.nil? || obj_id.nil?

        newly_created_record_that_passes_if = is_creating && passes_if_now
        destroying_a_record_that_passes_if  = is_destroying && passes_if_now
        updated_record_to_now_pass_if       = is_updating && !passes_if_before_update && passes_if_now
        updated_record_to_no_longer_pass_if = is_updating && passes_if_before_update && !passes_if_now

        if newly_created_record_that_passes_if || updated_record_to_now_pass_if
          if opts[:sum]
            record = obj.find(obj_id)
            record.update!(name => record.send(name) + self.send(opts[:sum]))
          else
            if opts[:callbacks]
              record = obj.find(obj_id)
              record.update!(name => record.send(name) + 1)
            else
              obj.increment_counter(name, obj_id, touch: true)
            end
          end
        end

        if destroying_a_record_that_passes_if || updated_record_to_no_longer_pass_if
          if opts[:sum]
            record = obj.find(obj_id)
            record.update!(name => record.send(name) - self.send(opts[:sum]))
          else
            if opts[:callbacks]
              record = obj.find(obj_id)
              record.update!(name => record.send(name) - 1)
            else
              obj.decrement_counter(name, obj_id, touch: true)
            end
          end
        end
      end
    end

    def _rollup_cache_config_for(name, opts)
      @_passes_if_before_update ||= {}

      association = self.class.reflect_on_all_associations.find { |a| a.name == opts[:belongs_to] }
      raise "#{self} defines a rollup_cache #{name} specified belongs_to of '#{opts[:belongs_to]}' but this association was not found." if association.nil?
      obj             = association.klass
      obj_instance    = self.send(opts[:belongs_to])
      obj_id = self.send(opts[:belongs_to])&.id

      rollup_cache_column = obj.columns.find { |c| c.name == name.to_s }
      raise "The column #{name} does not exist on #{obj}" if rollup_cache_column.nil?

      passes_if_now = opts[:if].nil? ? true : self.send(opts[:if])

      [obj, obj_id, passes_if_now, @_passes_if_before_update[name]]
    end
  end
end
