defmodule Vax.MixProject do
  use Mix.Project

  def project do
    [
      app: :vax,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env),
      package: package()
    ] ++ docs()
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:antidote_pb_codec, git: "https://github.com/vaxine-io/antidote_pb_codec.git", override: true},
      {:antidotec_pb, git: "https://github.com/vaxine-io/antidote-erlang-client.git"},
      {:ecto, "~> 3.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      name: "Vax",
      description: "Data access library for the Vaxine database platform.",
      source_url: "https://github.com/vaxine-io/vax",
      homepage_url: "https://vaxine.io"
    ]
  end

  # Ensures `test/**/*.ex` files are read during tests.
  defp elixirc_paths(:test), do: ["lib", "test/ecto"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      name: "vax",
      maintainers: ["James Arthur"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/vaxine-io/vax",
        "Vaxine" => "https://vaxine.io"
      }
    ]
  end
end
