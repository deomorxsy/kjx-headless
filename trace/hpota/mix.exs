defmodule Hpota.MixProject do
  use Mix.Project

  @source_url "https://github.com/deomorxsy/kjx-headless/tree/main/trace/hpota"
  @version "0.1.0"

  def project do
    [
      app: :hpota,
      name: "Hpota",
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs(),
      aliases: aliases(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      # mod: {Hpota.Application, []}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def package do
    [
      description: "Writing eBPF with Elixir!",
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["deomorxsy"],
      licenses: ["GPL-3.0-only"],
      links: %{
        "Github" => @source_url,
      },
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:honey, git: "https://github.com/lac-dcc/honey-potion/", submodules: true}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp aliases do
    [
      # The Honey.Mix.Tasks.CompileBPF.run function currently has no use. It has been left as a reference of
      # where code can be added for it to be executed before the compilation step of Elixir.
      #compile: ["compile", &Honey.Mix.Tasks.CompileBPF.run/1]
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [title: "Changelog"],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      homepage_url: @source_url,
      source_url: @source_url,
      source_ref: @version,
      logo: "assets/honey.png",
      assets: "assets",
      formatters: ["html"]
    ]
  end

end
