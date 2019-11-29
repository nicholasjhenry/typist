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

    constructor =
      quote do
        @spec new(%{unquote_splicing(TypeSpec.from_ast(ast))}) :: t
      end

    metadata = %{
      metadata
      | spec: Macro.to_string(spec),
        constructor: Macro.to_string(constructor)
    }

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
      unquote(spec)

      def __type__ do
        unquote(Macro.escape(metadata))
      end

      unquote(constructor)

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

      @spec value(t) :: unquote(TypeSpec.from_ast(ast))
      def value(%__MODULE__{} = wrapper) do
        wrapper.value
      end

      @spec apply(t, (unquote(TypeSpec.from_ast(ast)) -> any)) :: any
      def apply(%__MODULE__{} = wrapper, func) do
        func.(wrapper.value)
      end

      defoverridable new: 1, value: 1, apply: 2
    end
  end
end
