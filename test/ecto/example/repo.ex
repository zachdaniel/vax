defmodule VaxTest.Ecto.Example.Repo do
  @moduledoc """
  Example repo module that uses the Vax Ecto adapter,
  defined here so we can test it.
  """

  use Ecto.Repo,
    adapter: Vax.Ecto.Adapter,
    database: "vax_ecto_test_repo",
    otp_app: :vax
end
