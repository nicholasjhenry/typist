defmodule Typist.Generator do
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

    new_code =
      quote do
        alias unquote(module)

        defmodule unquote(module) do
          def __type__ do
            unquote(Macro.escape(metadata))
          end
        end
      end

    [new_code | build(metadata, code)]
  end

  # record
  def do_build({module_name, :t}, metadata, code) do
    module = Module.concat([metadata.calling_module, module_name])

    new_code =
      quote do
        alias unquote(module)

        defmodule unquote(module) do
          def __type__ do
            unquote(Macro.escape(metadata))
          end
        end
      end

    [new_code | code]
  end

  # Inline single case union type
  def do_build(metadata, {:"::", _, [{module_name, :t}, type]}, code) do
    module = Module.concat([metadata.calling_module, module_name])

    new_code =
      quote do
        alias unquote(module)

        defmodule unquote(module) do
          def __type__ do
            unquote(Macro.escape(%{ast: type}))
          end
        end
      end

    [new_code | code]
  end

  # non-block
  def do_build(metadata, {_, _, params}, code) when is_list(params) do
    new_code =
      quote do
        def __type__ do
          unquote(Macro.escape(metadata))
        end
      end

    [new_code | build(metadata, params, code)]
  end

  def do_build(metadata, term, []) when is_atom(term) do
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
