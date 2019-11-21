defmodule Typist.SingleCaseUnionType do
  @moduledoc """
  Single case union type is used to wrap a primitive.

  https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/

  Example:

      deftype ProductCode :: String.t
  """
  @enforce_keys [:name, :ast, :spec, :module_path, :defined]

  defstruct [:name, :ast, :spec, :module_path, :defined]

  import Typist.{Ast, Module}

  def build(module_path, ast, block \\ :none) do
    module_name = module_name(module_path)

    case maybe_type(module_name, module_path, ast, block) do
      :none ->
        :none

      type ->
        build_ast(type)
    end
  end

  # Data type: Single case union type, inline
  #
  # deftype ProductCode1 :: String.t()
  defp maybe_type(
         _current_module,
         module_path,
         {
           :"::",
           _,
           [{:__aliases__, _, [type_name]}, {{:., _, [_, _]}, _, _} = ast]
         },
         _block
       ) do
    type(type_name, module_path, ast, :inline)
  end

  # Data type: single case union type, module, (remote type)
  #
  # defmodule ProductCode2 do
  #   use Typist
  #
  #   deftype String.t()
  # end
  defp maybe_type(
         type_name,
         module_path,
         {{:., _, [_, _]}, _, []} = ast,
         _block
       ) do
    type(type_name, module_path, ast, :module)
  end

  # Data type: single case union type, module, (basic type)"
  #
  # deftype ProductCodeBar :: binary
  defp maybe_type(
         _module_name,
         module_path,
         {:"::", _,
          [
            {:__aliases__, _, [type_name]},
            {_basic_type, _, nil} = ast
          ]},
         _block
       ) do
    type(type_name, module_path, ast, :inline)
  end

  # Data type: single case union type, inline, (basic type, multi-line AST)
  #
  # This can occur with a basic type such as a function
  # defmodule ProductCode2 do
  #   use Typist
  #
  #   deftype binary
  # end
  # deftype ProductCodeBaz :: (binary -> integer)

  defp maybe_type(
         _module_name,
         module_path,
         {:"::", _,
          [
            {:__aliases__, _, [type_name]},
            [_] = ast
          ]},
         _block
       ) do
    type(type_name, module_path, ast, :inline)
  end

  defp maybe_type(_module_name, _module_path, _ast, _block), do: :none

  defp type(module_name, module_path, ast, defined) do
    %Typist.SingleCaseUnionType{
      name: module_name,
      module_path: module_path,
      defined: defined,
      ast: ast,
      spec: spec(ast)
    }
  end

  defp spec(value) do
    quote do
      @type t :: %__MODULE__{value: unquote(value)}
    end
  end
end
