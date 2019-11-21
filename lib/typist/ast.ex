defmodule Typist.Ast do
  def build_ast(type) do
    case type.defined do
      :module ->
        do_build_ast(type)

      :inline ->
        quote do
          defmodule unquote(Module.concat([type.module_path, type.name])) do
            unquote(do_build_ast(type))
          end
        end
    end
  end

  defp do_build_ast(type) do
    quote do
      @enforce_keys [:value]
      defstruct [:value]
      unquote(type.spec)

      def __type__ do
        unquote(Macro.escape(%{type | spec: Macro.to_string(type.spec)}))
      end

      def __spec__ do
        unquote(Macro.to_string(type.spec))
      end

      @spec new(unquote(type.ast)) :: t
      def new(value) do
        struct!(__MODULE__, value: value)
      end
    end
  end
end
