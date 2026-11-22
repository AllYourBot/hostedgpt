# Cucumber-side hook for the Chrome 158 teardown shim. The shared
# implementation and its removal notes live in
# test/support/chrome_reset_compat.rb — see that file for the issue, the
# solutions considered, and when to delete both copies.
require Rails.root.join("test/support/chrome_reset_compat")
