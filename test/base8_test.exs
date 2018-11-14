defmodule Base8Test do
  use ExUnit.Case, async: true
  doctest Base8

  test "encode/2 encodes binaries" do
    bin = "cheese and onions"
    string = "615503126256331220141334620403366715133667163"
    assert Base8.encode8(bin) == string
    assert Base8.encode8(bin, padding: true) == string
    assert Base8.encode8(bin, padding: false) == string

    for c <- 0..255 do
      assert <<c::utf8>> |> Base8.encode8() |> String.valid?()
    end
  end

  test "encode/2 encodes leading zeroes" do
    zeroes_bin = <<0, 1>>
    two_zeroes_bin = <<0, 0, 1>>

    assert Base8.encode8(zeroes_bin) == "1"
    assert Base8.encode8(zeroes_bin, padding: true) == "01"
    assert Base8.encode8(zeroes_bin, padding: false) == "1"

    assert Base8.encode8(two_zeroes_bin) == "1"
    assert Base8.encode8(two_zeroes_bin, padding: true) == "001"
    assert Base8.encode8(two_zeroes_bin, padding: false) == "1"
  end

  test "encode/2 encodes empty strings" do
    assert Base8.encode8(<<>>) == <<>>
    assert Base8.encode8(<<>>, padding: true) == <<>>
    assert Base8.encode8(<<>>, padding: false) == <<>>
  end

  test "decode!/2 decodes binaries" do
    bin = "cheese and onions"
    string = "615503126256331220141334620403366715133667163"
    assert Base8.decode8!(string) == bin
    assert Base8.decode8!(string, padding: true) == bin
    assert Base8.decode8!(string, padding: false) == bin
  end

  test "decode/2 decodes binaries" do
    bin = "cheese and onions"
    string = "615503126256331220141334620403366715133667163"
    assert Base8.decode8(string) == {:ok, bin}
    assert Base8.decode8(string, padding: true) == {:ok, bin}
    assert Base8.decode8(string, padding: false) == {:ok, bin}
  end

  test "decode!/2 decodes empty strings" do
    assert Base8.decode8!(<<>>) == <<>>
    assert Base8.decode8!(<<>>, padding: true) == <<>>
    assert Base8.decode8!(<<>>, padding: false) == <<>>
  end

  test "decode/2 decodes empty strings" do
    assert Base8.decode8(<<>>) == {:ok, <<>>}
    assert Base8.decode8(<<>>, padding: true) == {:ok, <<>>}
    assert Base8.decode8(<<>>, padding: false) == {:ok, <<>>}
  end

  test "decode!/2 decodes leading zeroes" do
    zero_string = "0"
    zeroes_string = "01"
    two_zeroes_string = "001"

    assert Base8.decode8!(zero_string) == <<0>>
    assert Base8.decode8!(zero_string, padding: true) == <<0>>
    assert Base8.decode8!(zero_string, padding: false) == <<0>>

    assert Base8.decode8!(zeroes_string) == <<1>>
    assert Base8.decode8!(zeroes_string, padding: true) == <<0, 1>>
    assert Base8.decode8!(zeroes_string, padding: false) == <<1>>

    assert Base8.decode8!(two_zeroes_string) == <<1>>
    assert Base8.decode8!(two_zeroes_string, padding: true) == <<0, 0, 1>>
    assert Base8.decode8!(two_zeroes_string, padding: false) == <<1>>
  end

  test "decode/2 decodes leading zeroes" do
    zero_string = "0"
    zeroes_string = "01"
    two_zeroes_string = "001"

    assert Base8.decode8(zero_string) == {:ok, <<0>>}
    assert Base8.decode8(zero_string, padding: true) == {:ok, <<0>>}
    assert Base8.decode8(zero_string, padding: false) == {:ok, <<0>>}

    assert Base8.decode8(zeroes_string) == {:ok, <<1>>}
    assert Base8.decode8(zeroes_string, padding: true) == {:ok, <<0, 1>>}
    assert Base8.decode8(zeroes_string, padding: false) == {:ok, <<1>>}

    assert Base8.decode8(two_zeroes_string) == {:ok, <<1>>}
    assert Base8.decode8(two_zeroes_string, padding: true) == {:ok, <<0, 0, 1>>}
    assert Base8.decode8(two_zeroes_string, padding: false) == {:ok, <<1>>}
  end

  test "decode!/2 raises errors on invalid Base-8 strings" do
    # non-alpha character trailing
    assert_raise ArgumentError, fn -> Base8.decode8!("09") end
    # non-alpha character leading
    assert_raise ArgumentError, fn -> Base8.decode8!("90") end
    # non-alpha character middle
    assert_raise ArgumentError, fn -> Base8.decode8!("091") end

    # non-alpha character trailing
    assert_raise ArgumentError, fn -> Base8.decode8!("09", padding: true) end
    # non-alpha character leading
    assert_raise ArgumentError, fn -> Base8.decode8!("90", padding: true) end
    # non-alpha character middle
    assert_raise ArgumentError, fn -> Base8.decode8!("091", padding: true) end

    # non-alpha character trailing
    assert_raise ArgumentError, fn -> Base8.decode8!("09", padding: false) end
    # non-alpha character leading
    assert_raise ArgumentError, fn -> Base8.decode8!("90", padding: false) end
    # non-alpha character middle
    assert_raise ArgumentError, fn -> Base8.decode8!("091", padding: false) end

    for non_alpha <- Enum.concat([?A..?Z, ?a..?z]) do
      assert_raise ArgumentError, fn -> <<non_alpha::utf8>> |> Base8.decode8!() end
    end
  end

  test "decode/2 returns an error on invalid Base-8 strings" do
    # non-alpha character trailing
    assert Base8.decode8("09") == :error
    # non-alpha character leading
    assert Base8.decode8("90") == :error
    # non-alpha character middle
    assert Base8.decode8("090") == :error

    # non-alpha character trailing
    assert Base8.decode8("09", padding: true) == :error
    # non-alpha character leading
    assert Base8.decode8("90", padding: true) == :error
    # non-alpha character middle
    assert Base8.decode8("090", padding: true) == :error

    # non-alpha character trailing
    assert Base8.decode8("09", padding: false) == :error
    # non-alpha character leading
    assert Base8.decode8("90", padding: false) == :error
    # non-alpha character middle
    assert Base8.decode8("090", padding: false) == :error

    for non_alpha <- Enum.concat([?A..?Z, ?a..?z]) do
      assert <<non_alpha::utf8>> |> Base8.decode8() == :error
    end
  end

end
