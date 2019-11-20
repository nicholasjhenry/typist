defmodule Typist.Utils do
  @doc """
  # Example:

    iex> Typist.Utils.module_name(MyApp.ProductCode)
    :ProductCode
  """
  def module_name(module_path) do
    Module.split(module_path)
    |> Enum.reverse()
    |> List.first()
    |> String.to_atom()
  end

  def module_defined?(current_module, type_name) do
    current_module == type_name
  end

  # Returns the type definition from the AST.
  # For union types, e.g.:
  # `String.t | non_neg_integer | nil`
  def from_ast({:|, _, types}) do
    Enum.map(types, &from_ast/1)
  end

  def from_ast(ast) do
    {Macro.to_string(ast), ast}
  end
end
