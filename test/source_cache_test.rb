# frozen_string_literal: true

require 'test_helper'
require 'fileutils'
require 'tempfile'

class SourceCacheTest < Minitest::Test
  def setup
    @file = Tempfile.new(['cached', '.rb'])
    @file.write("original\n")
    @file.close
  end

  def teardown
    FileUtils.rm_f(@file.path)
  end

  def test_reads_once_per_file_and_kind
    calls = 0

    3.times { Typerb::SourceCache.read(@file.path, :probe) { calls += 1 } }

    assert_equal 1, calls
  end

  def test_returns_the_cached_value
    first = Typerb::SourceCache.read(@file.path, :probe_value) { Object.new }
    second = Typerb::SourceCache.read(@file.path, :probe_value) { Object.new }

    assert_same first, second
  end

  def test_keeps_separate_entries_per_kind
    assert_equal :a, Typerb::SourceCache.read(@file.path, :probe_a) { :a }
    assert_equal :b, Typerb::SourceCache.read(@file.path, :probe_b) { :b }
  end

  def test_rereads_after_the_file_changes
    assert_equal :before, Typerb::SourceCache.read(@file.path, :probe_change) { :before }

    File.write(@file.path, "a much longer body than the original\n")
    File.utime(Time.now + 5, Time.now + 5, @file.path)

    assert_equal :after, Typerb::SourceCache.read(@file.path, :probe_change) { :after }
  end

  def test_evicts_the_oldest_entry_beyond_the_limit
    files = Array.new(Typerb::SourceCache::LIMIT + 1) do |index|
      path = Tempfile.new(["evicted#{index}", '.rb'])
      path.write("body #{index}\n")
      path.close
      path
    end

    files.each { |file| Typerb::SourceCache.read(file.path, :probe_evict) { :cached } }

    calls = 0
    Typerb::SourceCache.read(files.first.path, :probe_evict) { calls += 1 }

    assert_equal 1, calls
  ensure
    files&.each { |file| FileUtils.rm_f(file.path) }
  end

  def test_raises_for_a_missing_file
    assert_raises(Errno::ENOENT) { Typerb::SourceCache.read('/nonexistent/typerb.rb', :probe) { :never } }
  end
end
