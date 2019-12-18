defmodule Typist do
  alias Typist.Code

  defmodule Type do
    defstruct [:caller_module, :spec, :module_name]
  end

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

  defmacro defunion(ast, block) do
    union(__CALLER__.module, ast, block)
  end

  defp union(caller_module, {:__aliases__, _metadata, module_name}, do: block) do
    types = types(caller_module, block)
    spec = union_spec(block)

    spec =
      quote do
        @type t :: unquote(spec)
      end

    type = %Type{caller_module: caller_module, module_name: module_name, spec: spec}

    content =
      quote do
        def __type__ do
          unquote(Macro.escape(%{type | spec: Macro.to_string(type.spec)}))
        end
      end

    Code.module(type, content, types)
  end

  defp types(caller_module, {:__block__, _, ast}) do
    Enum.map(ast, &type(caller_module, &1))
  end

  defp union_spec({:__block__, _, ast}) do
    ast
    |> Enum.map(&union_spec/1)
    |> union_spec
  end

  defp union_spec({:"::", _, [type, _]}) do
    quote do
      unquote(type).t
    end
  end

  defp union_spec([head, tail]) do
    {:|, [], [head, tail]}
  end

  defp union_spec([head | tail]) do
    {:|, [], [head, union_spec(tail)]}
  end

  # Define a record type inline
  defp type(caller_module, {:__aliases__, _metadata, module_name}, block) do
    spec = Code.to_spec(block)
    struct = Code.to_struct(block)
    type = %Type{caller_module: caller_module, module_name: module_name, spec: spec}

    content =
      quote do
        unquote(struct)

        def __type__ do
          unquote(Macro.escape(%{type | spec: Macro.to_string(type.spec)}))
        end
      end

    Code.module(type, content)
  end

  # Define a record type in module
  defp type(_caller_module, do: block) do
    spec = Code.to_spec(block)
    struct = Code.to_struct(block)

    quote location: :keep do
      unquote(struct)

      def __type__ do
        %Type{spec: unquote(Macro.to_string(spec))}
      end
    end
  end

  # Define a dscriminated union type inline
  defp type(caller_module, {:"::", _, [{:__aliases__, _, module_name}, {:|, _, _} = type]}) do
    spec =
      quote do
        @type t :: unquote(type)
      end

    type = %Type{spec: spec, caller_module: caller_module, module_name: module_name}

    content =
      quote do
        defstruct [:value]

        def __type__ do
          unquote(Macro.escape(%{type | spec: Macro.to_string(type.spec)}))
        end
      end

    Code.module(type, content)
  end

  # Define a dscriminated union type in a module
  defp type(_caller_module, {:|, _, _} = type) do
    spec =
      quote do
        @type t :: unquote(type)
      end

    quote location: :keep do
      def __type__ do
        %Type{spec: unquote(Macro.to_string(spec))}
      end
    end
  end

  # Define a single case union type inline
  defp type(caller_module, {:"::", _, [{:__aliases__, _, module_name}, type]}) do
    spec =
      quote do
        @type t :: %__MODULE__{value: unquote(type)}
      end

    type = %Type{spec: spec, caller_module: caller_module, module_name: module_name}

    content =
      quote do
        defstruct [:value]

        def __type__ do
          unquote(Macro.escape(%{type | spec: Macro.to_string(type.spec)}))
        end
      end

    Code.module(type, content)
  end

  # Define a single case union or product type inside module
  defp type(_caller_module, type) do
    spec =
      quote do
        @type t :: %__MODULE__{value: unquote(type)}
      end

    quote do
      defstruct [:value]

      def __type__ do
        %Type{spec: unquote(Macro.to_string(spec))}
      end
    end
  end
end
