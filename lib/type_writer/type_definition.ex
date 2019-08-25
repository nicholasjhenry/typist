defmodule TypeWriter.TypeDefinition do
  @doc """
  Returns the type definition from the AST.
  """

  @type t :: {type_name :: atom, type_function :: atom, arguments :: []}

  # For aliased single type, e.g.:
  # - `String.t`
  # - `ProductCode.t`
  def from_ast({{:., _, [{:__aliases__, _, [type_name]}, type_function]}, _, []}) do
    {type_name, type_function, []}
  end

  # For union types, e.g.:
  # `String.t | non_neg_integer | nil`
  def from_ast({:|, _, types}) do
    Enum.map(types, &from_ast/1)
  end

  # For basic single type, e.g.:
  # - `binary`
  # - `float`
  # - `integer`
  def from_ast({type, [], _}) do
    {type, nil, []}
  end

  # For product types e.g.:
  # - `{String.t, String.t}`
  # - `{integer, float, Decimal.t}`
  def from_ast(product_types) do
    product_types
    |> Tuple.to_list()
    |> Enum.map(&from_ast/1)
    |> List.to_tuple()
  end
end
