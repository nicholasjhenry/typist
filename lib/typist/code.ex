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
    spec =
      quote do
        @type t :: %__MODULE__{unquote_splicing(TypeSpec.from_ast(ast))}
      end

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
    spec =
      quote do
        @type t :: unquote(TypeSpec.from_ast(ast))
      end

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

  def product(metadata, ast) do
    wrapped_type(metadata, ast)
  end

  def single_case_union(metadata, ast) do
    wrapped_type(metadata, ast)
  end

  defp wrapped_type(metadata, ast) do
    spec =
      quote do
        @type t :: %__MODULE__{value: unquote(TypeSpec.from_ast(ast))}
      end

    constructor =
      quote do
        @spec new(unquote(TypeSpec.from_ast(ast))) :: t
      end

    metadata = %{
      metadata
      | ast: ast,
        spec: Macro.to_string(spec),
        constructor: Macro.to_string(constructor)
    }

    quote do
      @enforce_keys [:value]
      defstruct [:value]

      unquote(spec)

      def __type__ do
        unquote(Macro.escape(metadata))
      end

      unquote(constructor)

      def new(value) do
        struct!(__MODULE__, value: value)
      end
    end
  end
end
