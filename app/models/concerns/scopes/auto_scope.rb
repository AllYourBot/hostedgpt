module Scopes::AutoScope
  extend ActiveSupport::Concern

  class_methods do
    # Add a scope, but only if it does not already exist. This should be used
    # for auto-generated scopes so that they do not override something that has
    # been manually defined.
    def auto_scope(name, body, opts={}, &block)
      opts = opts.merge(auto: true)

      if !respond_to?(name)
        scope(name, body, &block)
      end
    end
  end
end
