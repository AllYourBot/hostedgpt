module Scopes::AutoGenerated
    extend ActiveSupport::Concern

    include Scopes::AutoScope

    class_methods do
        def inherited(child)
            super(child)

            # This TracePoint is used to include the scopes after everything else
            # (when the final `end` of the enclosing class is reached. The included
            # concerns only add scopes if they are *not* already defined in the
            # class.
            TracePoint.trace(:end) do |t|
                if child == t.self
                    child.include(Scopes::Lib::Boolean)
                    child.include(Scopes::Lib::TimeRelated)
                    child.include(Scopes::Lib::LikeAndIs)
                    child.include(Scopes::Lib::WithAndWithout)
                    t.disable
                end
            end
        end
    end
end
