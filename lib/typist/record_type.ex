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
  defmodule Field do
    @moduledoc """
    A field in a `RecordType`.
    """

    @enforce_keys [:name, :type]
    defstruct [:name, :type]
  end

  @enforce_keys [:name, :fields]
  defstruct [:name, :fields]

  import Typist.Utils

  def maybe_build(module, ast, block) do
    current_module = current_module(module)

    case maybe_type(current_module, ast, block) do
      :none ->
        :none

      type ->
        spec = spec(type)

        build_ast(current_module, module, type, spec)
    end
  end

  # Data type: record, module
  #
  # defmodule Product do
  #   deftype do
  #     code :: ProductCode.t()
  #     price :: float()
  #   end
  # end
  #
  # matches: do, ... end
  defp maybe_type(current_module, :none, {:__block__, _, block}) do
    fields = Enum.map(block, &build_field/1)
    %Typist.RecordType{name: current_module, fields: fields}
  end

  # Data type: record, inline
  #
  # deftype Product do
  #   code :: ProductCode.t()
  #   price :: float()
  # end
  #
  # matches: deftype Product do, ... end
  defp maybe_type(_current_module, {:__aliases__, _, [module]}, block) do
    maybe_type(module, :none, block)
  end

  defp maybe_type(_current_module, _ast, _block), do: :none

  defp build_field(
         {:"::", _,
          [
            {name, _, nil},
            type_to_be_wrapped
          ]}
       ) do
    type = from_ast(type_to_be_wrapped)
    %Field{name: name, type: type}
  end

  defp spec(record_type) do
    Enum.map(record_type.fields, fn field ->
      field_name_ast = field.name
      type_ast = elem(field.type, 1)

      quote do
        {unquote(field_name_ast), unquote(type_ast)}
      end
    end)
  end

  defp build_ast(current_module, module, type, spec) do
    if module_defined?(current_module, type.name) do
      do_build_ast(type, spec)
    else
      quote do
        defmodule unquote(Module.concat([module, type.name])) do
          unquote(do_build_ast(type, spec))
        end
      end
    end
  end

  defp do_build_ast(type, spec) do
    fields = Enum.map(type.fields, & &1.name)

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
end
