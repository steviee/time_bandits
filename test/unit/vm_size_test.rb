require_relative '../test_helper'

class VmSizeTest < Test::Unit::TestCase
  test "accessing peak vm size" do
    assert_kind_of Integer, TimeBandits.peak_vm_size
  end

  test "accessing current vm size" do
    assert_kind_of Integer, TimeBandits.current_vm_size
  end

  if RUBY_PLATFORM =~ /darwin|linux/i

    test "peak vm size should be positive" do
      assert_operator TimeBandits.peak_vm_size, :>, 0
    end

    test "current vm size should be positive" do
      assert_operator TimeBandits.current_vm_size, :>, 0
    end

  end
end
