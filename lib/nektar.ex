defmodule Nektar do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl GenServer
  def init([]) do
    ports = Midiex.ports()

    [input | _] =
      ports
      |> Enum.filter(fn port ->
        port.direction == :input && String.contains?(port.name, "PANORAMA P1")
      end)

    [output | _] =
      ports
      |> Enum.filter(fn port ->
        port.direction == :output && String.contains?(port.name, "PANORAMA P1")
      end)

    :ok = Midiex.subscribe(input)
    output = Midiex.open(output)

    {:ok, %{input: input, output: output}}
  end

  def decode_midi_command({:control_change, _, controller, value}) do
    case <<controller::7>> do
      <<3::7>> ->
        {:ch_fader, 9, value}

      <<1::2, type::2, channel::3>> ->
        type =
          case type do
            0 -> :ch_enc
            1 -> :ch_fader
            2 -> :aux_enc
            3 -> :ch_button
          end

        value =
          case type do
            :ch_enc ->
              case <<value::7>> do
                <<0::1, value::6>> -> value
                <<1::1, value::6>> -> -value
              end

            :ch_fader ->
              value

            :aux_enc ->
              case <<value::7>> do
                <<0::1, value::6>> -> value
                <<1::1, value::6>> -> -value
              end

            :ch_button ->
              value > 0
          end

        {type, channel, value}

      _ ->
        value = value > 0

        button =
          cond do
            controller == 103 -> :track_minus
            controller == 104 -> :track_plus
            controller == 105 -> :patch_minus
            controller == 106 -> :patch_plus
            controller == 107 -> :view
            controller in 108..113 -> {:f, controller - 102}
            controller in 114..118 -> {:f, controller - 113}
          end

        {button, value}
    end
  end

  def decode_midi_command(command) do
    {:unknown, command}
  end

  def handle_event({{:f, index}, true}, state) do
    Eos.fader_page(index)

    {:noreply, state}
  end

  def handle_event({:ch_fader, channel, value}, state) do
    Eos.move_fader(channel + 1, value / 127)

    {:noreply, state}
  end

  def handle_event({:aux_enc, channel, value}, state) do
    Eos.move_wheel(channel + 1, value)

    {:noreply, state}
  end

  def handle_event({:ch_button, channel, true}, state) do
    Eos.move_fader(channel + 1, 1)

    {:noreply, state}
  end

  def handle_event({:ch_button, channel, false}, state) do
    Eos.move_fader(channel + 1, 0)

    {:noreply, state}
  end

  def handle_event(_msg, state) do
    {:noreply, state}
  end

  def handle_midi_command(command, state) do
    handle_event(decode_midi_command(command), state)
  end

  @impl GenServer
  def handle_info(%Midiex.MidiMessage{data: data}, state) do
    {command, ""} = Midi.decode_command(:erlang.list_to_binary(data))
    handle_midi_command(command, state)
  end
end
