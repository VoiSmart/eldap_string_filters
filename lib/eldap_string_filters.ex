defmodule EldapStringFilters do
  @moduledoc """
  `EldapStringFilters` main module.
  """
  alias __MODULE__.RFC4515

  @doc """
  Parses an LDAP search filter string as defined in RFC4515 and returns
  a filter in `:eldap` format suitable to be used in `:eldap.search/2`.

  Return `{:ok, :eldap.filter()}` or `{:error, any()}` when parsing fails.
  """
  @spec parse(String.t()) :: {:ok, :eldap.filter()} | {:error, any()}
  def parse(filter) when is_binary(filter) do
    case RFC4515.parse(filter) do
      {:ok, parsed, "", _, _, _} -> {:ok, Enum.at(parsed, 0)}
      {:ok, _parsed, rest, _, _, _} -> {:error, {:incomplete, rest}}
      {:error, a, b, c, d, e} -> {:error, {:parse_error, a, b, c, d, e}}
    end
  end
end
