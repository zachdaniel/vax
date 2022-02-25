defmodule Vax.Ecto.Schema do
  @moduledoc """
  Use this instead of `Ecto.Schema` to set the right ID type defaults.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      alias Vax.Ecto.Types

      # XXX autogenerate or not?
      @primary_key {:id, :binary_id, autogenerate: false}
      @foreign_key_type :binary_id
    end
  end
end
