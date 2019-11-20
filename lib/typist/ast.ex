defmodule Typist.Ast do
  import Typist.Utils

  def build_ast(current_module, module, type, spec) do
    struct_defn = struct_defn(type)

    if module_defined?(current_module, type.name) do
      do_build_ast(struct_defn, spec, type)
    else
      quote do
        defmodule unquote(Module.concat([module, type.name])) do
          unquote(do_build_ast(struct_defn, spec, type))
        end
      end
    end
  end

  defp do_build_ast(struct_defn, spec, type) do
    quote do
      unquote(struct_defn)
      unquote(spec)

      def __type__ do
        unquote(Macro.escape(type))
      end

      def __spec__ do
        unquote(Macro.to_string(spec))
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
