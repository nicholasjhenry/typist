defmodule Typist.Field do
  @moduledoc """
  A field in a `RecordType`.
  """

  @enforce_keys [:name, :type]
  defstruct [:name, :type]
end

defmodule Typist.RecordType do
  @moduledoc """
  A record type, a product type with named fields.

  Example:

      deftype ProductCode :: String.t
      deftype Product do
        code :: ProductCode.t()
        price :: integer()
      end
  """

  @enforce_keys [:name, :fields]
  defstruct [:name, :fields]

  import Typist.Utils

  def build(caller, {:__block__, _, ast}) do
    current_module = current_module(caller.module)
    type = record_type(current_module, ast)
    fields = Enum.map(type.fields, & &1.name)
    spec = get_spec(type)

    # AST: record, module
    #
    # %{required(:code) => String.t, required(:price) => non_neg_integer()})
    #  {:%{}, [],
    # [
    #   {{:required, [], [:code]},
    #    {{:., [], [{:__aliases__, [alias: false], [:String]}, :t]}, [], []}},
    #   {{:required, [], [:price]}, {:non_neg_integer, [], []}}
    # ]}
    constructor_spec =
      Enum.map(type.fields, fn field ->
        %{name: name, type: {_, x}} = field
        {{:required, [], [name]}, x}
      end)

    quote do
      @enforce_keys unquote(fields)
      defstruct unquote(fields)
      @type t :: %__MODULE__{unquote_splicing(spec)}

      def __type__ do
        unquote(Macro.escape(type))
      end

      @spec new(%{unquote_splicing(constructor_spec)}) :: t
      def new(fields) do
        struct(__MODULE__, fields)
      end
    end
  end

  def build(caller, ast, block) do
    current_module = current_module(caller.module)
    type = record_type(current_module, ast, block)
    fields = Enum.map(type.fields, & &1.name)
    spec = get_spec(type)

    constructor_spec =
      Enum.map(type.fields, fn field ->
        %{name: name, type: {_, x}} = field
        {{:required, [], [name]}, x}
      end)

    quote do
      defmodule unquote(Module.concat([caller.module, type.name])) do
        @enforce_keys unquote(fields)
        defstruct unquote(fields)
        @type t :: %__MODULE__{unquote_splicing(spec)}

        def __type__ do
          unquote(Macro.escape(type))
        end

        @spec new(%{unquote_splicing(constructor_spec)}) :: t
        def new(fields) do
          struct(__MODULE__, fields)
        end
      end
    end
  end

  # Data type: Record, module
  defp record_type(current_module, ast) do
    fields = Enum.map(ast, &build_field/1)
    %Typist.RecordType{name: current_module, fields: fields}
  end

  # Data type: Record, inline
  defp record_type(
         _current_module,
         {:__aliases__, _, [module]},
         {:__block__, _, ast}
       ) do
    record_type(module, ast)
  end

  defp build_field(
         {:"::", _,
          [
            {name, _, nil},
            type_to_be_wrapped
          ]}
       ) do
    type = from_ast(type_to_be_wrapped)
    %Typist.Field{name: name, type: type}
  end

  defp get_spec(record_type) do
    Enum.map(record_type.fields, fn field ->
      field_name_ast = field.name
      type_ast = elem(field.type, 1)

      quote do
        {unquote(field_name_ast), unquote(type_ast)}
      end
    end)
  end
end
