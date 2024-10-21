defmodule BinStruct.Macro.Structs.ParseCheckpointProduceConsumeInfo do


  alias BinStruct.Macro.Structs.ParseCheckpointProduceConsumeInfo

  @type t :: %ParseCheckpointConsumeInfo {
               checkpoint_index: integer(),
               produce_fields: list(
                 Field.t()
               ),
               consume_dependencies: list(
                 DependencyOnField.t()
               )
             }

  defstruct [
    :checkpoint_index,
    :produce_fields,
    :consume_dependencies
  ]


end
