defmodule Domain.Message do
  @moduledoc """
  Representa un mensaje en el chat de un equipo.
  """

  defstruct [:id, :sender_id, :team_id, :contenido, :timestamp]

  @doc """
  Crea un nuevo mensaje en el chat.
  """
  def nuevo_mensaje(sender_id, team_id, contenido) do
    %__MODULE__{
      id: System.unique_integer([:positive]),
      sender_id: sender_id,
      team_id: team_id,
      contenido: contenido,
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Obtiene información formateada del mensaje.
  """
  def formato_mensaje(message) do
    formatted_time = format_timestamp(message.timestamp)
    "[#{formatted_time}] Usuario #{message.sender_id}: #{message.contenido}"
  end

  @doc """
  Verifica si un mensaje pertenece a un equipo específico.
  """
  def pertenece_a_equipo?(message, team_id) do
    message.team_id == team_id
  end

  @doc """
  Verifica si un mensaje fue enviado por un usuario específico.
  """
  def enviado_por_usuario?(message, user_id) do
    message.sender_id == user_id
  end

  @doc """
  Obtiene información resumida del mensaje.
  """
  def obtener_info_mensaje(message) do
    %{
      id: message.id,
      sender_id: message.sender_id,
      team_id: message.team_id,
      contenido: String.slice(message.contenido, 0, 50) <> "...",
      timestamp: message.timestamp
    }
  end

  @doc """
  Verifica si el mensaje es reciente (menos de 1 hora).
  """
  def es_reciente?(message) do
    hora_atras = DateTime.add(DateTime.utc_now(), -3600, :second)
    DateTime.compare(message.timestamp, hora_atras) == :gt
  end

  # Función privada para formatear timestamp
  defp formatear_timestamp(timestamp) do
    timestamp
    |> DateTime.to_time()
    |> Time.to_string()
    |> String.slice(0, 8)  # HH:MM:SS
  end
end
