#!/usr/bin/env ruby
# frozen_string_literal: true

OPENER = /(?:\.transaction\b|\btransaction\s*\(|\btransaction\s+do\b|\.with_lock\b|\bwith_lock\b|\bacquire\w*lock\w*)/
FORWARDS_BLOCK = /\b(?:transaction|with_lock|acquire\w*lock\w*)\s*\(\s*&\w*\s*\)/

SLOW_WORK = {
  "subprocess" => /\bOpen3\b|`[^`]*`|\bsystem\(|\bsystem\s+["']|%x[(\[{|<]|\bspawn\(/,
  "network" => /\bNet::HTTP\b|\bFaraday\b|\bHTTParty\b|\bRestClient\b|\bExcon\b|\bURI\.open\b|\bopen\(["']https?:/,
  "cross-DB enqueue" => /\bperform_later\b|\bperform_now\b/,
  "agent turn" => /\brespond_to\b(?!\?)|\bsession\s+do\b|\bkeep_alive\b|\bsend_and_wait\b/,
  "large scan" => /\bfind_each\b|\bin_batches\b/
}.freeze

Site = Struct.new(:file, :line_no, :kind, :opener, :hints, :yields)

def merge_base
  %w[origin/main main].each do |ref|
    base = `git merge-base #{ref} HEAD 2>/dev/null`.strip
    return base unless base.empty?
  end
  ""
end

def changed_ruby_files
  base = merge_base
  outputs = []
  outputs << `git diff --name-only #{base}...HEAD 2>/dev/null` unless base.empty?
  outputs << `git diff --name-only 2>/dev/null`
  outputs << `git diff --cached --name-only 2>/dev/null`
  outputs.join("\n").split("\n").map(&:strip).reject(&:empty?).uniq
    .select { |f| f.end_with?(".rb") && File.exist?(f) }
end

def block_body_range(lines, open_idx)
  line = lines[open_idx]
  opener_indent = line[/\A\s*/]

  if line =~ /\{[^}]*\}/ && line !~ /\bdo\b\s*(\|[^|]*\|)?\s*\z/
    return [open_idx, open_idx]
  end

  close_at_opener_indent = if line =~ /\{\s*(\|[^|]*\|)?\s*\z/
    /\A#{Regexp.escape(opener_indent)}\}/
  else
    /\A#{Regexp.escape(opener_indent)}end\b/
  end

  ((open_idx + 1)...lines.length).each do |j|
    return [open_idx + 1, j - 1] if lines[j] =~ close_at_opener_indent
  end
  [open_idx + 1, lines.length - 1]
end

def opens_inline_block?(line)
  line =~ /\bdo\b\s*(\|[^|]*\|)?\s*(#.*)?\z/ || line.include?("{")
end

def own_scanner_file?(path)
  File.basename(path).start_with?("scan-transaction-locks")
end

def scan_file(path)
  lines = File.readlines(path, chomp: true)
  sites = []

  lines.each_index do |i|
    line = lines[i]
    next if line.strip.start_with?("#")
    next unless line =~ OPENER

    if line =~ FORWARDS_BLOCK
      sites << Site.new(path, i + 1, :forwarded, line.strip, [], false)
    elsif opens_inline_block?(line)
      body_start, body_end = block_body_range(lines, i)
      body = lines[body_start..body_end].reject { |l| l.strip.start_with?("#") }
      hints = SLOW_WORK.flat_map do |category, pattern|
        body.select { |l| l =~ pattern }.map { |l| [category, l.strip] }
      end
      yields = body.any? { |l| l =~ /\byield\b/ }
      sites << Site.new(path, i + 1, :inline, line.strip, hints, yields)
    end
  end

  sites
end

files = if ARGV.first == "--files"
  ARGV.drop(1)
else
  changed_ruby_files
end

files = files.reject { |f| own_scanner_file?(f) }

if files.empty?
  puts "No changed Ruby files to scan."
  exit 0
end

sites = files.flat_map { |f| scan_file(f) }

if sites.empty?
  puts "No transaction/with_lock sites in #{files.length} changed file(s)."
  exit 0
end

puts "#{sites.length} lock site(s) in the changed files. TRACE what runs while each"
puts "lock is held — into forwarded blocks AND called methods — before approving:"
puts
sites.group_by(&:file).each do |file, group|
  puts file
  group.each do |s|
    puts "  L#{s.line_no}  #{s.opener}"
    case s.kind
    when :forwarded
      puts "          ↳ forwards a block (&) — grep callers of this method and trace THEIR block"
    when :inline
      s.hints.each { |category, text| puts "          ↳ holds slow work? [#{category}] #{text}  — confirm" }
      puts "          ↳ yields to the caller's block — grep callers and trace it" if s.yields
      if s.hints.empty? && !s.yields
        puts "          ↳ inline block — trace its body and every method it calls"
      end
    end
  end
  puts
end
puts "Audit question for each: does any path that runs while the lock is held do"
puts "I/O or call out of the DB (subprocess / network / cross-DB perform_later /"
puts "agent turn / large scan), INCLUDING inside a forwarded block or a called"
puts "method? If so, restructure per .claude/rules/job.md (slow work before the"
puts "lock; cheap rows-only critical section; TOCTOU recheck inside); see model.md"
puts "for the enqueue-outside-the-lock pattern."
puts
puts "Blind spots: this lists only explicit lock sites in the diff. A slow write"
puts "inside a transaction opened by a CALLER (no opener here) won't appear — those"
puts "holders are found in the runtime sqlite_locks.log (#544), not by this pass."
exit 0
