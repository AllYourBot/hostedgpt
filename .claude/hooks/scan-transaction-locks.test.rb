#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "shellwords"

class ScanTransactionLocksTest < Minitest::Test
  SCANNER = File.join(__dir__, "scan-transaction-locks.rb")

  def scan(*sources)
    Dir.mktmpdir do |dir|
      paths = sources.each_with_index.map do |src, i|
        path = File.join(dir, "fixture_#{i}.rb")
        File.write(path, src)
        path
      end
      out = `#{SCANNER.shellescape} --files #{paths.map(&:shellescape).join(" ")} 2>&1`
      assert_equal 0, $?.exitstatus, "enumerator must always exit 0:\n#{out}"
      out
    end
  end

  def test_inline_block_with_perform_later_is_listed_with_hint
    out = scan <<~RUBY
      def claim
        record.with_lock do
          record.update!(state: "claimed")
          SomeJob.perform_later(record)
        end
      end
    RUBY
    assert_includes out, "with_lock do"
    assert_includes out, "[cross-DB enqueue]"
    assert_includes out, "perform_later"
  end

  def test_subprocess_and_network_and_agent_turn_hints
    assert_includes scan(<<~RUBY), "[subprocess]"
      ApplicationRecord.transaction do
        row.update!(x: 1)
        Open3.capture2e("claude", "/context")
      end
    RUBY
    assert_includes scan(<<~RUBY), "[network]"
      account.transaction do
        account.touch
        Net::HTTP.get(URI("https://example.com"))
      end
    RUBY
    assert_includes scan(<<~RUBY), "[agent turn]"
      owner.with_lock do
        owner.lock!
        agent.respond_to(message)
      end
    RUBY
  end

  def test_forwarded_block_is_listed_for_caller_tracing
    out = scan <<~RUBY
      def guarded(&)
        record.with_lock(&)
      end
    RUBY
    assert_includes out, "with_lock(&)"
    assert_includes out, "forwards a block"
  end

  def test_yield_inside_inline_block_is_flagged_for_caller_tracing
    out = scan <<~RUBY
      def guarded
        record.with_lock do
          yield
        end
      end
    RUBY
    assert_includes out, "yields to the caller's block"
  end

  def test_clean_inline_block_is_listed_for_tracing_without_a_slow_hint
    out = scan <<~RUBY
      def claim
        record.with_lock do
          record.reload
          record.update!(pending_job_id: id) if record.pending_job_id.nil?
        end
      end
    RUBY
    assert_includes out, "with_lock do"
    assert_includes out, "trace its body"
    refute_includes out, "holds slow work"
  end

  def test_inline_brace_block_with_perform_later
    assert_includes scan("record.with_lock { SomeJob.perform_later(record) }\n"), "[cross-DB enqueue]"
  end

  def test_transaction_with_kwargs
    assert_includes scan(<<~RUBY), "[cross-DB enqueue]"
      transaction(requires_new: true) do
        touch
        SomeJob.perform_later(self)
      end
    RUBY
  end

  def test_nested_block_does_not_truncate_the_body
    assert_includes scan(<<~RUBY), "[cross-DB enqueue]"
      record.with_lock do
        items.each do |item|
          item.touch
        end
        SomeJob.perform_later(record)
      end
    RUBY
  end

  def test_respond_to_predicate_is_not_flagged_as_an_agent_turn
    out = scan <<~RUBY
      record.with_lock do
        record.update!(state: "x") if record.respond_to?(:state)
      end
    RUBY
    refute_includes out, "[agent turn]"
  end

  def test_token_inside_a_string_is_not_a_site
    out = scan <<~RUBY
      DESC = "use with_lock, don't forget the recheck"
      def run
        Net::HTTP.get(uri)
      end
    RUBY
    assert_includes out, "No transaction/with_lock sites"
  end

  def test_association_without_a_block_is_not_a_site
    out = scan <<~RUBY
      def amount
        payment.transaction.amount
      end
    RUBY
    assert_includes out, "No transaction/with_lock sites"
  end

  def test_own_source_and_fixtures_are_skipped
    Dir.mktmpdir do |dir|
      path = File.join(dir, "scan-transaction-locks.rb")
      File.write(path, "record.with_lock { SomeJob.perform_later(record) }\n")
      out = `#{SCANNER.shellescape} --files #{path.shellescape} 2>&1`
      assert_equal 0, $?.exitstatus
      assert_includes out, "No changed Ruby files to scan."
    end
  end
end
