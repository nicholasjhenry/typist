defmodule Typist.Ast do
  def build(current_module, module, type, spec) do
    struct_defn = struct_defn(type)

    if module_defined?(current_module, type.name) do
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
    else
      quote do
        defmodule unquote(Module.concat([module, type.name])) do
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
    end
  end

  defp module_defined?(current_module, type_name) do
    current_module == type_name
  end

  defp struct_defn(_type) do
    quote do
      @enforce_keys [:value]
      defstruct [:value]
    end
  end
end
