defmodule Typist.Generator do
  alias Typist.TypeSpec

  # Public entry points
  def build(%Typist.Metadata{} = metadata, code) do
    do_build(metadata, metadata.ast, code)
  end

  def build(module_ast, metadata, code) do
    do_build(module_ast, metadata, code)
  end

  # inline union
  def do_build({module_name, :t}, %{ast: {:|, _, _}} = metadata, code) do
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

    [new_code | build(metadata, code)]
  end

  # record
  def do_build({module_name, :t}, metadata, code) do
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

  def do_build(metadata, {:"::", _, [{module_name, :t}, type]}, code) do
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
  def do_build(metadata, {_, _, params} = ast, code) when is_list(params) do
    spec = TypeSpec.from_ast(ast)

    new_code =
      quote do
        def __type__ do
          unquote(Macro.escape(%{metadata | spec: Macro.to_string(spec)}))
        end
      end

    [new_code | build(metadata, params, code)]
  end

  def do_build(metadata, term, []) when is_atom(term) or is_tuple(term) do
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

  def do_build(_metadata, term, code) when is_tuple(term) do
    code
  end

  def do_build(_metadata, term, code) when is_atom(term) do
    code
  end

  def do_build(metadata, [head | tail], code) do
    new_code = build(metadata, head, code)

    [new_code | build(metadata, tail, code)]
  end

  def do_build(_metadata, [], code) do
    code
  end
end
