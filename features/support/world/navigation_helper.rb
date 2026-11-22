# frozen_string_literal: true

# Reuse the minitest suite's morph/navigation helper verbatim (see KTD2: it is
# dependency-free, so requiring it avoids a copy that would drift). Its helpers
# (assert, find, first_message, get_scroll_position) come from the assertions
# and SystemHelpers already mixed into this World.
require Rails.root.join("test/support/navigation_helper")

World(NavigationHelper)
