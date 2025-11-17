defmodule ChatServer do
  @moduledoc """
  Módulo servidor para gestionar el chat con múltiples salas.
  """
  use GenServer

  @default_room :equipo

  # ======== INICIO Y ESTADO INICIAL ========

  def start_link do
    initial_state = %{
      salas: %{
        @default_room => %{usuarios: [], mensajes: []}
      },
      anuncios: []
    }

    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  # ======== HANDLE CALLS ========

  # Listar personas
  def handle_call({:listar_personas, sala}, _from, state) do
    case Map.get(state.salas, sala) do
      nil -> {:reply, {:error, :sala_no_existe}, state}
      %{usuarios: usuarios} ->
        {:reply, {:ok, Enum.map(usuarios, fn {user_id, _pid} -> user_id end)}, state}
    end
  end

  def handle_call(:listar_personas, from, state),
    do: handle_call({:listar_personas, @default_room}, from, state)

  # Recibir mensaje
  def handle_call({:recibir_mensaje, sala, sender_id, contenido}, _from, state) do
    case Map.get(state.salas, sala) do
      nil ->
        {:reply, {:error, :sala_no_existe}, state}

      %{usuarios: usuarios, mensajes: mensajes} ->
        message = %{
          sender_id: sender_id,
          contenido: contenido,
          timestamp: DateTime.utc_now()
        }

        new_mensajes = [message | mensajes]
        new_state = put_in(state, [:salas, sala, :mensajes], new_mensajes)

        broadcast_all(usuarios, sala, message)
        {:reply, {:ok, message}, new_state}
    end
  end

  def handle_call({:recibir_mensaje, sender_id, contenido}, from, state),
    do: handle_call({:recibir_mensaje, @default_room, sender_id, contenido}, from, state)

  # Listar mensajes previos
  def handle_call({:listar_mensajes_previos, sala}, _from, state) do
    case Map.get(state.salas, sala) do
      nil -> {:reply, {:error, :sala_no_existe}, state}
      %{mensajes: mensajes} -> {:reply, {:ok, mensajes}, state}
    end
  end

  def handle_call(:listar_mensajes_previos, from, state),
    do: handle_call({:listar_mensajes_previos, @default_room}, from, state)

  # Consultar anuncios
  def handle_call(:consultar_anuncios, _from, state),
    do: {:reply, {:ok, state.anuncios}, state}

  def handle_call(:listar_salas, _from, state) do
    salas = Enum.filter(state.salas, fn {nombre, _value} -> nombre != @default_room end )
    |> Enum.map(fn {nombre, _value} -> nombre end)
    {:reply, salas, state}
  end

  # Unirse a sala existente
  def handle_call({:unirse, sala, user_id, pid}, _from, state) do
    case Map.get(state.salas, sala) do
      nil ->
        IO.puts("Error: la sala #{sala} no existe. El usuario #{user_id} no puede unirse.")
        {:reply, false, state}

      %{usuarios: usuarios} ->
        IO.puts("Usuario #{user_id} se ha unido a la sala #{sala}.")
        new_usuarios = [{user_id, pid} | usuarios]
        new_state = put_in(state, [:salas, sala, :usuarios], new_usuarios)
        {:reply, true, new_state}
    end
  end

  def handle_call({:unirse, user_id, pid}, from, state),
    do: handle_call({:unirse, @default_room, user_id, pid}, from, state)


  # ======== HANDLE CASTS ========

  # Crear sala
  def handle_cast({:crear_sala, sala}, state) do
    if Map.has_key?(state.salas, sala) do
      IO.puts("La sala #{sala} ya existe.")
      {:noreply, state}
    else
      IO.puts("Sala #{sala} creada correctamente.")
      new_state = put_in(state, [:salas, sala], %{usuarios: [], mensajes: []})
      {:noreply, new_state}
    end
  end

  # Crear anuncio (global)
  def handle_cast({:crear_anuncio, mensaje}, state) do
    IO.puts("Anuncio creado: #{mensaje}")
    message = %{sender_id: "admin", contenido: mensaje, timestamp: DateTime.utc_now()}
    new_anuncios = [message | state.anuncios]
    new_state = %{state | anuncios: new_anuncios}

    Enum.each(state.salas, fn {_nombre, datos} ->
      broadcast_all(datos.usuarios, :anuncio, message)
    end)

    {:noreply, new_state}
  end


  # Desconectarse de sala
  def handle_cast({:desconectarse, sala, user_id, pid}, state) do
    case Map.get(state.salas, sala) do
      nil ->
        IO.puts("No se puede salir: la sala #{sala} no existe.")
        {:noreply, state}

      %{usuarios: usuarios} ->
        IO.puts("Usuario #{user_id} ha salido de la sala #{sala}.")
        new_usuarios = Enum.reject(usuarios, fn {id, p} -> id == user_id and p == pid end)
        new_state = put_in(state, [:salas, sala, :usuarios], new_usuarios)
        {:noreply, new_state}
    end
  end

  def handle_cast({:desconectarse, user_id, pid}, state),
    do: handle_cast({:desconectarse, @default_room, user_id, pid}, state)

  # ======== BROADCAST ========

  def broadcast_all(usuarios, tipo, message) do
    Enum.each(usuarios, fn {_user_id, pid} ->
      GenServer.cast(pid, {:nuevo_mensaje, tipo, message})
    end)
  end

  # ======== MAIN ========

  def main do
    Node.start(:"chat_server@localhost", :shortnames)
    {:ok, _pid} = ChatServer.start_link()
    IO.puts("Chat server iniciado. Sala principal: #{@default_room}")
    :timer.sleep(:infinity)
  end
end

ChatServer.main()
