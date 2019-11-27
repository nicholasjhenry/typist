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

  defmacro deftype(ast) do
    type(__CALLER__.module, ast)
  end

  def type(calling_module, ast) do
    ast = Parser.parse(ast)
    metadata = %{ast: ast}

    build(calling_module, metadata)
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
