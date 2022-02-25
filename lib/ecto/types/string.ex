defmodule Vax.Ecto.Types.String do
  @moduledoc """
  String defaults to a last-write-wins register.

  XXX atm we don't provide a `String` type -- we adapt the
  load and dump functions for the built in ecto type.
  """

  def dump(value) do
    IO.inspect {
      :string,
      :dump,
      value
    }

    value
  end

  def load(value) do
    IO.inspect {
      :string,
      :load,
      value
    }

    # :antidotec_reg.value(raw)

    value
  end
end
