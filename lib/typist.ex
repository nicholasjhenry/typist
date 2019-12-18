defmodule Typist do
  alias Typist.Code

  defmacro __using__(_opts) do
    quote do
      import Typist
    end
  end

  defmacro deftype(ast, do: block) do
    type(__CALLER__.module, ast, block)
  end

  defmacro deftype(block) do
    type(__CALLER__.module, block)
  end

  # Define a record type inline
  defp type(caller_module, {:__aliases__, _metadata, module_name}, block) do
    alias_name = Module.concat([caller_module] ++ [List.first(module_name)])
    module = Module.concat([caller_module] ++ module_name)

    spec = Code.to_spec(block)
    struct = Code.to_struct(block)

    quote location: :keep do
      alias unquote(alias_name)

      defmodule unquote(module) do
        unquote(struct)

        def __type__ do
          %{spec: unquote(Macro.to_string(spec))}
        end
      end
    end
  end

  # Define a record type in module
  defp type(_caller_module, do: block) do
    spec = Code.to_spec(block)
    struct = Code.to_struct(block)

    quote location: :keep do
      unquote(struct)

      def __type__ do
        %{spec: unquote(Macro.to_string(spec))}
      end
    end
  end

  # Define a single case union type inside module
  defp type(_caller_module, {{:., _, [_, :t]}, _, []} = type) do
    spec =
      quote do
        @type t :: %__MODULE__{value: unquote(type)}
      end

    quote do
      defstruct [:value]

      def __type__ do
        %{spec: unquote(Macro.to_string(spec))}
      end
    end
  end

  # Define a single case union type inline
  defp type(caller_module, {:"::", _, [{:__aliases__, _, module_name}, {:|, _, _} = type]}) do
    alias_name = Module.concat([caller_module] ++ [List.first(module_name)])
    module = Module.concat([caller_module] ++ module_name)

    spec =
      quote do
        @type t :: unquote(type)
      end

    quote location: :keep do
      alias unquote(alias_name)

      defmodule unquote(module) do
        defstruct [:value]

        def __type__ do
          %{spec: unquote(Macro.to_string(spec))}
        end
      end
    end
  end

  # Define a single case union type inline
  defp type(caller_module, {:"::", _, [{:__aliases__, _, module_name}, type]}) do
    alias_name = Module.concat([caller_module] ++ [List.first(module_name)])
    module = Module.concat([caller_module] ++ module_name)

    spec =
      quote do
        @type t :: %__MODULE__{value: unquote(type)}
      end

    quote location: :keep do
      alias unquote(alias_name)

      defmodule unquote(module) do
        defstruct [:value]

        def __type__ do
          %{spec: unquote(Macro.to_string(spec))}
        end
      end
    end
  end
end
