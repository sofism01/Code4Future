defmodule ChatServer do

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{usuarios: [], mensajes: []}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}  # Estado inicial: lista vacía de mensajes
  end

  def handle_cast({:unirse, user_id}, state) do
    IO.puts("Usuario #{user_id} se ha unido al chat.")
    new_state = Map.put(state, :usuarios, [user_id | Map.get(state, :usuarios)])
    {:noreply, new_state}
  end

  def handle_call(:listar_personas, _from, state) do
    {:reply, Map.get(state, :usuarios), state}
  end

  def handle_call({:recibir_mensaje, sender_id, contenido}, _from, state) do
    message = %{sender_id: sender_id, contenido: contenido, timestamp: DateTime.utc_now()}
    new_state = Map.put(state, :mensajes, [message | Map.get(state, :mensajes)])
    {:reply, message, new_state}
  end

  def main do

    Node.start(:"chat_server@localhost", :shortnames)
    {:ok, _pid} = ChatServer.start_link()

    IO.puts("Chat server iniciado. Esperando mensajes...")

    :timer.sleep(:infinity)

  end

end

ChatServer.main()
