defmodule Typist.Code do
  alias Typist.TypeSpec

  def module(content, metadata, {module_name, :t}) do
    alias_name = Module.concat([metadata.calling_module] ++ [List.first(module_name)])
    module = Module.concat([metadata.calling_module] ++ module_name)

    quote do
      alias unquote(alias_name)

      defmodule unquote(module) do
        unquote(content)
      end
    end
  end

  def record(metadata, {_, _, fields} = ast) do
    spec = TypeSpec.from_ast(ast)
    metadata = %{metadata | spec: Macro.to_string(spec)}
    struct = Enum.map(fields, fn {key, _} -> key end)

    quote do
      @enforce_keys [unquote_splicing(struct)]
      defstruct [unquote_splicing(struct)]

      def __type__ do
        unquote(Macro.escape(metadata))
      end

      def new(fields) do
        struct!(__MODULE__, fields)
      end
    end
  end

  def union(metadata, ast) do
    spec = TypeSpec.from_ast(ast)
    metadata = %{metadata | ast: ast, spec: Macro.to_string(spec)}

    quote do
      def __type__ do
        unquote(Macro.escape(metadata))
      end

      # Add spec
      def new(value) do
        value
      end
    end
  end

  def wrapped_type(metadata, ast) do
    spec = TypeSpec.from_ast(ast)
    metadata = %{metadata | ast: ast, spec: Macro.to_string(spec)}

    quote do
      defstruct [:value]

      def __type__ do
        unquote(Macro.escape(metadata))
      end

      # Add spec
      def new(value) do
        struct!(__MODULE__, value: value)
      end
    end
  end

  def single_union(metadata, term) do
    spec = TypeSpec.from_ast(term)
    metadata = %{metadata | spec: Macro.to_string(spec)}

    quote do
      @enforce_keys [:value]
      defstruct [:value]

      unquote(spec)

      def __type__ do
        unquote(Macro.escape(metadata))
      end

      # Add spec
      def new(value) do
        struct!(__MODULE__, value: value)
      end
    end
  end
end
