defmodule Eos do
  use GenServer
  require Logger

  @port 8000

  def fader_page(page) do
    GenServer.cast(__MODULE__, {:fader_page, page})
  end

  def move_fader(channel, value) do
    GenServer.cast(__MODULE__, {:move_fader, channel, value})
  end

  def move_wheel(index, value) do
    GenServer.cast(__MODULE__, {:move_wheel, index, value})
  end

  defp send(address, args, %{socket: socket, ip: ip}) do
    :gen_udp.send(
      socket,
      ip,
      @port,
      Osc.encode_message(address, args)
    )
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl GenServer
  def init(ip) do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: true])

    {:ok, %{socket: socket, ip: ip}}
  end

  @impl GenServer
  def handle_cast({:fader_page, page}, state) do
    :ok = send("/eos/fader/1/config/#{page}/10", [], state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:move_fader, channel, value}, state) do
    :ok = send("/eos/fader/1/#{channel}", [value], state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:move_wheel, index, value}, state) do
    :ok = send("/eos/active/wheel/#{index}", [value], state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:custom_send, address, values}, state) do
    :ok = send(address, values, state)

    {:noreply, state}
  end
end
