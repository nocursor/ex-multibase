defmodule BaseIdentity do
  @moduledoc false

#  """
#  This modules provides a simple wrapper for a consistent interface for handling different Base conversions.
#
#  It performs no conversions and simply leaves data untouched. It exists to simplify code generation and to provide simple sanity checks on input data.
#  """

  ## No guarantee we will keep this, just a stub to simplify code generation. We could use a simple no-op style function instead.

  @doc """
  Encodes a binary using identity encoding.

  ## Examples

      iex> BaseIdentity.encode("hello")
      "hello"

  """
  @spec encode(binary()) :: binary()
  def encode(data) when is_binary(data) do
    data
  end

  @doc """
  Decodes an identity encoded binary.

  An ArgumentError is raised if the input data is not a binary.

  ## Examples

      iex> BaseIdentity.decode!("hello"
      "hello"

  """
  @spec decode!(binary()) :: binary()
  def decode!(string)
  def decode!(string) when is_binary(string) do
    string
  end

  def decode!(_string, _opts) do
    raise ArgumentError, "string must be a valid binary."
  end

  @doc """
  Decodes an identity encoded binary.

  An `:error` is returned if the input data is not a binary.

  ## Examples

      iex> BaseIdentity.decode("hello"
      {:ok, "hello"}

  """
  @spec decode(binary()) :: {:ok, binary()} | :error
  def decode(string) do
    {:ok, decode!(string)}
  rescue
    ArgumentError -> :error
  end

end
