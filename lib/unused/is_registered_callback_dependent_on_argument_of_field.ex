defmodule BinStruct.Macro.IsRegisteredCallbackDependentOnArgumentOfField do

  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.Field

  def is_registered_callback_dependent_on_argument_of_field(registered_callback, field) do

    %RegisteredCallback{
      arguments: arguments
    } = registered_callback

    Enum.any?(
      arguments,
      fn %RegisteredCallbackFieldArgument{} = argument ->

        %RegisteredCallbackFieldArgument{ field: registered_callback_field_dependency } = argument

        %Field{ name: registered_callback_field_dependency_name  } = registered_callback_field_dependency
        %Field{ name: maybe_depends_on_field_name  } = field

        registered_callback_field_dependency_name == maybe_depends_on_field_name

      end
    )

  end

end
