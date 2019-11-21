defmodule Typist.SingleCaseUnionType do
  @moduledoc """
  Single case union type is used to wrap a primitive.

  https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/

  Example:

      deftype ProductCode :: String.t
  """
  @enforce_keys [:name, :type, :value, :spec, :module_path]
  defstruct [:name, :type, :value, :spec, :module_path]

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

  # Data type: Single case union type, inline
  #
  # deftype ProductCode1 :: String.t()
  defp maybe_type(
         _current_module,
         module_path,
         {
           :"::",
           _,
           [{:__aliases__, _, [module_name]}, {{:., _, [_, _]}, _, _} = ast]
         },
         _block
       ) do
    type(module_name, module_path, ast)
  end

  # Data type: single case union type, module, (remote type)
  #
  # defmodule ProductCode2 do
  #   use Typist
  #
  #   deftype String.t()
  # end
  defp maybe_type(
         module_name,
         module_path,
         {{:., _, [_, _]}, _, []} = ast,
         _block
       ) do
    type(module_name, module_path, ast)
  end

  # Data type: single case union type, module, (basic type)"
  #
  # defmodule ProductCode2 do
  #   use Typist
  #
  #   deftype binary
  # end
  defp maybe_type(
         _module_name,
         module_path,
         {:"::", _,
          [
            {:__aliases__, _, [module_name]},
            {_basic_type, _, nil} = ast
          ]},
         _block
       ) do
    type(module_name, module_path, ast)
  end

  # Data type: single case union type, module, (basic type, multi-line AST)
  #
  # This can occur with a basic type such as a function
  # defmodule ProductCode2 do
  #   use Typist
  #
  #   deftype binary
  # end

  defp maybe_type(
         _module_name,
         module_path,
         {:"::", _,
          [
            {:__aliases__, _, [module_name]},
            [_] = ast
          ]},
         _block
       ) do
    type(module_name, module_path, ast)
  end

  defp maybe_type(_module_name, _module_path, _ast, _block), do: :none

  defp type(module_name, module_path, ast) do
    type = from_ast(ast)
    {_, value} = type

    %Typist.SingleCaseUnionType{
      name: module_name,
      module_path: module_path,
      type: type,
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
