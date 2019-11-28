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
        end
      end

    [new_code | generate(metadata, code)]
  end

  # Generate for record
  # i.e. {:record, _, _}
  def perform_do_block({module_name, :t}, %{ast: {:record, _, _}} = metadata, code) do
    alias_name = Module.concat([metadata.calling_module] ++ [List.first(module_name)])
    module = Module.concat([metadata.calling_module] ++ module_name)
    spec = TypeSpec.from_ast(metadata.ast)

    new_code =
      quote do
        alias unquote(alias_name)

        defmodule unquote(module) do
          def __type__ do
            unquote(Macro.escape(%{metadata | spec: Macro.to_string(spec)}))
          end
        end
      end

    [new_code | code]
  end

  # Generate for aliases
  def perform(metadata, {:"::", _, [{module_name, :t}, type]}, code) do
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

  # Generate for inline or module-based definitions
  def perform(metadata, {_, _, params} = ast, code) when is_list(params) do
    spec = TypeSpec.from_ast(ast)

    metadata = %{metadata | spec: Macro.to_string(spec)}

    new_code =
      quote do
        def __type__ do
          unquote(Macro.escape(metadata))
        end
      end

    [new_code | perform(metadata, params, code)]
  end

  # Generate for aliases, i.e. {:"::", _, _}
  def perform(%{ast: {:"::", _, _}} = metadata, {_, :t} = term, code) do
    single_union(metadata, term, code)
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

  # Generate for record fields, products
  # e.g. {:code, {[:String], :t}}, {:price, :integer}
  def perform(metadata, term, [] = code) when is_tuple(term) do
    spec = TypeSpec.from_ast(term)

    metadata = %{metadata | spec: Macro.to_string(spec)}

    new_code =
      quote do
        def __type__ do
          unquote(Macro.escape(metadata))
        end
      end

    [new_code | code]
  end

  def perform(_metadata, term, code) when is_tuple(term) do
    code
  end

  def perform(_metadata, term, code) when is_atom(term) do
    code
  end

  def perform(metadata, [head | tail], code) do
    new_code = perform(metadata, head, code)

    [new_code | perform(metadata, tail, code)]
  end

  def perform(_metadata, [], code) do
    code
  end
end
