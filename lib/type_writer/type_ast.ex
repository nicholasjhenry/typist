defmodule TypeWriter.TypeAst do
  # single types
  def get_type({{:., _, [{:__aliases__, _, [type_name]}, type_function]}, _, []}) do
    {type_name, type_function, []}
  end

  # union types
  def get_type({:|, [], types}) do
    Enum.map(types, &get_type/1)
  end

  # match basic types, e.g. binary, float, integer
  def get_type({type, [], _}) do
    {type, nil, []}
  end

  def get_type({:|, _, union_types}) do
    union_types |> Enum.map(&get_type/1)
  end

  # product types
  def get_type(product_types) do
    product_types |> Tuple.to_list() |> Enum.map(&get_type/1) |> List.to_tuple()
  end
end
