defmodule Typist.Generator do
  alias Typist.TypeSpec

  # Public entry points
  def generate(%Typist.Metadata{} = metadata, code) do
    perform(metadata, metadata.ast, code)
  end

  def generate(module_ast, metadata, code) do
    perform(module_ast, metadata, code)
  end

  # Generate for inline union
  def perform({module_name, :t}, %{ast: {:|, _, _}} = metadata, code) do
    module = Module.concat([metadata.calling_module, module_name])

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
  def perform({module_name, :t}, %{ast: {:record, _, _}} = metadata, code) do
    module = Module.concat([metadata.calling_module, module_name])

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

    [new_code | code]
  end

  def perform(metadata, {:"::", _, [{module_name, :t}, type]}, code) do
    IO.inspect(metadata.ast)
    module = Module.concat([metadata.calling_module, module_name])

    spec = TypeSpec.from_ast(type)

    new_code =
      quote do
        alias unquote(module)

        defmodule unquote(module) do
          def __type__ do
            unquote(Macro.escape(%{metadata | ast: type, spec: Macro.to_string(spec)}))
          end
        end
      end

    [new_code | code]
  end

  # non-block
  def perform(metadata, {_, _, params} = ast, code) when is_list(params) do
    spec = TypeSpec.from_ast(ast)

    metadata = %{metadata | spec: Macro.to_string(spec)}

    new_code =
      quote do
        def __type__ do
          unquote(Macro.escape(metadata))
        end
      end

    [new_code | generate(metadata, params, code)]
  end

  def perform(metadata, term, []) when is_atom(term) or is_tuple(term) do
    spec = TypeSpec.from_ast(term)

    metadata = %{metadata | spec: Macro.to_string(spec)}

    new_code =
      quote do
        def __type__ do
          unquote(Macro.escape(metadata))
        end
      end

    [new_code]
  end

  def perform(_metadata, term, code) when is_tuple(term) do
    code
  end

  def perform(_metadata, term, code) when is_atom(term) do
    code
  end

  def perform(metadata, [head | tail], code) do
    new_code = generate(metadata, head, code)

    [new_code | generate(metadata, tail, code)]
  end

  def perform(_metadata, [], code) do
    code
  end
end
