defmodule Base10 do
  @moduledoc false

#
#  """
#  This module provides encoding and decoding for Base-10.
#  """

  #TODO: Replace with a macro

  # uncomment for generating using manual approach
  #alphabet_encoding = Enum.with_index('0123456789')

  @doc """
  Encodes a binary in Base-10.

  ## Options

  The accepted options are:

  :padding - specifies whether or not to pad leading zeroes when encoding to preserve full transparency.

  The values for :padding can be:

    * true - pad leading zeroes
    * false - ignore leading zeroes (default), faster

  ## Examples

      iex> Base10.encode10("hello")
      "448378203247"

      iex> Base10.encode10(<<0, 0, "hello">>, padding: false)
      "448378203247"

      iex> Base8.encode8(<<0, 0, "hello">>, padding: true)
      "006414533066157"

      iex> Base10.encode10(<<0, 0, "hello">>, padding: true)
      "00448378203247"

  """
  @spec encode10(binary(), keyword()) :: binary()
  def encode10(data, opts \\ []) when is_binary(data) do
    pad? = Keyword.get(opts, :padding, false)
    do_encode10(data, pad?)
  end
  @doc """
  Decodes a Base-10 binary.

  An ArgumentError is raised if the string is not a valid Base-10 string.

  ## Options

    The accepted options are:

    :padding - specifies whether or not to pad leading zeroes when decoding to preserve full transparency.

    The values for :padding can be:

      * true - check for padded leading zeroes
      * false - ignore leading zeroes (default), faster

  ## Examples

      iex> Base10.decode10!("448378203247")
      "hello"

      iex> Base10.decode10!("00448378203247", padding: false)
      "hello"

      iex> Base10.decode10!("00448378203247", padding: true)
      <<0, 0, 104, 101, 108, 108, 111>>

  """
  @spec decode10!(binary(), keyword()) :: binary()
  def decode10!(string, opts \\ [])
  def decode10!(string, opts) when is_binary(string) do
    pad? = Keyword.get(opts, :padding, false)
    do_decode10(string, pad?)
  end

  def decode10!(_string, _opts) do
    raise ArgumentError, "string must be a valid base10-encoded string."
  end

  @doc """
  Decodes a Base-10 binary.

  An ArgumentError is raised if the string is not a valid Base-10 string.

  ## Options

    The accepted options are:

    :padding - specifies whether or not to pad leading zeroes when decoding to preserve full transparency.

    The values for :padding can be:

      * true - check for padded leading zeroes
      * false - ignore leading zeroes (default), faster

  ## Examples

      iex> Base10.decode10("448378203247")
      {:ok, "hello"}

      iex> Base10.decode10("00448378203247", padding: false)
      {:ok, "hello"}

      iex> Base10.decode10("00448378203247", padding: true)
      {:ok, <<0, 0, 104, 101, 108, 108, 111>>}

  """
  @spec decode10(binary(), keyword()) :: {:ok, binary()} | :error
  def decode10(string, opts \\ []) do
    {:ok, decode10!(string, opts)}
  rescue
    ArgumentError -> :error
  end

  #===============================================================================
  # Private
  #===============================================================================
  # This is not needed if we got with built-in
#  defp encode_char(value)
#  for {encoding, value} <- alphabet_encoding do
#    defp encode_char(unquote(value)), do: unquote(encoding)
#  end
#
#  defp encode_char(value) do
#    "non-alphabet digit found: #{inspect(<<value>>, binaries: :as_strings)} (byte #{value})"
#  end

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

  defp encode_body(data) do
    # This performs better than div/mod typically with less memory usage
    :binary.decode_unsigned(data) |> Integer.to_string(10)
  end
#
#  defp encode_body(0, acc) do
#    acc
#  end
#
#  defp encode_body(integer, acc) do
#    encode_body(div(integer, 10), [encode_char(rem(integer, 10)) | acc])
#  end

  defp do_encode10(<<>>, _pad?) do
    <<>>
  end

  defp do_encode10(data, false) do
    encode_body(data)
  end

  defp do_encode10(data, true) do
    encoded_prefix = encode_prefix(data, []) |> to_string()
    <<encoded_prefix::binary, encode_body(data)::binary>>
  end
#
#  defp do_encode10(data) do
#    encoded_prefix = encode_prefix(data, [])
#    body = encode_body(data |> :binary.decode_unsigned(), [])
#    [encoded_prefix | body] |> to_string()
#  end

  def do_decode10(<<>>, _pad) do
    <<>>
  end

  def do_decode10("0", _pad) do
    <<0>>
  end

  def do_decode10(string, false) do
    decode_payload(string)
  end

  def do_decode10(string, true) do
    leading_zeroes_count = count_leading_zeroes(string, 0)
    <<0::unsigned-integer-size(leading_zeroes_count)-unit(8), decode_payload(string)::binary>>
  end

  defp decode_payload(string) do
    String.to_integer(string, 10) |> :binary.encode_unsigned()
  end

  defp count_leading_zeroes(<<"0", rest::binary>>, acc) do
    count_leading_zeroes(rest, acc + 1)
  end

  defp count_leading_zeroes(_string, acc) do
    acc
  end

end