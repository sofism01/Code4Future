defmodule ChatClient do

  use GenServer

  def start_link(_) do

    {:ok, _pid} = Node.start(:"chat_client@localhost", :shortnames)
    server = :"chat_server@localhost";

    case Node.connect(server) do
      true -> IO.puts("Conectado al chat server.")
      false -> IO.puts("No se pudo conectar al chat server.")
    end

    GenServer.start_link(__MODULE__, server, name: __MODULE__)
  end

  def init(server_node) do
    {:ok, server_node}
  end

  def unirse_al_chat(user_id) do
    GenServer.cast(__MODULE__, {:unirse, user_id})
  end

  def lista_personas() do
    GenServer.call(__MODULE__, :listar_personas)
  end

  def enviar_mensaje(sender_id, contenido) do
    GenServer.call(__MODULE__, {:enviar_mensaje, sender_id, contenido})
  end

  def handle_call(:listar_personas, _from, state) do
    respuesta = GenServer.call({ChatServer, state}, :listar_personas)
    IO.puts("Las personas conectadas son: " <> Enum.join(respuesta, ", "))
    {:reply, respuesta, state}
  end

  def handle_call({:enviar_mensaje, sender_id, contenido}, _from, server_node) do
    try do
      # Llamada correcta al servidor remoto
      response = GenServer.call({ChatServer, server_node}, {:recibir_mensaje, sender_id, contenido})
      IO.puts("✅ Mensaje enviado exitosamente")
      {:reply, {:ok, response}, server_node}
    rescue
      error ->
        IO.puts("❌ Error al enviar mensaje: #{inspect(error)}")
        {:reply, {:error, error}, server_node}
    end
  end

  def handle_cast({:unirse, user_id}, server_node) do
    GenServer.cast({ChatServer, server_node}, {:unirse, user_id})
    {:noreply, server_node}
  end

  def main do
      {:ok, _pid} = ChatClient.start_link([])
      IO.puts("Chat client iniciado.")

      unirse_al_chat("pepito")
      lista_personas()

  end

end

ChatClient.main()
