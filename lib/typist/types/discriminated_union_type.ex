defmodule Typist.DiscriminatedUnionType do
  @moduledoc """
  Create new types by “summing” existing types.

  https://fsharpforfunandprofit.com/posts/discriminated-unions/

  Example:

      deftype Nickname :: String.t
      deftype FirstLast :: {String.t, String.t}
      deftype Name :: Nickname.t | FirstLast.t
  """

  @enforce_keys [:name, :ast, :spec, :module_path, :defined]
  defstruct [:name, :ast, :spec, :module_path, :defined]

  import Typist.Module

  def build(module_path, ast, block \\ :none) do
    case module_path |> module_name() |> maybe_type(module_path, ast, block) do
      :none ->
        :none

      type ->
        build_ast(type)
    end
  end

  # Data type: discriminated union type, module
  defp maybe_type(type_name, module_path, {:|, _, _} = ast, _block = :none) do
    type(type_name, module_path, ast, :module)
  end

  # Data type: discriminated union type, inline
  defp maybe_type(
         _module_name,
         module_path,
         {:"::", _,
          [
            {:__aliases__, _, [type_name]},
            {:|, _, _} = ast
          ]},
         _block = :none
       ) do
    type(type_name, module_path, ast, :inline)
  end

  defp maybe_type(_module_name, _ast, _block, _defined), do: :none

  defp type(type_name, module_path, ast, defined) do
    %Typist.DiscriminatedUnionType{
      # The name of the type, e.g. `PersonalName`
      name: type_name,
      # The module path in which the type was defined, e.g. `MyApp.Products.Price`
      module_path: module_path,
      # How the type was defined, `:inline | :module`
      defined: defined,
      # Type information as an AST, e.g. `Nickname.t() | FirstLast.t() | FormalName.t() | binary`
      ast: ast,
      # The spec of the type as an AST, e.g. `@type t :: %__MODULE__{value: String.t()}`
      spec: spec(ast)
    }
  end

  defp spec(value) do
    quote do
      @type t :: unquote(value)
    end
  end

  defp build_ast(type) do
    case type.defined do
      :module ->
        do_build_ast(type)

      :inline ->
        new_module_path = Module.concat([type.module_path, type.name])

        quote do
          # Ensure the module name is available in the namespace it was defined.
          alias unquote(new_module_path)

          defmodule unquote(new_module_path) do
            unquote(do_build_ast(type))
          end
        end
    end
  end

  defp do_build_ast(type) do
    quote do
      unquote(type.spec)

      def __type__ do
        unquote(Macro.escape(%{type | spec: Macro.to_string(type.spec)}))
      end

      @spec new(unquote(type.ast)) :: t
      def new(value), do: value

      defoverridable new: 1
    end
  end
end
