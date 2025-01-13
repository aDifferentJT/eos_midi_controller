defmodule EosMidiController.MixProject do
  use Mix.Project

  def project do
    [
      app: :eos_midi_controller,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        flags: [
          :error_handling,
          :race_conditions,
          :unknown,
          :unmatched_returns,
          :overspecs,
          :no_match
        ]
      ],
      releases: [eos_midi_controller: []],
      rustler_precompiled: [force_build: [midiex: true]],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {EosMidiController, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:midiex, git: "https://github.com/SocksHelp/midiex", branch: "update-nif-for-windows"},
      {:rustler, "~> 0.34.0", runtime: false},
    ]
  end
end
