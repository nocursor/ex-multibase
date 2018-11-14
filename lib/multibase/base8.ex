defmodule Base8 do
  @moduledoc false
#  """
#  This module provides encoding and decoding for Base-8.
#  """
  #TODO: Replace with a macro

  alphabet_encoding = Enum.with_index('01234567')

  @doc """
  Encodes a binary in Base-8.

  ## Options

  The accepted options are:

  :padding - specifies whether or not to pad leading zeroes when encoding to preserve full transparency.

  The values for :padding can be:

    * true - pad leading zeroes
    * false - ignore leading zeroes (default), faster

  ## Examples

      iex> Base8.encode8("hello")
      "6414533066157"

      iex> Base8.encode8(<<0, 0, "hello">>, padding: false)
      "6414533066157"

      iex> Base8.encode8(<<0, 0, "hello">>, padding: true)
      "006414533066157"

  """
  @spec encode8(binary(), keyword()) :: binary()
  def encode8(data, opts \\ []) when is_binary(data) do
    pad? = Keyword.get(opts, :padding, false)
    do_encode8(data, pad?)
  end

  @doc """
  Decodes a Base-8 binary.

  An ArgumentError is raised if the string is not a valid Base-8 string.

  ## Options

    The accepted options are:

    :padding - specifies whether or not to pad leading zeroes when decoding to preserve full transparency.

    The values for :padding can be:

      * true - check for padded leading zeroes
      * false - ignore leading zeroes (default), faster

  ## Examples

      iex> Base8.decode8!("6414533066157")
      "hello"

      iex> Base8.decode8!("006414533066157", padding: false)
      "hello"

      iex> Base8.decode8!("006414533066157", padding: true)
      <<0, 0, 104, 101, 108, 108, 111>>

  """
  @spec decode8!(binary(), keyword()) :: binary()
  def decode8!(string, opts \\ [])
  def decode8!(string, opts) when is_binary(string) do
    pad? = Keyword.get(opts, :padding, false)
    do_decode8(string, pad?)
  end

  def decode8!(_string, _opts) do
    raise ArgumentError, "string must be a valid base8-encoded string."
  end

  @doc """
  Decodes a Base-8 binary.

  An error is returned if the string is not a valid Base-8 string.

  ## Options

    The accepted options are:

    :padding - specifies whether or not to pad leading zeroes when decoding to preserve full transparency.

    The values for :padding can be:

      * true - check for padded leading zeroes
      * false - ignore leading zeroes (default), faster

  ## Examples

      iex> Base8.decode8("6414533066157")
      {:ok, "hello"}

      iex> Base8.decode8("006414533066157", padding: false)
      {:ok, "hello"}

      iex> Base8.decode8("006414533066157", padding: true)
      {:ok, <<0, 0, 104, 101, 108, 108, 111>>}

      iex> Base8.decode8("006414533066157ABC", padding: true)
      :error

  """
  @spec decode8(binary(), keyword()) :: {:ok, binary()} | :error
  def decode8(string, opts \\ []) do
    {:ok, decode8!(string, opts)}
    rescue
      ArgumentError -> :error
  end

#===============================================================================
# Private
#===============================================================================
  defp encode_char(value)
  for {encoding, value} <- alphabet_encoding do
    defp encode_char(unquote(value)), do: unquote(encoding)
  end

  # if we want custom char decoding, we can do this
  #  defp decode_char(encoding)
  #  for {encoding, value} <- alphabet_encoding do
  #    defp decode_char(unquote(encoding)), do: unquote(value)
  #  end
  #
  #  defp decode_char(encoding) do
  #    "non-alphabet digit found: #{inspect(<<encoding>>, binaries: :as_strings)} (byte #{encoding})"
  #  end

  defp encode_prefix(<<0, rest::binary>>, acc) do
    encode_prefix(rest, ['0' | acc])
  end

  defp encode_prefix(_bin, acc) do
    acc
  end

  defp do_encode8(<<>>, _pad?) do
    <<>>
  end

  defp do_encode8(data, false) do
    encode_body(data) |> to_string()
  end

  defp do_encode8(data, true) do
    encoded_prefix = encode_prefix(data, [])
    body = encode_body(data)
    [encoded_prefix | body] |> to_string()
  end

  defp encode_body(data) do
    # this performs better than :binary.decode_unsigned(data) |> Integer.to_string(8) typically for base8
    encode_body(data |> :binary.decode_unsigned(), [])
  end

  defp encode_body(0, acc) do
    acc
  end

  defp encode_body(integer, acc) do
    encode_body(div(integer, 8), [encode_char(rem(integer, 8)) | acc])
  end

  def do_decode8(<<>>, _pad) do
    <<>>
  end

  def do_decode8("0", _pad) do
    <<0>>
  end

  def do_decode8(string, false) do
    decode_payload(string)
  end

  def do_decode8(string, true) do
    leading_zeroes_count = count_leading_zeroes(string, 0)
    <<0::unsigned-integer-size(leading_zeroes_count)-unit(8), decode_payload(string)::binary>>
  end

  defp decode_payload(string) do
    String.to_integer(string, 8) |> :binary.encode_unsigned()
  end

  defp count_leading_zeroes(<<"0", rest::binary>>, acc) do
    count_leading_zeroes(rest, acc + 1)
  end

  defp count_leading_zeroes(_string, acc) do
    acc
  end

end