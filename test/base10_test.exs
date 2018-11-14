defmodule Base10Test do
  use ExUnit.Case
  doctest Base10

  test "encode/2 encodes binaries" do
    bin = "cheese and onions"
    string = "33826720516383156940929764387734877597299"
    assert Base10.encode10(bin) == string
    assert Base10.encode10(bin, padding: true) == string
    assert Base10.encode10(bin, padding: false) == string

    for c <- 0..255 do
      assert <<c::utf8>> |> Base10.encode10() |> String.valid?()
    end
  end

  test "encode/2 encodes leading zeroes" do
    zeroes_bin = <<0, 1>>
    two_zeroes_bin = <<0, 0, 1>>

    assert Base10.encode10(zeroes_bin) == "1"
    assert Base10.encode10(zeroes_bin, padding: true) == "01"
    assert Base10.encode10(zeroes_bin, padding: false) == "1"

    assert Base10.encode10(two_zeroes_bin) == "1"
    assert Base10.encode10(two_zeroes_bin, padding: true) == "001"
    assert Base10.encode10(two_zeroes_bin, padding: false) == "1"
  end

  test "encode/2 encodes empty strings" do
    assert Base10.encode10(<<>>) == <<>>
    assert Base10.encode10(<<>>, padding: true) == <<>>
    assert Base10.encode10(<<>>, padding: false) == <<>>
  end

  test "decode!/2 decodes binaries" do
    bin = "cheese and onions"
    string = "33826720516383156940929764387734877597299"
    assert Base10.decode10!(string) == bin
    assert Base10.decode10!(string, padding: true) == bin
    assert Base10.decode10!(string, padding: false) == bin
  end

  test "decode/2 decodes binaries" do
    bin = "cheese and onions"
    string = "33826720516383156940929764387734877597299"
    assert Base10.decode10(string) == {:ok, bin}
    assert Base10.decode10(string, padding: true) == {:ok, bin}
    assert Base10.decode10(string, padding: false) == {:ok, bin}
  end

  test "decode!/2 decodes empty strings" do
    assert Base10.decode10!(<<>>) == <<>>
    assert Base10.decode10!(<<>>, padding: true) == <<>>
    assert Base10.decode10!(<<>>, padding: false) == <<>>
  end

  test "decode/2 decodes empty strings" do
    assert Base10.decode10(<<>>) == {:ok, <<>>}
    assert Base10.decode10(<<>>, padding: true) == {:ok, <<>>}
    assert Base10.decode10(<<>>, padding: false) == {:ok, <<>>}
  end

  test "decode!/2 decodes leading zeroes" do
    zero_string = "0"
    zeroes_string = "01"
    two_zeroes_string = "001"

    assert Base10.decode10!(zero_string) == <<0>>
    assert Base10.decode10!(zero_string, padding: true) == <<0>>
    assert Base10.decode10!(zero_string, padding: false) == <<0>>

    assert Base10.decode10!(zeroes_string) == <<1>>
    assert Base10.decode10!(zeroes_string, padding: true) == <<0, 1>>
    assert Base10.decode10!(zeroes_string, padding: false) == <<1>>

    assert Base10.decode10!(two_zeroes_string) == <<1>>
    assert Base10.decode10!(two_zeroes_string, padding: true) == <<0, 0, 1>>
    assert Base10.decode10!(two_zeroes_string, padding: false) == <<1>>
  end

  test "decode/2 decodes leading zeroes" do
    zero_string = "0"
    zeroes_string = "01"
    two_zeroes_string = "001"

    assert Base10.decode10(zero_string) == {:ok, <<0>>}
    assert Base10.decode10(zero_string, padding: true) == {:ok, <<0>>}
    assert Base10.decode10(zero_string, padding: false) == {:ok, <<0>>}

    assert Base10.decode10(zeroes_string) == {:ok, <<1>>}
    assert Base10.decode10(zeroes_string, padding: true) == {:ok, <<0, 1>>}
    assert Base10.decode10(zeroes_string, padding: false) == {:ok, <<1>>}

    assert Base10.decode10(two_zeroes_string) == {:ok, <<1>>}
    assert Base10.decode10(two_zeroes_string, padding: true) == {:ok, <<0, 0, 1>>}
    assert Base10.decode10(two_zeroes_string, padding: false) == {:ok, <<1>>}
  end

  test "decode!/2 raises errors on invalid Base-10 strings" do
    # non-alpha character trailing
    assert_raise ArgumentError, fn -> Base10.decode10!("0~") end
    # non-alpha character leading
    assert_raise ArgumentError, fn -> Base10.decode10!("~0") end
    # non-alpha character middle
    assert_raise ArgumentError, fn -> Base10.decode10!("0~1") end

    # non-alpha character trailing
    assert_raise ArgumentError, fn -> Base10.decode10!("0~", padding: true) end
    # non-alpha character leading
    assert_raise ArgumentError, fn -> Base10.decode10!("~0", padding: true) end
    # non-alpha character middle
    assert_raise ArgumentError, fn -> Base10.decode10!("0~1", padding: true) end

    # non-alpha character trailing
    assert_raise ArgumentError, fn -> Base10.decode10!("0~", padding: false) end
    # non-alpha character leading
    assert_raise ArgumentError, fn -> Base10.decode10!("~0", padding: false) end
    # non-alpha character middle
    assert_raise ArgumentError, fn -> Base10.decode10!("0~1", padding: false) end

    for non_alpha <- Enum.concat([?A..?Z, ?a..?z]) do
      assert_raise ArgumentError, fn -> <<non_alpha::utf8>> |> Base10.decode10!() end
    end
  end

  test "decode/2 returns an error on invalid Base-10 strings" do
    # non-alpha character trailing
    assert Base10.decode10("0~") == :error
    # non-alpha character leading
    assert Base10.decode10("A~") == :error
    # non-alpha character middle
    assert Base10.decode10("0~0") == :error

    # non-alpha character trailing
    assert Base10.decode10("0~", padding: true) == :error
    # non-alpha character leading
    assert Base10.decode10("A~", padding: true) == :error
    # non-alpha character middle
    assert Base10.decode10("0~0", padding: true) == :error

    # non-alpha character trailing
    assert Base10.decode10("0~", padding: false) == :error
    # non-alpha character leading
    assert Base10.decode10("~0", padding: false) == :error
    # non-alpha character middle
    assert Base10.decode10("0~0", padding: false) == :error

    for non_alpha <- Enum.concat([?A..?Z, ?a..?z]) do
      assert <<non_alpha::utf8>> |> Base10.decode10() == :error
    end
  end

end
