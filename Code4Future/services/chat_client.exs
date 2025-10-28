defmodule ChatClient do

  use GenServer

  def start_link(_) do

    id_random = :rand.uniform(10000)
    {:ok, _pid} = Node.start(:"chat_client#{id_random}@localhost", :shortnames)
    server = :"chat_server@localhost";

    case Node.connect(server) do
      true -> IO.puts("Conectado al chat server.")
      false -> IO.puts("No se pudo conectar al chat server.")
    end

    GenServer.start_link(__MODULE__, %{server: server, en_chat: false}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def unirse_al_chat(user_id) do
    GenServer.cast(__MODULE__, {:unirse, user_id})
  end

  def lista_personas() do
    GenServer.call(__MODULE__, :listar_personas)
  end

  def listar_mensajes_previos() do
    GenServer.call(__MODULE__, :listar_mensajes_previos)
  end

  def enviar_mensaje(sender_id, contenido) do
    GenServer.call(__MODULE__, {:enviar_mensaje, sender_id, contenido})
  end

   # Funciones para controlar el estado del chat
  def entrar_al_chat do
    GenServer.cast(__MODULE__, :entrar_al_chat)
  end

  def salir_del_chat do
    GenServer.cast(__MODULE__, :salir_del_chat)
  end

  def desconectarse(user_id) do
    GenServer.cast(__MODULE__, {:desconectarse, user_id})
  end

  def handle_call(:listar_mensajes_previos, _from, state) do
    respuesta = GenServer.call({ChatServer, state.server}, :listar_mensajes_previos)
    {:reply, respuesta, state}
  end

  def handle_call(:listar_personas, _from, state) do
    respuesta = GenServer.call({ChatServer, state.server}, :listar_personas)
    IO.puts("Las personas conectadas son: " <> Enum.join(respuesta, ", "))
    {:reply, respuesta, state}
  end

  def handle_call({:enviar_mensaje, sender_id, contenido}, _from, state) do
    try do
      # Llamada correcta al servidor remoto
      response = GenServer.call({ChatServer, state.server}, {:recibir_mensaje, sender_id, contenido})
      #IO.puts("✅ Mensaje enviado exitosamente")
      {:reply, {:ok, response}, state}
    rescue
      error ->
        IO.puts("❌ Error al enviar mensaje: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end

  def handle_cast({:unirse, user_id}, state) do
    GenServer.cast({ChatServer, state.server}, {:unirse, user_id, self()})
    {:noreply, state}
  end

  def handle_cast({:nuevo_mensaje, user_id, message}, state) do
    if state.en_chat do
      timestamp = message.timestamp |> DateTime.to_time() |> Time.to_string() |> String.slice(0, 8)
      IO.puts("\n🔔 [#{timestamp}] #{user_id}: #{message.contenido}")
      IO.write("> ")  # Volver a mostrar el prompt
    end
    # Si no está en chat, el mensaje se ignora (no se muestra)
    {:noreply, state}
  end

  def handle_cast({:desconectarse, user_id}, state) do
    GenServer.cast({ChatServer, state.server}, {:desconectarse, user_id, self()})
    {:noreply, state}
  end

  # Controlar el estado del chat
  def handle_cast(:entrar_al_chat, state) do
    new_state = %{state | en_chat: true}
    {:noreply, new_state}
  end

  def handle_cast(:salir_del_chat, state) do
    new_state = %{state | en_chat: false}
    {:noreply, new_state}
  end

  def main do
      {:ok, _pid} = ChatClient.start_link([])
      IO.puts("Chat client iniciado.")

      IO.puts("Escriba su nombre para identificarse en el sistema:")
      nombre = IO.gets("> ") |> String.trim()
      unirse_al_chat(nombre)

      menu(nombre)

  end

  def menu(nombre) do

    IO.puts("MENU PRINCIPAL")
    IO.puts("1. Chat con mi equipo")
    IO.puts("2. Ver anuncios")
    IO.puts("3. Crear salas de discusión")
    IO.puts("4. Unirse a una sala de discusión")
    IO.puts("5. Salir")

    opcion_principal = IO.gets("Seleccione una opción: ") |> String.trim()

    case opcion_principal do

      "1" -> chat_equipo(nombre)
      _ ->
        IO.puts("En desarrollo...")
        menu(nombre)

    end


  end

  def chat_equipo(nombre) do

    IO.puts("MENU DEL CHAT")
    IO.puts("1. Listar personas conectadas")
    IO.puts("2. Enviar mensaje")
    IO.puts("3. Salir")

    opcion = IO.gets("Seleccione una opción: ") |> String.trim()
    case opcion do
      "1" ->
        lista_personas()
        chat_equipo(nombre)
      "2" ->
        entrar_al_chat()
        listar_mensajes_previos()
        |> Enum.reverse()
        |> Enum.each(fn msg ->
          IO.puts("[#{msg.timestamp}] #{msg.sender_id}: #{msg.contenido}")
        end)
        chat_loop()
        chat_equipo(nombre)
      "3" ->
        desconectarse(nombre)
        IO.puts("Saliendo del chat. ¡Hasta luego!")
      _ ->
        IO.puts("Opción inválida. Intente de nuevo.")
        chat_equipo(nombre)
    end

  end

  def chat_loop do
    IO.puts("Escriba su mensaje o salir para terminar el chat:")
    mensaje = IO.gets("> ") |> String.trim()

    case mensaje do
      "salir" ->
        salir_del_chat()
        IO.puts("Saliendo del chat.")
      "" ->
        IO.puts("Mensaje vacío. Intente de nuevo.")
        chat_loop()
      _ ->
        enviar_mensaje("Usuario", mensaje)
        chat_loop()
    end

  end

end

ChatClient.main()
