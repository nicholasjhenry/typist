defmodule TypeWriter do
  @moduledoc """
  A DSL for defining types inspired by F#.
  """

  defmacro __using__(_opts) do
    quote do
      import TypeWriter
    end
  end

  # deftype/1
  # Pattern match on `::` in `deftype ProductCode :: String.t()`, aka "inline syntax"
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

  # deftype/1
  # Pattern match on deftype String.t(), aka "module syntax"
  defmacro deftype({{:., _, [{:__aliases__, _, [type]}, :t]}, _, _}) do
    quote do
      defstruct value: nil
      @type t :: %__MODULE__{value: unquote(type).t()}
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

  # deftype/2
  defmacro deftype({:__aliases__, _, [type_name]}, do: {:__block__, [], ast}) do
    fields = extract_fields(ast)

    struct_body = Enum.map(fields, fn {field, default, _type} -> {field, default} end)

    typespec =
      Enum.map(fields, fn
        {field, _default, {module, type}} -> {field, Module.concat([module, type])}
        {field, _default, type} -> {field, type}
      end)

    quote do
      defmodule __MODULE__.unquote(Module.concat([type_name])) do
        defstruct unquote(struct_body)
        @type t :: %__MODULE__{unquote_splicing(typespec)}
      end
    end
  end

  defp extract_fields(ast) do
    Enum.map(ast, fn
      #   {:"::", [line: 29], [ {:code, [line: 29], nil}, {{:., [line: 29], [{:__aliases__, [line: 29], [:ProductCode1]}, :t]}, [line: 29], []} ]},
      {:"::", _, [{field, _, default}, {{:., _, [{:__aliases__, _, [module]}, type]}, _, []}]} ->
        {field, default, {module, type}}

      # {:"::", [line: 30], [{:price, [line: 30], nil}, {:float, [line: 30], []}]}
      {:"::", _, [{field, _, default}, {type, _, []}]} ->
        {field, default, type}
    end)
  end
end
