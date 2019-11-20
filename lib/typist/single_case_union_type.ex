defmodule Typist.SingleCaseUnionType do
  @moduledoc """
  Single case union type is used to wrap a primitive.

  https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/

  Example:

      deftype ProductCode :: String.t
  """
  @enforce_keys [:name, :type]
  defstruct [:name, :type]

  alias Typist.Ast
  import Typist.Utils

  def build(module, ast, block \\ :none) do
    current_module = current_module(module)

    case maybe_type(current_module, ast, block) do
      :none ->
        :none

      type ->
        spec = spec(type)
        Ast.build(current_module, module, type, spec)
    end
  end

  def spec(union_type) do
    {_, ast} = union_type.type

    quote do
      @type t :: %__MODULE__{value: unquote(ast)}
    end
  end

  # Data type: Single case union type, inline
  #
  # deftype ProductCode1 :: String.t()
  def maybe_type(
        _current_module,
        {
          :"::",
          _,
          [{:__aliases__, _, [module]}, {{:., _, [_, _]}, _, _} = type_to_be_wrapped]
        },
        _block
      ) do
    %Typist.SingleCaseUnionType{
      name: module,
      type: from_ast(type_to_be_wrapped)
    }
  end

  # Data type: single case union type, module, (remote type)
  #
  # defmodule ProductCode2 do
  #   use Typist
  #
  #   deftype String.t()
  # end
  def maybe_type(
        current_module,
        {{:., _, [_, _]}, _, []} = type_to_be_wrapped,
        _block
      ) do
    %Typist.SingleCaseUnionType{
      name: current_module,
      type: from_ast(type_to_be_wrapped)
    }
  end

  # Data type: single case union type, module, (basic type)"
  #
  # defmodule ProductCode2 do
  #   use Typist
  #
  #   deftype binary
  # end
  def maybe_type(
        _current_module,
        {:"::", _,
         [
           {:__aliases__, _, [module]},
           {_basic_type, _, nil} = type_to_be_wrapped
         ]},
        _block
      ) do
    %Typist.SingleCaseUnionType{
      name: module,
      type: from_ast(type_to_be_wrapped)
    }
  end

  # Data type: single case union type, module, (basic type, multi-line AST)
  #
  # This can occur with a basic type such as a function
  # defmodule ProductCode2 do
  #   use Typist
  #
  #   deftype binary
  # end

  def maybe_type(
        _current_module,
        {:"::", _,
         [
           {:__aliases__, _, [module]},
           [_] = type_to_be_wrapped
         ]},
        _block
      ) do
    %Typist.SingleCaseUnionType{
      name: module,
      type: from_ast(type_to_be_wrapped)
    }
  end

  def maybe_type(_current_module, _ast, _block), do: :none
end
