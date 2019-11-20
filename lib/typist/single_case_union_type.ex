defmodule Typist.SingleCaseUnionType do
  @moduledoc """
  Single case union type is used to wrap a primitive.

  https://fsharpforfunandprofit.com/posts/designing-with-types-single-case-dus/

  Example:

      deftype ProductCode :: String.t
  """
  @enforce_keys [:name, :type]
  defstruct [:name, :type]

  import Typist.Utils

  # Data type: Single case union type, inline
  #
  # deftype ProductCode1 :: String.t()
  def maybe_build(
        _current_module,
        {
          :"::",
          _,
          [{:__aliases__, _, [module]}, {{:., _, [_, _]}, _, _} = type_to_be_wrapped]
        }
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
  def maybe_build(
        current_module,
        {{:., _, [_, _]}, _, []} = type_to_be_wrapped
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
  def maybe_build(
        _current_module,
        {:"::", _,
         [
           {:__aliases__, _, [module]},
           {_basic_type, _, nil} = type_to_be_wrapped
         ]}
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

  def maybe_build(
        _current_module,
        {:"::", _,
         [
           {:__aliases__, _, [module]},
           [_] = type_to_be_wrapped
         ]}
      ) do
    %Typist.SingleCaseUnionType{
      name: module,
      type: from_ast(type_to_be_wrapped)
    }
  end

  def maybe_build(_current_module, _ast), do: :none
end
