defmodule TypeWriter do
  @moduledoc """
  A DSL for defining types inspired by F#.
  """

  defmacro __using__(_opts) do
    quote do
      import TypeWriter
    end
  end

  # Pattern match on `::` in `deftype ProductCode :: String.t()`
  defmacro deftype({:"::", _, args}) do
    type_name = get_type_name(args)
    type = get_type(args)

    quote do
      defmodule __MODULE__.unquote(Module.concat([type_name])) do
        defstruct value: nil
        @type t :: %__MODULE__{value: unquote(type).t()}
      end
    end
  end

  # The name of the type is contained in the next nested line.
  # [
  #   {:__aliases__, [line: 6], [:ProductCode]},
  #   _type
  # ]
  defp get_type_name([{:__aliases__, _, [type]}, _type]) do
    type
  end

  # The type spec is contained in the second nested line.
  # [
  #   _type_name,
  #   {{:., [line: 6], [{:__aliases__, [line: 6], [:String]}, :t]}, [line: 6], []}
  # ]
  defp get_type([_type_name, {{:., _, [{:__aliases__, _, [type]}, :t]}, _, _}]) do
    type
  end
end
