# frozen_string_literal: true

# Reuse the minitest suite's microphone helper verbatim (dependency-free; its
# find_target comes from the element patch in features/support/system_parity.rb).
require Rails.root.join("test/support/microphone_helper")

World(MicrophoneHelper)
