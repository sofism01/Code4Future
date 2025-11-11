defmodule ChatServer do

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{usuarios: [], mensajes: []}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}  # Estado inicial: lista vacía de mensajes
  end

end
