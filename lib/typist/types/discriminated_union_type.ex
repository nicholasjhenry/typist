defmodule Typist.DiscriminatedUnionType do
  @moduledoc """
  Create new types by “summing” existing types.

  https://fsharpforfunandprofit.com/posts/discriminated-unions/

  Example:

      deftype Nickname :: String.t
      deftype FirstLast :: {String.t, String.t}
      deftype Name :: Nickname.t | FirstLast.t
  """

  @enforce_keys [:name, :types, :value, :spec, :module_path, :defined]
  defstruct [:name, :types, :value, :spec, :module_path, :defined]

  import Typist.{Ast, Utils}

  def build(module_path, ast, block \\ :none) do
    case module_path |> module_name() |> maybe_type(module_path, ast, block) do
      :none ->
        :none

      type ->
        build_ast(type)
    end
  end

  # Data type: discriminated union type, module
  defp maybe_type(type_name, module_path, {:|, _, _} = union_types, _block) do
    type(type_name, module_path, union_types, :module)
  end

  # Data type: discriminated union type, inline
  defp maybe_type(
         _module_name,
         module_path,
         {:"::", _,
          [
            {:__aliases__, _, [type_name]},
            {:|, _, _} = union_types
          ]},
         _block
       ) do
    type(type_name, module_path, union_types, :inline)
  end

  defp maybe_type(_module_name, _ast, _block, _defined), do: :none

  defp type(type_name, module_path, value, defined) do
    {:|, _, foo} = value

    types = foo |> Enum.map(&from_ast/1) |> List.flatten()

    %Typist.DiscriminatedUnionType{
      name: type_name,
      module_path: module_path,
      defined: defined,
      types: types,
      value: value,
      spec: spec(value)
    }
  end

  defp spec(value) do
    quote do
      @type t :: %__MODULE__{value: unquote(value)}
    end
  end
end
