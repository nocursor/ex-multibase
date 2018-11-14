defmodule MultibaseTest do
  use ExUnit.Case, async: true
  doctest Multibase

  #slow_encodings = MapSet.new([:base1, :base2])
  #@non_pathological_encodings Enum.reject(Multibase.encodings(), fn(encoding_id) -> MapSet.member?(slow_encodings, encoding_id) end)
  @non_pathological_encodings Multibase.encodings()

  test "encodes binaries for all encodings" do
    hello_world = "hello world"
    zero_hello_world = <<0, hello_world::binary>>
    hello_world_zero = <<hello_world::binary, 0>>
    data_bin = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
    bigger_bin = "Have you seen a six fingered man?"

    bins = [hello_world, zero_hello_world, hello_world_zero, data_bin, bigger_bin]

    for encoding_id <- @non_pathological_encodings do
      for bin <- bins do
        {:ok, string} = Multibase.encode(bin, encoding_id)
        assert is_binary(string) == true
        assert Multibase.encode!(bin, encoding_id) |> is_binary() == true
      end
    end
  end

  test "decodes binaries for all encodings" do
    hello_world = "hello world"
    zero_hello_world = <<0, hello_world::binary>>
    hello_world_zero = <<hello_world::binary, 0>>
    data_bin = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
    bigger_bin = "Have you seen a six fingered man?"

    bins = [hello_world, zero_hello_world, hello_world_zero, data_bin, bigger_bin]

    for encoding_id <- @non_pathological_encodings do
      for bin <- bins do
        {:ok, string} = Multibase.encode(bin, encoding_id)
        {:ok, data} = Multibase.decode(string)
        assert is_binary(data) == true
        assert Multibase.decode!(string)  == data
      end
    end
  end

  test "codec decodes binaries for all encodings" do
    hello_world = "hello world"
    zero_hello_world = <<0, hello_world::binary>>
    hello_world_zero = <<hello_world::binary, 0>>
    data_bin = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
    bigger_bin = "Have you seen a six fingered man?"

    bins = [hello_world, zero_hello_world, hello_world_zero, data_bin, bigger_bin]

    for encoding_id <- @non_pathological_encodings do
      for bin <- bins do
        {:ok, string} = Multibase.encode(bin, encoding_id)
        {:ok, {data, ^encoding_id}} = Multibase.codec_decode(string)
        assert is_binary(data) == true
        assert Multibase.codec_decode!(string) == {data, encoding_id}
      end
    end
  end

  test "multibase/2 encodes pre-encoded data as multibase" do
    data = "blunderbus"
    encoding_prefix = Multibase.prefix!(:base16_lower)
    prefix_size = byte_size(encoding_prefix)
    <<prefix::binary-size(prefix_size), _rest::binary>> = Base.encode16(data, case: :lower) |> Multibase.multibase!(:base16_lower)
    assert prefix == encoding_prefix
  end


  test "multibase/2 encodes pre-encoded data as multibase for all encodings" do
    data = <<>>
    for encoding_id <- Multibase.encodings() do
      encoding_prefix = Multibase.prefix!(encoding_id)
      prefix_size = byte_size(encoding_prefix)
      <<prefix::binary-size(prefix_size), _rest::binary>> = data |> Multibase.multibase!(encoding_id)
      assert prefix == encoding_prefix
    end
  end

  test "encodings/0 return all encodings" do
    valid_encodings = [:identity, :base1, :base2, :base8, :base10, :base16_upper, :base16_lower,
      :base32_hex_upper, :base32_hex_lower, :base32_hex_pad_upper,
      :base32_hex_pad_lower, :base32_upper, :base32_lower, :base32_pad_upper,
      :base32_pad_lower, :base32_z, :base58_flickr, :base58_btc, :base64,
      :base64_pad, :base64_url, :base64_url_pad]

    encodings = Multibase.encodings()
    assert Enum.count(encodings) == 22
    assert valid_encodings -- encodings == []
  end

  test "prefix/1 returns a valid prefix for all encodings" do
    for encoding_id <- Multibase.encodings() do
      {:ok, prefix} = Multibase.prefix(encoding_id)
      assert is_binary(prefix) == true
      assert byte_size(prefix) == 1
      assert Multibase.prefix!(encoding_id) == prefix
    end
  end

  test "encoded?/1 checks if data is multibased encoded for all encodings" do
    data = "banana fish bones"
    for encoding_id <- Multibase.encodings() do
      assert Multibase.encode!(data, encoding_id) |> Multibase.encoded?() == true
    end

    assert Multibase.encoded?("*&^#%^$@#%!$#") == false
  end

  test "codec/1 returns the encoding id used to encode the data" do
    bin = "Hello Cleveland"
    for encoding_id <- Multibase.encodings() do
      {:ok, string} = Multibase.encode(bin, encoding_id)
      assert Multibase.codec!(string) == encoding_id
      assert Multibase.codec(string) == {:ok, encoding_id}
    end
  end

  test "encoding_families/0 return all encoding families" do
     families = [:base1, :base10, :base16, :base2, :base32, :base58, :base64, :base8, :identity]
     assert Multibase.encoding_families() -- families == []
  end

  test "encodings_for/1 returns the encoding ids for a given encoding family" do
    # feeling lazy today
    for encoding_family <- Multibase.encoding_families() do
      assert [_ | _] = Multibase.encodings_for!(encoding_family)
    end

    assert Multibase.encodings_for(:identity) ==
             {:ok, [:identity]}
    assert Multibase.encodings_for(:base1) ==
             {:ok, [:base1]}
    assert Multibase.encodings_for(:base2) ==
             {:ok, [:base2]}

    assert Multibase.encodings_for(:base8) ==
             {:ok, [:base8]}

    Multibase.encodings_for(:base10)
    {:ok, [:base10]}

    assert Multibase.encodings_for(:base16) == {:ok, [:base16_upper, :base16_lower, :base32_hex_upper, :base32_hex_lower]}
    assert Multibase.encodings_for(:base32) == {
             :ok,
             [
               :base32_hex_pad_upper,
               :base32_hex_pad_lower,
               :base32_upper,
               :base32_lower,
               :base32_pad_upper,
               :base32_pad_lower,
               :base32_z
             ]
           }

    assert Multibase.encodings_for(:base58) ==
             {:ok, [:base58_flickr, :base58_btc]}

    assert Multibase.encodings_for(:base16) ==
             {:ok, [:base16_upper, :base16_lower, :base32_hex_upper, :base32_hex_lower]}
  end

end
