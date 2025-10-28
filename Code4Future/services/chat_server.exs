defmodule ChatServer do

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{usuarios: [], mensajes: []}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}  # Estado inicial: lista vacía de mensajes
  end

  def handle_cast({:unirse, user_id, pid}, state) do
    IO.puts("Usuario #{user_id} se ha unido al chat.")
    new_state = Map.put(state, :usuarios, [{user_id, pid} | Map.get(state, :usuarios)])
    {:noreply, new_state}
  end

  def handle_cast({:desconectarse, user_id, pid}, state) do
    IO.puts("Usuario #{user_id} ha salido del chat.")
    new_usuarios = Map.get(state, :usuarios) |> Enum.reject(fn {id, p} -> id == user_id and p == pid end)
    new_state = Map.put(state, :usuarios, new_usuarios)
    {:noreply, new_state}
  end

  def handle_call(:listar_personas, _from, state) do
    {:reply, Map.get(state, :usuarios) |> Enum.map(fn {user_id, _pid} -> user_id end), state}
  end

  def handle_call({:recibir_mensaje, sender_id, contenido}, _from, state) do
    message = %{sender_id: sender_id, contenido: contenido, timestamp: DateTime.utc_now()}
    new_state = Map.put(state, :mensajes, [message | Map.get(state, :mensajes)])

    broadcast_all(new_state, message)

    {:reply, message, new_state}
  end

  def handle_call(:listar_mensajes_previos, _from, state) do
    {:reply, Map.get(state, :mensajes), state}
  end

  def broadcast_all(state, message) do
    Enum.each(Map.get(state, :usuarios), fn {user_id, pid} ->
      GenServer.cast(pid, {:nuevo_mensaje, user_id, message})
    end)
  end

  def main do

    Node.start(:"chat_server@localhost", :shortnames)
    {:ok, _pid} = ChatServer.start_link()

    IO.puts("Chat server iniciado. Esperando mensajes...")

    :timer.sleep(:infinity)

  end

end

ChatServer.main()
