defmodule Typist.Ast do
  import Typist.Utils

  def build_ast(module_name, type) do
    struct_defn = struct_defn(type)

    if module_defined?(module_name, type.name) do
      do_build_ast(struct_defn, type)
    else
      quote do
        defmodule unquote(Module.concat([type.module_path, type.name])) do
          unquote(do_build_ast(struct_defn, type))
        end
      end
    end
  end

  defp do_build_ast(struct_defn, type) do
    quote do
      unquote(struct_defn)
      unquote(type.spec)

      def __type__ do
        unquote(Macro.escape(type))
      end

      def __spec__ do
        unquote(Macro.to_string(type.spec))
      end

      @spec new(unquote(type.value)) :: t
      def new(value) do
        struct!(__MODULE__, value: value)
      end
    end
  end

  defp struct_defn(_type) do
    quote do
      @enforce_keys [:value]
      defstruct [:value]
    end
  end
end
