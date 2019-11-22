defmodule Typist.Ast do
  def build_ast(type) do
    case type.defined do
      :module ->
        do_build_ast(type)

      :inline ->
        new_module_path = Module.concat([type.module_path, type.name])

        quote do
          # Ensure the module name is available in the namespace it was defined.
          alias unquote(new_module_path)

          defmodule unquote(new_module_path) do
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

      @spec new(unquote(type.ast)) :: t
      def new(value) do
        struct!(__MODULE__, value: value)
      end

      @spec value(t) :: unquote(type.ast)
      def value(%__MODULE__{} = wrapper) do
        wrapper.value
      end

      @spec apply(t, (unquote(type.ast) -> any)) :: any
      def apply(%__MODULE__{} = wrapper, func) do
        func.(wrapper.value)
      end

      defoverridable new: 1, value: 1, apply: 2
    end
  end
end
