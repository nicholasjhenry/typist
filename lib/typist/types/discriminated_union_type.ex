defmodule Typist.DiscriminatedUnionType do
  @moduledoc """
  Create new types by “summing” existing types.

  https://fsharpforfunandprofit.com/posts/discriminated-unions/

  Example:

      deftype Nickname :: String.t
      deftype FirstLast :: {String.t, String.t}
      deftype Name :: Nickname.t | FirstLast.t
  """

  @enforce_keys [:name, :types, :value, :spec, :module_path]
  defstruct [:name, :types, :value, :spec, :module_path]

  import Typist.{Ast, Utils}

  def build(module_path, ast, block \\ :none) do
    module_name = module_name(module_path)

    case maybe_type(module_name, module_path, ast, block) do
      :none ->
        :none

      type ->
        build_ast(module_name, type)
    end
  end

  # Data type: discriminated union type, module
  defp maybe_type(type_name, module_path, {:|, _, union_types}, _block) do
    type(type_name, module_path, union_types)
  end

  # Data type: discriminated union type, inline
  defp maybe_type(
         _module_name,
         module_path,
         {:"::", _,
          [
            {:__aliases__, _, [type_name]},
            {:|, _, union_types}
          ]},
         _block
       ) do
    type(type_name, module_path, union_types)
  end

  defp maybe_type(_module_name, _module_path, _ast, _block), do: :none

  defp type(type_name, module_path, union_types) do
    types = union_types |> Enum.map(&from_ast/1) |> List.flatten()
    value = {:|, [], union_types}

    %Typist.DiscriminatedUnionType{
      name: type_name,
      module_path: module_path,
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
