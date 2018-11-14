defmodule Multibase do
  @moduledoc """
  This module provides encoding, decoding, and convenience functions for working with [Multibase](https://github.com/multiformats/multibase).

  Multibase is a protocol for distinguishing base encodings and other simple string encodings, and for ensuring full compatibility with program interfaces. It answers the question:

    ```
    Given data d encoded into string s, how can I tell what base d is encoded with?
    ```

  Base encodings exist because transports have restrictions, use special in-band sequences, or must be human-friendly. When systems chose a base to use, it is not always clear which base to use, as there are many tradeoffs in the decision. Multibase is here to save programs and programmers from worrying about which encoding is best. It solves the biggest problem: a program can use multibase to take input or produce output in whichever base is desired. The important part is that the value is self-describing, letting other programs elsewhere know what encoding it is using.

  ## Use-Cases

  The following are some typical use-cases for Multibase:

  * Abstracting encoding and decoding
  * Tagging encoded data with the encoding type
  * IPFS
  * Processing multiple types of data in the same API, stream, code etc. where the encoding can vary or is not always known
  * Avoiding heuristics and other inaccurate methods of determining an encoding type
  * Streamlining an encoding interfaces
    * Simplifying patterns where there can be many options such as padding and case

  ## Format

  The Format is:

  ```
  <varint-base-encoding-code><base-encoded-data>
  ```

  Where `<varint-base-encoding-code>` is used according to the multibase table. Note that varints (bases above 127) are not yet supported, but planned.

  ## Multibase By Example

  Consider the following encodings of the same binary string:

  ```
  4D756C74696261736520697320617765736F6D6521205C6F2F # base16 (hex)
  JV2WY5DJMJQXGZJANFZSAYLXMVZW63LFEEQFY3ZP           # base32
  YAjKoNbau5KiqmHPmSxYCvn66dA1vLmwbt                 # base58
  TXVsdGliYXNlIGlzIGF3ZXNvbWUhIFxvLw==               # base64
  ```

  And consider the same encodings with their multibase prefix

  ```
  F4D756C74696261736520697320617765736F6D6521205C6F2F # base16 F
  BJV2WY5DJMJQXGZJANFZSAYLXMVZW63LFEEQFY3ZP           # base32 B
  zYAjKoNbau5KiqmHPmSxYCvn66dA1vLmwbt                 # base58 z
  MTXVsdGliYXNlIGlzIGF3ZXNvbWUhIFxvLw==               # base64 M
  ```

  The base prefixes used are: `F, B, z, M`.

  ## Encodings

  The following table lists the currently supported Multibase encodings. Each encoding has an accompanying prefix code. An upper-case code signifies upper-encoding/decoding, and a lower-case code signifies a lower-case encoding/decoding.

  | encoding     |      code |  name                                                     | encoding ids                                   |
  |--------------|-----------|-----------------------------------------------------------|------------------------------------------------|
  | identity     |       0x00|  8-bit binary (encoder and decoder keeps data unmodified) |`:identity`                                     |
  | base1        |          1|     unary tends to be 11111                               |`:base1`                                        |
  | base2        |          0|     binary has 1 and 0                                    |`:base2`                                        |
  | base8        |          7|     highest char in octal                                 |`:base8`                                        |
  | base10       |          9|     highest char in decimal                               |`:base10`                                       |
  | base16       |        F,f|    highest char in hex                                    |`:base16_upper`, `:base16_lower`                |
  | base32hex    |        V,v|    rfc4648 no padding - highest char                      |`:base32_hex_upper`, `:base32_hex_lower`        |
  | base32hexpad |        T,t|    rfc4648 with padding                                   |`:base32_hex_pad_upper`, `:base32_hex_pad_lower`|
  | base32       |        B,b|    rfc4648 no padding                                     |`:base32_upper`, `:base32_lower`                |
  | base32pad    |        C,c|    rfc4648 with padding                                   |`:base32_pad_upper`, `:base32_pad_lower`        |
  | base32z      |          h|     z-base-32 - used by Tahoe-LAFS - highest letter       |`:base32_z`                                     |
  | base58flickr |          Z|     highest letter                                        |`:base58_flickr`                                |
  | base58btc    |          z|     highest letter                                        |`:base58_btc`                                   |
  | base64       |          m|     rfc4648 no padding                                    |`:base64`                                       |
  | base64pad    |          M|     rfc4648 with padding - MIME encoding                  |`:base64_pad`                                   |
  | base64url    |          u|     rfc4648 no padding                                    |`:base64_url`                                   |
  | base64urlpad |          U|     rfc4648 with padding                                  |`:base64_url_pad`                               |

  All encodings above are fully supported at present.

  ## Resources

  * [Multibase](https://github.com/multiformats/multibase)
  * [Elixir Base Module](https://hexdocs.pm/elixir/Base.html)
  * [Base1](https://github.com/nocursor/base1)
  * [Base2](https://github.com/nocursor/base2)
  * [B58](https://github.com/nocursor/b58)
  * [ZBase32](https://github.com/nocursor/zbase32)

  """

  require Base2
  require ZBase32

  @typedoc """
  A family of encoding_id values that are related but differ by options or alphabet typically.
  """
  @type encoding_family_id :: :identity | :base1 | :base2 | :base8 | :base10 | :base16 | :base32 | :base58 | :base64

  @typedoc """
  A binary encoded and prefixed according to Multibase.
  """
  @type multibase_binary() :: binary

  @typedoc """
  An encoding supported by Multibase.
  """
  @type encoding_id :: :identity | :base1 | :base2 | :base8 | :base10 | :base16_upper | :base16_lower
  | :base32_hex_upper | :base32_hex_lower | :base32_hex_pad_upper | :base32_hex_pad_lower
  | :base32_upper | :base32_lower | :base32_pad_upper | :base32_pad_lower | :base32z
  | :base58_flickr | :base58_btc | :base64 | :base64_pad | :base64_url | :base64_url_pad

  @typedoc """
  A Multibase prefix added to encoded binaries.
  """
  @type prefix :: <<_::8>>

  # READ!
  #=============================================================================
  # Here we define our macro data for all bases and write functions in the style of apply.
  # There may be a more elegant way, but this leaves open the possibility of this module also offering some declarative data for anyone who wants to build their own shim easily.
  # ex: apply(Base, :encode16, ["abc", [case: :upper]]) == Base.encode16("abc", :upper)
  #
  # A second approach is to simply store the function, for example encode_fn: &Base.encode16/2 alongside its args.
  # For now, we lean towards MFA simply because it makes sense for building an AST and for if we decide to do further ports to other langs in a similar style
  #
  # The other reason for this form is to be explicit. We could just call encode/decode!/decode or build our own module adapters.
  # The former is implicit magic and I prefer to be explicit.
  # The latter is an implementation burden we don't need and another level of indirection per-call we don't want.
  # An added benefit is we can possible mix and match modules or break the convention if needed.
  # Protocols are another option, but again I'd like to keep the implementation burden minimal.
  #
  # Finally, there's some obvious repetition. We could try to be clever and mix/relate the data some, but there are better things to do in life probably.
  #
  # Long-term, even this form should probably be revisited as this is just v 0.0.0.0.0.0.1 BETA TM.

  # TODO: Consider if we want to have decoding_mfa_safe or not.
  # ex: %{encoding_id: :base8, prefix: "7",
  #      encoding_mfa: [Base8, :encode8, [[padding: false]]],
  #      decoding_mfa: [Base8, :decode8!, [[padding: false]]],
  #      decoding_mfa_safe: [Base8, :decode8, [[padding: false]]],
  #    },
  # decode_mfa_safe could be separate for now because we don't want to assume too much about the modules we're calling other than potential shape of return args.
  # also we want any additional error info if it's actually there, though most just return `:error` which is already maybe not the best idea in the source modules
  # on the flip side, just returning :error is nice since we have a universal way to encode/decode
  # It would be possible to just use "rescue" on all these, but since these modules are from various sources we shouldn't assume too much perhaps
  # This is less of an issue now, but in the future as more encodings are added, it could get nasty if we just always assume rescue + value

  #TODO: struct for metadata to force required fields? waiting until form is settled more before taking this path

  # this our overly verbose, but explicit codec "database"
  codec_meta = [
    %{encoding_id: :identity, prefix: <<0x00>>, encoding_family_id: :identity,
      encoding_mfa: [BaseIdentity, :encode, []],
      decoding_mfa: [BaseIdentity, :decode!, []],
    },
    %{encoding_id: :base1, prefix: "1", encoding_family_id: :base1,
      encoding_mfa: [Base1, :encode_length_bin, []],
      decoding_mfa: [Base1, :decode_length_bin!, []],
    },
    %{encoding_id: :base2, prefix: "0", encoding_family_id: :base2,
      encoding_mfa: [Base2, :encode2, [[padding: :none]]],
      decoding_mfa: [Base2, :decode2!, []],
    },
    %{encoding_id: :base8, prefix: "7", encoding_family_id: :base8,
      encoding_mfa: [Base8, :encode8, [[padding: false]]],
      decoding_mfa: [Base8, :decode8!, [[padding: false]]],
    },
    %{encoding_id: :base10, prefix: "9", encoding_family_id: :base10,
      encoding_mfa: [Base10, :encode10, [[padding: false]]],
      decoding_mfa: [Base10, :decode10!, [[padding: false]]],
    },
    %{encoding_id: :base16_upper, prefix: "F", encoding_family_id: :base16,
      encoding_mfa: [Base, :encode16, [[case: :upper]]],
      decoding_mfa: [Base, :decode16!, [[case: :upper]]],
    },
    %{encoding_id: :base16_lower, prefix: "f", encoding_family_id: :base16,
      encoding_mfa: [Base, :encode16, [[case: :lower]]],
      decoding_mfa: [Base, :decode16!, [[case: :lower]]],
    },
    %{encoding_id: :base32_hex_upper, prefix: "V", encoding_family_id: :base16,
      encoding_mfa: [Base, :hex_encode32, [[case: :upper, padding: false]]],
      decoding_mfa: [Base, :hex_decode32!, [[case: :upper, padding: false]]],
    },
    %{encoding_id: :base32_hex_lower, prefix: "v", encoding_family_id: :base16,
      encoding_mfa: [Base, :hex_encode32, [[case: :lower, padding: false]]],
      decoding_mfa: [Base, :hex_decode32!, [[case: :lower, padding: false]]],
    },
    %{encoding_id: :base32_hex_pad_upper, prefix: "T", encoding_family_id: :base32,
      encoding_mfa: [Base, :hex_encode32, [[case: :upper, padding: true]]],
      decoding_mfa: [Base, :hex_decode32!, [[case: :upper, padding: true]]],
    },
    %{encoding_id: :base32_hex_pad_lower, prefix: "t", encoding_family_id: :base32,
      encoding_mfa: [Base, :hex_encode32, [[case: :lower, padding: true]]],
      decoding_mfa: [Base, :hex_decode32!, [[case: :lower, padding: true]]],
    },
    %{encoding_id: :base32_upper, prefix: "B", encoding_family_id: :base32,
      encoding_mfa: [Base, :encode32, [[case: :upper, padding: false]]],
      decoding_mfa: [Base, :decode32!, [[case: :upper, padding: false]]],
    },
    %{encoding_id: :base32_lower, prefix: "b", encoding_family_id: :base32,
      encoding_mfa: [Base, :encode32, [[case: :lower, padding: false]]],
      decoding_mfa: [Base, :decode32!, [[case: :lower, padding: false]]],
    },
    %{encoding_id: :base32_pad_upper, prefix: "C", encoding_family_id: :base32,
      encoding_mfa: [Base, :encode32, [[case: :upper, padding: true]]],
      decoding_mfa: [Base, :decode32!, [[case: :upper, padding: true]]]
    },
    %{encoding_id: :base32_pad_lower, prefix: "c", encoding_family_id: :base32,
      encoding_mfa: [Base, :encode32, [[case: :lower, padding: true]]],
      decoding_mfa: [Base, :decode32!, [[case: :lower, padding: true]]],
    },
    %{encoding_id: :base32_z, prefix: "h", encoding_family_id: :base32,
      encoding_mfa: [ZBase32, :encode, []],
      #TODO: check on pull request
      decoding_mfa: [ZBase32, :decode, []],
    },
    %{encoding_id: :base58_flickr, prefix: "Z", encoding_family_id: :base58,
      encoding_mfa: [B58, :encode58, [[alphabet: :flickr]]],
      decoding_mfa: [B58, :decode58!, [[alphabet: :flickr]]],
    },
    %{encoding_id: :base58_btc, prefix: "z", encoding_family_id: :base58,
      encoding_mfa: [B58, :encode58, [[alphabet: :btc]]],
      decoding_mfa: [B58, :decode58!, [[alphabet: :btc]]],
    },
    %{encoding_id: :base64, prefix: "m", encoding_family_id: :base64,
      encoding_mfa: [Base, :encode64, [[padding: false]]],
      decoding_mfa: [Base, :decode64!, [[padding: false]]],
    },
    %{encoding_id: :base64_pad, prefix: "M", encoding_family_id: :base64,
      encoding_mfa: [Base, :encode64, [[padding: true]]],
      decoding_mfa: [Base, :decode64!, [[padding: true]]],
    },
    %{encoding_id: :base64_url, prefix: "u", encoding_family_id: :base64,
      encoding_mfa: [Base, :url_encode64, [[padding: false]]],
      decoding_mfa: [Base, :url_decode64!, [[padding: false]]],
    },
    %{encoding_id: :base64_url_pad, prefix: "U", encoding_family_id: :base64,
      encoding_mfa: [Base, :url_encode64, [[padding: true]]],
      decoding_mfa: [Base, :url_decode64!, [[padding: true]]],
    },
  ]

  @doc """
  Encodes a binary using Multibase in the given encoding as specified by `encoding_id`.

  Returns an {:error, :unsupported_encoding} if the given encoding id is not implemented or supported.

  ## Examples

      iex> Multibase.encode("hello world", :base32_lower)
      {:ok, "bnbswy3dpeb3w64tmmq"}

      iex> Multibase.encode("hello world", :base32_pad_lower)
      {:ok, "cnbswy3dpeb3w64tmmq======"}

      iex>  Multibase.encode(<<0, "love's got the world in motion">>, :base58_btc)
      {:ok, "z1NjCQeEgij5WQXS5UXtL8yiTLPkGRYohc5MopavNUd"}

      iex> Multibase.encode("hello world", :nonsense_codec)
      {:error, :unsupported_encoding}

  """
  @spec encode(binary(), encoding_id()) :: {:ok, binary()} | {:error, :unsupported_encoding}
  def encode(data, encoding_id) when is_binary(data) do
    case do_encode(data, encoding_id) do
      encoded_data when is_binary(encoded_data) ->
        {:ok, encoded_data}
      :unsupported_encoding ->
        {:error, :unsupported_encoding}
    end
  end

  @doc """
  Encodes a binary using Multibase in the given encoding as specified by `encoding_id`

  Raises an ArgumentError if the encoding type is not supported.

  ## Examples

      iex> Multibase.encode!("hello world", :base32_lower)
      "bnbswy3dpeb3w64tmmq"

      iex> Multibase.encode!("hello world", :base32_pad_lower)
      "cnbswy3dpeb3w64tmmq======"

      iex>  Multibase.encode!(<<0, "love's got the world in motion">>, :base58_btc)
      "z1NjCQeEgij5WQXS5UXtL8yiTLPkGRYohc5MopavNUd"

  """
  @spec encode!(binary(), encoding_id()) :: binary()
  def encode!(data, encoding_id) when is_binary(data) do
    case do_encode(data, encoding_id) do
      encoded_data when is_binary(encoded_data) ->
        encoded_data
      :unsupported_encoding ->
        raise ArgumentError, "Unsupported encoding - no encodings for encoding id: #{inspect encoding_id}"
    end
  end

  @doc """
  Decodes a Multibase-encoded binary.

  Raises an ArgumentError if the input is not a valid Multibase binary.

  ## Examples

      iex> Multibase.decode!("z42vFWDGstskJy3N74kMHfTKEA")
      "I distribute files"

      iex> Multibase.decode!("Z42VfvdgSTSKiY3n74KmhEsjea")
      "I distribute files"

      iex> Multibase.decode!("MZGlzb3JnYW5pemVkIGRlc2sgZGF5")
      "disorganized desk day"

      iex> Multibase.decode!("731064563336711473026715136462544100621453466544031060571")
      "disorganized desk day"

  """
  @spec decode!(binary()) :: binary()
  def decode!(string) when is_binary(string) do
    do_decode!(string)
  end

  def decode!(_string) do
    raise ArgumentError, "string must be a binary that has been encoded using Multibase."
  end

  @doc """
  Decodes a Multibase-encoded binary.

  Returns an error if the input is not a valid Multibase binary.

  ## Examples

      iex> Multibase.decode("BNFZSA5DINFZSA5DINFXGOIDPNY")
      {:ok, "is this thing on"}

      iex> Multibase.decode("bnfzsa5dinfzsa5dinfxgoidpny")
      {:ok, "is this thing on"}

      iex> Multibase.decode("-nfzsa5dinfzsa5dinfxgoidpny")
      :error

  """
  @spec decode(binary()) :: {:ok, binary()} | {:error, term()}
  def decode(string) when is_binary(string) do
    # Here we take the "yuck" approach. We can define an extra decode_mfa_safe entry for each encoding and just call that direct instead if we like.
    {:ok, decode!(string)}
    rescue
      ArgumentError -> :error
  end

  @doc """
  Decodes a Multibase-encoded binary, returning the encoding_id used to encode the Multibase binary.

  Raises an ArgumentError if the input is not a valid Multibase binary.

  ## Examples

      iex> Multibase.codec_decode!("hqpts13mqcp11n")
      {"science!", :base32_z}

      iex> Multibase.codec_decode!("VEDHMIPBECDII2")
      {"science!", :base32_hex_upper}

      iex> Multibase.codec_decode!("vedhmipbecdii2")
      {"science!", :base32_hex_lower}

  """
  @spec codec_decode!(binary()) :: {binary(), encoding_id()}
  def codec_decode!(data) when is_binary(data) do
    do_codec_decode!(data)
  end

  @doc """
  Decodes a Multibase-encoded binary, returning the encoding_id used to encode the Multibase binary.

  Raises an ArgumentError if the input is not a valid Multibase binary.

  ## Examples

      iex> Multibase.codec_decode("UZnVuZCBpdA==")
      {:ok, {"fund it", :base64_url_pad}}

      iex> Multibase.codec_decode("uZnVuZCBpdA")
      {:ok, {"fund it", :base64_url}}

      iex> Multibase.codec_decode("-ZnVuZCBpdA")
      :error

  """
  @spec codec_decode(binary()) :: {:ok, {binary(), encoding_id()}} | {:error, term()}
  def codec_decode(data) when is_binary(data) do
    {:ok, codec_decode!(data)}
  rescue
    ArgumentError -> :error
  end

  @doc """
  Prefixes an encoded binary with the appropriate multibase prefix for the given encoding as specified by `encoding_id`.

  An error is returned if the `encoding_id` is not supported.

  ## Examples

      iex> Base.encode32("absent forever", case: :lower) |> Multibase.multibase(:base32_lower)
      {:ok, "bmfrhgzlooqqgm33smv3gk4q="}

      iex> Base.encode32("absent forever", case: :upper) |> Multibase.multibase(:base32_upper)
      {:ok, "BMFRHGZLOOQQGM33SMV3GK4Q="}

      iex> Base.encode32("absent forever", case: :upper) |> Multibase.multibase(:base32_deepfried)
      {:error, :unsupported_encoding}

  """
  @spec multibase(binary(), encoding_id()) :: {:ok, multibase_binary()} | {:error, :unsupported_encoding}
  def multibase(data, encoding_id) do
    case prefix(encoding_id) do
      {:ok, prefix} ->
        {:ok, <<prefix::binary, data::binary>>}
      {:error, _reason} = err ->
        err
    end
  end

  @doc """
  Prefixes an encoded binary with the appropriate multibase prefix for the given encoding as specified by `encoding_id`.

  An ArgumentError is raised if the `encoding_id` is not supported.

  ## Examples

      iex> Base.encode64("high attendance party", padding: false) |> Multibase.multibase!(:base64)
      "maGlnaCBhdHRlbmRhbmNlIHBhcnR5"

      iex> Base.encode64("high attendance party", padding: true) |> Multibase.multibase!(:base64_pad)
      "MaGlnaCBhdHRlbmRhbmNlIHBhcnR5"

      iex> Base.encode16("high attendance party", case: :lower) |> Multibase.multibase!(:base16_lower)
      "f6869676820617474656e64616e6365207061727479"

  """
  @spec multibase!(binary(), encoding_id()) :: {:ok, multibase_binary()} | {:error, :unsupported_encoding}
  def multibase!(data, encoding_id) do
    case multibase(data, encoding_id) do
      {:ok, encoded_data} -> encoded_data
      {:error, :unsupported_encoding} -> "Unsupported encoding - no encodings for encoding id: #{inspect encoding_id}"
    end
  end

  @doc """
  Returns the `encoding_id` used to encode a Multibase encoded binary.

  Returns an error if the encoding is not supported or the binary is not a valid multibase encoded binary.

  ## Examples

      iex> Multibase.codec!("731672555304674403446254332270145")
      :base8

      iex> Multibase.codec!("UZ3VtYm8gcmVjaXBl")
      :base64_url_pad

      iex> Multibase.encode!("gumbo recipe", :base58_btc) |> Multibase.codec!()
      :base58_btc

  """
  @spec codec(binary()) :: {:ok, encoding_id()} | {:error, :missing_encoding | :unsupported_encoding}
  def codec(data) when is_binary(data) do
    do_codec(data)
  end

  @doc """
  Returns the `encoding_id` used to encode a Multibase encoded binary.

  Returns an error if the encoding is not supported or the binary is not a valid multibase encoded binary.

  ## Examples

      iex> Multibase.codec!("731672555304674403446254332270145")
      :base8

      iex> Multibase.codec!("UZ3VtYm8gcmVjaXBl")
      :base64_url_pad

      iex> Multibase.encode!("gumbo recipe", :base58_btc) |> Multibase.codec!()
      :base58_btc

  """
  @spec codec!(binary()) :: {:ok, encoding_id()} | {:error, :missing_encoding | :unsupported_encoding}
  def codec!(data) when is_binary(data) do
    case codec(data) do
      {:ok, data} -> data
      _ -> raise ArgumentError, "Invalid data. No multibase encoding information found."
    end
  end

  @doc """
  Returns true if a binary is probably Multibase encoded.

  Note that this check only scans for a valid prefix. A non-encoded binary may have a valid Multibase prefix.

  ## Examples

      iex> Multibase.encoded?("f7468652063757265")
      true

      iex> Multibase.encoded?("~f7468652063757265")
      false

      iex> Multibase.encoded?(<<>>)
      false

  """
  @spec encoded?(binary()) :: boolean()
  def encoded?(data) when is_binary(data) do
    case codec(data) do
      {:ok, _} -> true
      _ -> false
    end
  end

  @doc """
  Returns all the encodings that are available for use with Multibase.

  ## Examples

      iex> Multibase.encodings()
      [:identity, :base1, :base2, :base8, :base10, :base16_upper, :base16_lower,
      :base32_hex_upper, :base32_hex_lower, :base32_hex_pad_upper,
      :base32_hex_pad_lower, :base32_upper, :base32_lower, :base32_pad_upper,
      :base32_pad_lower, :base32_z, :base58_flickr, :base58_btc, :base64,
      :base64_pad, :base64_url, :base64_url_pad]

  """
  @spec encodings() :: [encoding_id()]
  defmacro encodings() do
    unquote(Enum.map(codec_meta, fn(%{encoding_id: encoding_id}) -> encoding_id end))
  end

  @doc """
  Returns all encoding families that are available for use with Multibase.

  ## Examples

      iex> Multibase.encoding_families()
      [:base1, :base10, :base16, :base2, :base32, :base58, :base64, :base8, :identity]

  """
  @spec encoding_families() :: [encoding_family_id()]
  defmacro encoding_families() do
    unquote(Enum.into(codec_meta, MapSet.new(), fn(%{encoding_family_id: family}) -> family end) |> Enum.to_list())
  end

  @doc """
  Returns all the encodings that are available for use with the given `encoding_family_id`.

  Useful you auditing the state of Multibase, debugging, or encoding by group.

  Returns an error if the given `encoding_family_id` is not supported.

  ## Examples

      iex> Multibase.encodings_for(:base32)
      {:ok,
      [:base32_hex_pad_upper, :base32_hex_pad_lower, :base32_upper, :base32_lower,
      :base32_pad_upper, :base32_pad_lower, :base32_z]}

      iex> Multibase.encodings_for(:base64)
      {:ok, [:base64, :base64_pad, :base64_url, :base64_url_pad]}

      iex> Multibase.encodings_for(:base58)
      {:ok, [:base58_flickr, :base58_btc]}

  """
  @spec encodings_for(encoding_family_id()) :: {:ok, [encoding_id()]} | {:error, :unsupported_encoding}
  def encodings_for(encoding_family_id) do
    do_encodings(encoding_family_id)
  end

  @doc """
  Returns all the encodings that are available for use with the given `encoding_family_id`.

  Useful you auditing the state of Multibase, debugging, or encoding by group.

  Raises an ArgumentError if the given `encoding_family_id` is not supported.

  ## Examples

      iex> Multibase.encodings_for!(:base16)
      [:base16_upper, :base16_lower, :base32_hex_upper, :base32_hex_lower]

      iex>  Multibase.encodings_for!(:base8)
      [:base8]

      iex> Multibase.encodings_for!(:base1)
      [:base1]

  """
  @spec encodings_for!(encoding_family_id()) :: {:ok, [encoding_id()]} | {:error, :unsupported_encoding}
  def encodings_for!(encoding_family_id) do
    case encodings_for(encoding_family_id) do
      {:ok, encodings} -> encodings
      _ -> raise ArgumentError, "Unsupported encoding - no encodings for encoding family id: #{inspect encoding_family_id}"
    end
  end

  @doc """
  Returns the encoding family for the given `encoding_id`.

  Returns an error if the given `encoding_id` is not supported.

  ## Examples

      iex> Multibase.encoding_family(:base16_lower)
      {:ok, :base16}

      iex> Multibase.encoding_family(:base32_pad_upper)
      {:ok, :base32}

      iex> Multibase.encoding_family(:bbq)
      {:error, :unsupported_encoding}

  """
  @spec encoding_family(encoding_id()) :: {:ok, encoding_family_id()} | {:error, :unsupported_encoding}
  def encoding_family(encoding_id) do
    do_encoding_family(encoding_id)
  end

  @doc """
  Returns the encoding family for the given `encoding_id`.

  Raises an ArgumentError if the given `encoding_id` is not supported.

  ## Examples

      iex> Multibase.encoding_family!(:base64_url_pad)
      :base64

      iex> Multibase.encoding_family!(:base8)
      :base8

      iex>  Multibase.encoding_family!(:base1)
      :base1

  """
  @spec encoding_family!(encoding_id()) :: {:ok, encoding_family_id()} | {:error, :unsupported_encoding}
  def encoding_family!(encoding_id) do
    case encoding_family(encoding_id) do
      {:ok, encoding_family} -> encoding_family
      _ -> raise ArgumentError, "Unsupported encoding - no encodings for encoding id: #{inspect encoding_id}"
    end
  end

  @doc """
  Returns the prefix that is used with a given `encoding_id`

  Returns an error if the given `encoding_id` is not supported.

  ## Examples

      iex>  Multibase.prefix(:base1)
      {:ok, "1"}

      iex> Multibase.prefix(:base32_hex_pad_upper)
      {:ok, "T"}

      iex> Multibase.prefix(:base32_hex_pad_lower)
      {:ok, "t"}

      Multibase.prefix(:quest_for_chips)
      {:error, :unsupported_encoding}

  """
  @spec prefix(encoding_id()) :: {:ok, prefix()} | {:error, :unsupported_encoding}
  def prefix(encoding_id) do
    do_prefix(encoding_id)
  end

  @doc """
  Returns the prefix that is used with a given `encoding_id`

  Raises an ArgumentError if the given `encoding_id` is not supported.

  ## Examples

      iex>  Multibase.prefix!(:base32_hex_lower)
      "v"

      iex> Multibase.prefix!(:base58_flickr)
      "Z"

      iex> Multibase.prefix!(:base58_btc)
      "z"

  """
  @spec prefix!(encoding_id()) :: {:ok, prefix()} | {:error, :unsupported_encoding}
  def prefix!(encoding_id) do
    case prefix(encoding_id) do
      {:ok, prefix} -> prefix
      _ -> raise ArgumentError, "Unsupported encoding - no prefix for encoding id: #{inspect encoding_id}"
    end
  end

#===============================================================================
# Private Lives
#===============================================================================

  #===============================================================================
  # Encoding
  #===============================================================================
  defp do_encode(data, encoding_id)
  for %{encoding_id: encoding_id, prefix: prefix, encoding_mfa: [encoding_mod, encoding_fn, encoding_args]} <- codec_meta do
    defp do_encode(data, unquote(encoding_id)) do
      <<
        (unquote(prefix)),
        unquote(encoding_mod).unquote(encoding_fn)(data, unquote_splicing(encoding_args))::binary
      >>
    end
  end

  defp do_encode(_data, _encoding_id) do
    :unsupported_encoding
  end

  #===============================================================================
  # Decoding
  #===============================================================================

  #TODO: write a macro to deal with payload for both do_codec_decode! and do_decode!

  defp do_decode!(string)
  for %{prefix: prefix, decoding_mfa: [decoding_mod, decoding_fn, decoding_args]} <- codec_meta do
    defp do_decode!(<<unquote(prefix), data::binary>>) do
      case unquote(decoding_mod).unquote(decoding_fn)(data, unquote_splicing(decoding_args)) do
        string when is_binary(string) -> string
        {:ok, string} -> string
        {:error, reason} ->  raise ArgumentError, "Error decoding - #{inspect reason}"
      end
    end
  end

  defp do_decode!(<<encoding_prefix::binary-size(1), _rest::binary>>) do
    raise ArgumentError, "Unsupported encoding or no encoding found matching the prefix: #{inspect encoding_prefix}"
  end

  defp do_decode!(<<>>) do
    raise ArgumentError, "missing encoding."
  end

  # yeah this is a bit redundant with decode!
  # could create a macro around do_decode! and do_codec_decode! or otherwise split up some of the functions so the output order is correct
  # main reasons it is repeated are order and avoiding some extra layers of function calls not really worth doing
  defp do_codec_decode!(string)
  for %{encoding_id: encoding_id, prefix: prefix, decoding_mfa: [decoding_mod, decoding_fn, decoding_args]} <- codec_meta do
    defp do_codec_decode!(<<unquote(prefix), data::binary>>) do
      case unquote(decoding_mod).unquote(decoding_fn)(data, unquote_splicing(decoding_args)) do
        string when is_binary(string) -> {string, unquote(encoding_id)}
        {:ok, string} -> {string, unquote(encoding_id)}
        {:error, reason} ->  raise ArgumentError, "Error decoding #{inspect unquote(encoding_id)} - #{inspect reason}"
      end
    end
  end

  defp do_codec_decode!(<<encoding_prefix::binary-size(1), _rest::binary>>) do
    raise ArgumentError, "Unsupported encoding or no encoding found matching the prefix: #{inspect encoding_prefix}"
  end

  defp do_codec_decode!(<<>>) do
    raise ArgumentError, "missing encoding."
  end

  #===============================================================================
  # Codec matching
  #===============================================================================
  defp do_codec(data)
  for %{encoding_id: encoding_id, prefix: prefix} <- codec_meta do
    defp do_codec(<<unquote(prefix), _data::binary>>) do
      {:ok, unquote(encoding_id)}
    end
  end

  defp do_codec(<<>>) do
    {:error, :missing_encoding}
  end

  defp do_codec(_data) do
    {:error, :unsupported_encoding}
  end

  for {encoding_family_id, encoding_ids} <- Enum.group_by(codec_meta,
    fn(%{encoding_family_id: encoding_family_id}) -> encoding_family_id end,
    fn(%{encoding_id: encoding_id}) -> encoding_id end) do
    defp do_encodings(unquote(encoding_family_id)) do
      {:ok, unquote(encoding_ids)}
    end
  end

  defp do_encodings(_encoding_family_id) do
    {:error, :unsupported_encoding}
  end

  for %{encoding_id: encoding_id, encoding_family_id: encoding_family_id} <- codec_meta do
    defp do_encoding_family(unquote(encoding_id)) do
      {:ok, unquote(encoding_family_id)}
    end
  end

  defp do_encoding_family(_encoding_id) do
    {:error, :unsupported_encoding}
  end

  for %{encoding_id: encoding_id, prefix: prefix} <- codec_meta do
    defp do_prefix(unquote(encoding_id)) do
      {:ok, unquote(prefix)}
    end
  end

  defp do_prefix(_encoding_id) do
    {:error, :unsupported_encoding}
  end

end
