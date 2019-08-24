defmodule TypeWriter do
  @moduledoc """
  A DSL for defining types inspired by F#.
  """

  # Types:
  # -

  defmacro __using__(_opts) do
    quote do
      import TypeWriter
    end
  end

  defmacro deftype(ast) do
    type = maybe_single_case_union_type(ast)

    quote do
      defmodule unquote(Module.concat([type.name])) do
        def __type__ do
          unquote(Macro.escape(type))
        end
      end
    end
  end

  defmodule SingleCaseUnionType do
    defstruct [:name, :type]
  end

  # deftype ProductCode1 :: String.t()
  def maybe_single_case_union_type(
        {:"::", _,
         [
           {:__aliases__, _, [module]},
           {{:., _, [{:__aliases__, _, [type_name]}, type_function]}, _, []}
         ]}
      ) do
    %TypeWriter.SingleCaseUnionType{
      name: module,
      type: {type_name, type_function, []}
    }
  end
end
