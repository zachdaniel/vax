defmodule VaxTest.Ecto.Example do
  @moduledoc """
  Work with the example data model using the adapted Repo.
  """

  alias VaxTest.Ecto.Example.Repo
  alias VaxTest.Ecto.Example.Account

  @default_attrs %{
    balance: 0
  }

  def init_account(attrs \\ @default_attrs) do
    %Account{}
    |> Account.changeset(attrs)
  end

  def create_account(attrs \\ @default_attrs) do
    attrs
    |> init_account()
    |> Repo.insert()
  end
end
