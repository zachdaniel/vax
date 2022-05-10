defmodule Vax.Types.Counter do
  @moduledoc """
  Type for CRDT counters
  """
  use Vax.Type

  @impl Ecto.Type
  def type(), do: :counter

  @impl Ecto.Type
  def load(value) do
    {:ok, value}
  end

  @impl Ecto.Type
  def dump(value) do
    {:ok, value}
  end

  @impl Ecto.Type
  def cast(value) when is_integer(value) do
    {:ok, value}
  end

  def cast(value) when is_binary(value) do
    try do
      {:ok, String.to_integer(value)}
    rescue
      _ -> :error
    end
  end

  def cast(_value) do
    :error
  end

  @impl Vax.Type
  def antidote_crdt_type, do: :antidote_crdt_counter_pn

  @impl Vax.Type
  def compute_change(antidotec_counter, new_value) do
    old_value = :antidotec_counter.value(antidotec_counter) || 0

    if old_value > new_value do
      :antidotec_counter.decrement(old_value - new_value, antidotec_counter)
    else
      :antidotec_counter.increment(new_value - old_value, antidotec_counter)
    end
  end
end
