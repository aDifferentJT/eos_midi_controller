defmodule EosMidiController do
  @moduledoc """
  Documentation for `EosMidiController`.
  """

  def start(_type, _args) do
    children = [
      Nektar,
      {Eos, {127, 0, 0, 1}}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
