defmodule TypeWriter.TypeDefinition do
  @doc """
  Returns the type definition from the AST.
  """

  # For union types, e.g.:
  # `String.t | non_neg_integer | nil`
  def from_ast({:|, _, types}) do
    Enum.map(types, &from_ast/1)
  end

  def from_ast(ast) do
    {Macro.to_string(ast), ast}
  end
end
