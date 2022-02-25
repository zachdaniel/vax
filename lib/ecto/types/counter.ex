defmodule Vax.Ecto.Types.Counter do
  @moduledoc """
  Wrap the Antidote Bounded Counter CRDT in an Ecto type.
  """

  use Ecto.Type

  # XXX where does this impact us? Does it impact us?
  def type, do: :map

  # XXX what do we accept being cast?
  def cast(value) do
    IO.inspect {
      :counter,
      :cast,
      value
    }

    {:ok, value}
  end

  # # Everything else is a failure though
  # def cast(_), do: :error

  # XXX load data from the database. Here we're expecting it in the
  # form of a map. What do we actually get -- a CRDT object?
  def load(data) do # when is_map(data) do
    IO.inspect {
      :counter,
      :load,
      data
    }

    # data =
    #   for {key, val} <- data do
    #     {String.to_existing_atom(key), val}
    #   end
    # {:ok, struct!(URI, data)}

    # :antidotec_counter.value(raw)

    {:ok, data}
  end

  # When dumping data to the database, we *expect* what?
  # A CRDT struct? Operations?
  def dump(value) do
    IO.inspect {
      :counter,
      :dump,
      value
    }

    {:ok, value}
  end

  # # Any value could be inserted into the schema struct at runtime,
  # # so guard against that.
  # def dump(_), do: :error
end
