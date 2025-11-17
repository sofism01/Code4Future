defmodule ChatClient do
  @moduledoc """
  Módulo cliente para interactuar con el ChatServer.
  """
  use GenServer

  @default_room :equipo

  def start_link(_) do
    id_random = :rand.uniform(10000)
    {:ok, _pid} = Node.start(:"chat_client#{id_random}@localhost", :shortnames)
    server = :"chat_server@localhost"

    case Node.connect(server) do
      true -> IO.puts("Conectado al chat server.")
      false -> IO.puts("No se pudo conectar al chat server.")
    end

    GenServer.start_link(__MODULE__, %{server: server, en_chat: false, user_id: "", sala_actual: @default_room}, name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  # ======================= INTERFAZ PÚBLICA =======================

  def unirse_al_chat(user_id), do: GenServer.cast(__MODULE__, {:unirse, user_id})
  def lista_personas(), do: GenServer.call(__MODULE__, :listar_personas)
  def listar_mensajes_previos(), do: GenServer.call(__MODULE__, :listar_mensajes_previos)
  def enviar_mensaje(contenido), do: GenServer.call(__MODULE__, {:enviar_mensaje, contenido})
  def entrar_al_chat(), do: GenServer.cast(__MODULE__, :entrar_al_chat)
  def salir_del_chat(), do: GenServer.cast(__MODULE__, :salir_del_chat)
  def desconectarse(user_id), do: GenServer.cast(__MODULE__, {:desconectarse, user_id})
  def crear_anuncio(mensaje), do: GenServer.cast(__MODULE__, {:crear_anuncio, mensaje})

  # ==== NUEVOS COMANDOS PARA SALAS ====
  def crear_sala(nombre), do: GenServer.cast(__MODULE__, {:crear_sala, nombre})
  def listar_salas(), do: GenServer.call(__MODULE__, :listar_salas)
  def unirse_a_sala(nombre), do: GenServer.call(__MODULE__, {:unirse_a_sala, nombre})

  # ======================= CALLBACKS =======================

  def handle_call(:listar_mensajes_previos, _from, state) do
    respuesta = GenServer.call({ChatServer, state.server}, {:listar_mensajes_previos, state.sala_actual})
    case respuesta do
      {:ok, mensajes} -> {:reply, mensajes, state}
      {:error, :sala_no_existe} ->
        IO.puts("La sala #{state.sala_actual} no existe.")
        {:reply, [], state}
    end
  end

  def handle_call(:listar_personas, _from, state) do
    respuesta = GenServer.call({ChatServer, state.server}, {:listar_personas, state.sala_actual})
    case respuesta do
      {:ok, lista} ->
        IO.puts("Personas en la sala #{state.sala_actual}: " <> Enum.join(lista, ", "))
        {:reply, lista, state}
      {:error, :sala_no_existe} ->
        IO.puts("La sala #{state.sala_actual} no existe.")
        {:reply, [], state}
    end
  end

  def handle_call({:enviar_mensaje, contenido}, _from, state) do
    try do
      response = GenServer.call({ChatServer, state.server}, {:recibir_mensaje, state.sala_actual, state.user_id, contenido})
      {:reply, response, state}
    rescue
      error ->
        IO.puts("Error al enviar mensaje: #{inspect(error)}")
        {:reply, {:error, error}, state}
    end
  end

  def handle_call(:listar_salas, _from, state) do
    salas = GenServer.call({ChatServer, state.server}, :listar_salas)
    IO.puts("Salas disponibles: " <> Enum.join(Enum.map(salas, &Atom.to_string/1), ", "))
    {:reply, salas, state}
  end

  def handle_call({:unirse_a_sala, nombre}, _from, state) do
    sala_atom = String.to_atom(nombre)
    respuesta = GenServer.call({ChatServer, state.server}, {:unirse, sala_atom, state.user_id, self()})
    case respuesta do
      true ->
        IO.puts("Te has unido a la sala #{nombre}.")
        {:reply, :ok, %{state | sala_actual: sala_atom}}

      _ ->
        IO.puts("No se pudo unir a la sala #{nombre}.")
        {:reply, :error, state}
    end
  end

  # ======================= CASTS =======================

  def handle_cast({:unirse, user_id}, state) do
    GenServer.call({ChatServer, state.server}, {:unirse, state.sala_actual, user_id, self()})
    IO.puts("Te has unido a la sala #{state.sala_actual}.")
    {:noreply, %{state | user_id: user_id}}
  end

  def handle_cast({:nuevo_mensaje, tipo, message}, state) do
    if state.en_chat do
      timestamp = message.timestamp |> DateTime.to_time() |> Time.to_string() |> String.slice(0, 8)
      tipo_str = if tipo == :anuncio, do: "ANUNCIO", else: "MENSAJE"
      IO.puts("\n#{tipo_str} [#{timestamp}] #{message.sender_id}: #{message.contenido}")
      IO.write("> ")
    end
    {:noreply, state}
  end

  def handle_cast({:crear_anuncio, mensaje}, state) do
    GenServer.cast({ChatServer, state.server}, {:crear_anuncio, mensaje})
    {:noreply, state}
  end

  def handle_cast({:desconectarse, user_id}, state) do
    GenServer.cast({ChatServer, state.server}, {:desconectarse, state.sala_actual, user_id, self()})
    {:noreply, state}
  end

  def handle_cast(:entrar_al_chat, state), do: {:noreply, %{state | en_chat: true}}
  def handle_cast(:salir_del_chat, state), do: {:noreply, %{state | en_chat: false}}

  def handle_cast({:crear_sala, nombre}, state) do
    GenServer.cast({ChatServer, state.server}, {:crear_sala, String.to_atom(nombre)})
    {:noreply, state}
  end

  # ======================= INTERFAZ DE CONSOLA =======================

  def main do
    {:ok, _pid} = ChatClient.start_link([])
    IO.puts("Chat client iniciado.")

    IO.puts("Escriba su nombre para identificarse en el sistema:")
    nombre = IO.gets("> ") |> String.trim()
    iniciar(nombre)
  end

  def iniciar("admin") do
    IO.puts("Bienvenido, admin. Escribe un mensaje de anuncio global:")
    mensaje = IO.gets("> ") |> String.trim()
    crear_anuncio(mensaje)
  end

  def iniciar(nombre) do
    unirse_al_chat(nombre)
    menu(nombre)
  end

  def menu(nombre) do
    IO.puts("\n===== MENÚ PRINCIPAL =====")
    IO.puts("1. Chat del equipo")
    IO.puts("2. Salas de discusión")
    IO.puts("3. Salir")
    opcion = IO.gets("Seleccione una opción: ") |> String.trim()

    case opcion do
      "1" -> chat_equipo(nombre)
      "2" -> salas_discusion(nombre)
      "3" -> desconectarse(nombre); IO.puts("Hasta luego.")
      _ -> IO.puts("Opción inválida."); menu(nombre)
    end
  end

  # === MENÚ DE SALAS ===
  def salas_discusion(nombre) do
    IO.puts("\n===== SALAS DE DISCUSIÓN =====")
    IO.puts("1. Crear una sala")
    IO.puts("2. Listar salas disponibles")
    IO.puts("3. Unirse a una sala existente")
    IO.puts("4. Volver al menú principal")
    opcion = IO.gets("Seleccione una opción: ") |> String.trim()

    case opcion do
      "1" ->
        IO.puts("Ingrese el nombre de la nueva sala:")
        nombre_sala = IO.gets("> ") |> String.trim()
        crear_sala(nombre_sala)
        salas_discusion(nombre)

      "2" ->
        listar_salas()
        salas_discusion(nombre)

      "3" ->
        IO.puts("Ingrese el nombre de la sala a la que desea unirse:")
        nombre_sala = IO.gets("> ") |> String.trim()

        unirse_a_sala(nombre_sala)

        #LLamar chat_equipo solamente si la función unirse_a_sala fue exitosa
        chat_equipo(nombre) # reusa el chat general pero en otra sala

      "4" -> menu(nombre)

      _ ->
        IO.puts("Opción inválida.")
        salas_discusion(nombre)
    end
  end

  # === CHAT DEL EQUIPO O DE SALA ACTUAL ===
  def chat_equipo(nombre) do
    IO.puts("\n===== CHAT (sala activa) =====")
    IO.puts("1. Listar personas conectadas")
    IO.puts("2. Entrar al chat")
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
        IO.puts("Saliendo del chat...")

      _ ->
        IO.puts("Opción inválida.")
        chat_equipo(nombre)
    end
  end

  def chat_loop do
    IO.puts("Escriba su mensaje o 'salir' para terminar el chat:")
    mensaje = IO.gets("> ") |> String.trim()
    case mensaje do
      "salir" -> salir_del_chat(); IO.puts("Saliendo del chat.")
      "" -> IO.puts("Mensaje vacío."); chat_loop()
      _ -> enviar_mensaje(mensaje); chat_loop()
    end
  end
end

ChatClient.main()
