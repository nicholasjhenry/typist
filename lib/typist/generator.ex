defmodule Typist.Generator do
  alias Typist.TypeSpec

  # Generate for a do-block
  # e.g. deftype Foo do: price :: integer
  def generate(module_ast, %Typist.Metadata{} = metadata, code) do
    perform_do_block(module_ast, metadata, code)
  end

  # Generate for inline or module
  def generate(%Typist.Metadata{} = metadata, code) do
    perform(metadata, metadata.ast, code)
  end

  # Generate for inline union
  # i.e. {:|, _, _}
  def perform_do_block({module_name, :t}, %{ast: {:|, _, _}} = metadata, code) do
    module = Module.concat([metadata.calling_module] ++ module_name)

    spec = TypeSpec.from_ast(metadata.ast)

    new_code =
      quote do
        alias unquote(module)

        defmodule unquote(module) do
          def __type__ do
            unquote(Macro.escape(%{metadata | spec: Macro.to_string(spec)}))
          end

          # Add spec
          def new(value) do
            value
          end
        end
      end

    [new_code | generate(metadata, code)]
  end

  # Generate for record from block
  def perform_do_block(module_ast, %{ast: {:record, _, _}} = metadata, [] = code) do
    {_, _, fields} = metadata.ast

    record =
      metadata
      |> record(metadata.ast)
      |> module(metadata, module_ast)

    [record | perform(metadata, fields, code)]
  end

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

  # Generate for record from module
  def perform(%{ast: {:record, _, _} = ast} = metadata, ast, [] = code) do
    {_, _, fields} = ast
    [record(metadata, ast) | perform(metadata, fields, code)]
  end

  defp record(metadata, {_, _, fields} = ast) do
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

  # Generate for aliases for a union type
  def perform(metadata, {:"::", _, [{module_name, :t}, {:|, _, _} = type]}, [] = code) do
    module = Module.concat([metadata.calling_module] ++ module_name)

    spec = TypeSpec.from_ast(type)

    new_code =
      quote do
        alias unquote(module)

        defmodule unquote(module) do
          def __type__ do
            unquote(Macro.escape(%{metadata | ast: type, spec: Macro.to_string(spec)}))
          end

          # Add spec
          def new(value) do
            value
          end
        end
      end

    [new_code | code]
  end

  # Generate for aliases for a non union type
  def perform(metadata, {:"::", _, [{module_name, :t}, type]}, [] = code) do
    module = Module.concat([metadata.calling_module] ++ module_name)

    spec = TypeSpec.from_ast(type)

    new_code =
      quote do
        alias unquote(module)

        defmodule unquote(module) do
          defstruct [:value]

          def __type__ do
            unquote(Macro.escape(%{metadata | ast: type, spec: Macro.to_string(spec)}))
          end

          # Add spec
          def new(value) do
            struct!(__MODULE__, value: value)
          end
        end
      end

    [new_code | code]
  end

  # Generate for product
  # e.g. {:product, _, _}
  def perform(metadata, {:product, _, params} = ast, code) do
    spec = TypeSpec.from_ast(ast)

    metadata = %{metadata | spec: Macro.to_string(spec)}

    new_code =
      quote do
        defstruct [:value]

        def __type__ do
          unquote(Macro.escape(metadata))
        end

        def new(value) do
          struct!(__MODULE__, value: value)
        end
      end

    [new_code | perform(metadata, params, code)]
  end

  # Generate for inline or module-based definitions
  def perform(%{ast: {func, _, _} = ast} = metadata, {_, _, params} = ast, [] = code)
      when func in [:|] and is_list(params) do
    spec = TypeSpec.from_ast(ast)

    metadata = %{metadata | spec: Macro.to_string(spec)}

    new_code =
      quote do
        def __type__ do
          unquote(Macro.escape(metadata))
        end

        def new(value) do
          value
        end
      end

    [new_code | perform(metadata, params, code)]
  end

  def perform(%{ast: {_, :t}} = metadata, {_, :t} = term, code) do
    single_union(metadata, term, code)
  end

  defp single_union(metadata, term, code) do
    spec = TypeSpec.from_ast(term)

    metadata = %{metadata | spec: Macro.to_string(spec)}

    new_code =
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

    [new_code | code]
  end

  def perform(metadata, [head | tail], code) do
    [perform(metadata, head, code) | perform(metadata, tail, code)]
  end

  def perform(_metadata, _term, code) do
    code
  end
end
