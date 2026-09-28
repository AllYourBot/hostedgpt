#!/usr/bin/env ruby
# frozen_string_literal: true

Dir.glob(File.join(__dir__, "*.test.rb")).sort.each { |f| require f }
