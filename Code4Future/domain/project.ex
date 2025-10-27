defmodule Domain.Project do
  @moduledoc """
  Representa un proyecto desarrollado durante la hackathon.
  """

  defstruct [:id, :team_id, :titulo, :descripcion, :categoria, :progreso, :feedbacks]

  @doc """
  Crea un nuevo proyecto para un equipo específico.
  """
  def crear_proyecto(team_id, titulo, descripcion, categoria) do
    %__MODULE__{
      id: System.unique_integer([:positive]),
      team_id: team_id,
      titulo: titulo,
      descripcion: descripcion,
      categoria: categoria,
      progreso: 0,
      feedbacks: []
    }
  end

  @doc """
  Actualiza el progreso del proyecto (porcentaje entre 0 y 100).
  """
  def actualizar_progreso(proyecto, progreso) when progreso >= 0 and progreso <= 100 do
    %{proyecto | progreso: progreso}
  end

  def actualizar_progreso(proyecto, _invalid_progress) do
    # Si el progreso no está entre 0 y 100, no hace cambios
    proyecto
  end

  @doc """
  Agrega feedback de un mentor al proyecto.
  """
  def agregar_feedback(proyecto, mentor_id, feedback) do
    nuevo_feedback = %{
      mentor_id: mentor_id,
      feedback: feedback,
      timestamp: DateTime.utc_now()
    }

    %{proyecto | feedbacks: [nuevo_feedback | proyecto.feedbacks]}
  end

  @doc """
  Obtiene todos los feedbacks del proyecto ordenados por fecha.
  """
  def obtener_feedbacks(proyecto) do
    proyecto.feedbacks
    |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})
  end

  @doc """
  Obtiene información resumida del proyecto.
  """
  def obtener_resumen_proyecto(proyecto) do
    %{
      id: proyecto.id,
      team_id: proyecto.team_id,
      title: proyecto.title,
      category: proyecto.category,
      progress: "#{proyecto.progreso}%",
      total_feedbacks: length(proyecto.feedbacks),
      status: get_status(proyecto.progreso)
    }
  end

  # Función privada para determinar el estado basado en el progreso
  defp get_status(progreso) when progreso == 0, do: "No iniciado"
  defp get_status(progreso) when progreso < 25, do: "Iniciado"
  defp get_status(progreso) when progreso < 50, do: "En progreso"
  defp get_status(progreso) when progreso < 75, do: "Avanzado"
  defp get_status(progreso) when progreso < 100, do: "Casi completo"
  defp get_status(progreso) when progreso == 100, do: "Completo"
end
