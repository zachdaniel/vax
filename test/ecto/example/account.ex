defmodule VaxTest.Ecto.Example.Account do
  @moduledoc """
  Example `Account` schema.
  """

  use Vax.Ecto.Schema

  import Ecto.Changeset
  alias __MODULE__

  schema "account" do
    # field :id, :integer, :guid, :primary-key
    # field :name, :string, :lww
    field :balance, Types.Counter #, min: 0
  end

  def changeset(%Account{} = account, attrs) do
    account
    |> cast(attrs, [:balance])
  end
end
