defmodule Typist do
  @moduledoc """
  Documentation for Typist.
  """
  alias Typist.Parser

  defmacro __using__(_opts \\ []) do
    quote do
      import Typist
    end
  end

  # Inline record
  defmacro deftype(ast, do: block) do
    record(__CALLER__.module, ast, block)
  end

  def record(calling_module, module_ast, block_ast) do
    module = Parser.parse(module_ast)
    fields = Parser.parse(block_ast)
    metadata = %{ast: fields}

    build(calling_module, module, metadata)
  end

  # Module record
  defmacro deftype(do: block) do
    type(__CALLER__.module, block)
  end

  # Union and product types (inline or module)
  defmacro deftype(ast) do
    type(__CALLER__.module, ast)
  end

  def type(calling_module, ast) do
    ast = Parser.parse(ast)
    metadata = %{ast: ast}

    build(calling_module, metadata)
  end

  defp build(calling_module, {module_name, :t}, metadata) do
    module = Module.concat([calling_module, module_name])

    quote do
      alias unquote(module)

      defmodule unquote(module) do
        def __type__ do
          unquote(Macro.escape(metadata))
        end
      end
    end
  end

  defp build(calling_module, %{ast: {:"::", _, [{module_name, :t}, type]}} = metadata) do
    module = Module.concat([calling_module, module_name])

    quote do
      alias unquote(module)

      defmodule unquote(module) do
        def __type__ do
          unquote(Macro.escape(%{metadata | ast: type}))
        end
      end
    end
  end

  defp build(_calling_module, metadata) do
    quote do
      def __type__ do
        unquote(Macro.escape(metadata))
      end
    end
  end
end
