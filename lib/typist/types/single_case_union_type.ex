defmodule Typist.SingleCaseUnionType do
  @moduledoc """
  Single case union type is used to wrap a primitive.

  https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/

  Example:

      deftype ProductCode :: String.t
  """
  @enforce_keys [:name, :type, :value]
  defstruct [:name, :type, :value]

  import Typist.{Ast, Utils}

  def build(module_path, ast, block \\ :none) do
    module_name = module_name(module_path)

    case maybe_type(module_name, ast, block) do
      :none ->
        :none

      type ->
        spec = spec(type)
        build_ast(module_name, module_path, type, spec)
    end
  end

  # Data type: Single case union type, inline
  #
  # deftype ProductCode1 :: String.t()
  defp maybe_type(
         _current_module,
         {
           :"::",
           _,
           [{:__aliases__, _, [module_name]}, {{:., _, [_, _]}, _, _} = ast]
         },
         _block
       ) do
    type(module_name, ast)
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
         {{:., _, [_, _]}, _, []} = ast,
         _block
       ) do
    type(module_name, ast)
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
         {:"::", _,
          [
            {:__aliases__, _, [module_name]},
            {_basic_type, _, nil} = ast
          ]},
         _block
       ) do
    type(module_name, ast)
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
         {:"::", _,
          [
            {:__aliases__, _, [module_name]},
            [_] = ast
          ]},
         _block
       ) do
    type(module_name, ast)
  end

  defp maybe_type(_module_name, _ast, _block), do: :none

  defp type(module_name, ast) do
    type = from_ast(ast)
    {_, value} = type

    %Typist.SingleCaseUnionType{name: module_name, type: type, value: value}
  end

  defp spec(type) do
    quote do
      @type t :: %__MODULE__{value: unquote(type.value)}
    end
  end
end
