defmodule Typist.Module do
  @doc """
  # Example:

    iex> Typist.Module.module_name(MyApp.ProductCode)
    :ProductCode
  """
  def module_name(module_path) do
    Module.split(module_path)
    |> Enum.reverse()
    |> List.first()
    |> String.to_atom()
  end

  def module_defined?(lhs, rhs) do
    lhs == rhs
  end
end
