defmodule Services.MentorService do
  @moduledoc """
  Servicio para el registro de mentores y gestión de retroalimentación.
  """

  alias Domain.Mentor
  alias Services.ProjectService

  @mentors_csv "mentors.csv"
  @assignments_csv "mentor_assignments.csv"
  @feedback_csv "mentor_feedback.csv"

  @doc """
  Registra un nuevo mentor en el sistema.
  """
  def registrar_mentor(nombre, experiencia) do
    # Verificar que el mentor no exista ya
    case obtener_mentor_por_nombre(nombre) do
      nil ->
        mentor = Mentor.crear_mentor(nombre, experiencia)
        guardar_mentor(mentor)
        {:ok, mentor}

      _mentor_existente ->
        {:error, "Ya existe un mentor con ese nombre"}
    end
  end

  @doc """
  Lista todos los mentores registrados en el sistema.
  """
  def list_mentors do
    listar_mentores()
  end

  @doc """
  Lista mentores filtrados por área de experiencia.
  """
  def listar_por_experiencia(categoria) do
    listar_mentores()
    |> Enum.filter(fn mentor ->
      Mentor.tiene_experiencia?(mentor, categoria)
    end)
  end

  @doc """
  Asigna un mentor a un equipo específico.
  """
  def asignar_a_team(mentor_id, team_id) do
    case {obtener_mentor_por_id(mentor_id), verificar_equipo_existe(team_id)} do
      {nil, _} ->
        {:error, "Mentor no encontrado"}

      {_mentor, false} ->
        {:error, "Equipo no encontrado"}

      {mentor, true} ->
        # Verificar si ya está asignado
        case obtener_asignacion(mentor_id, team_id) do
          nil ->
            asignacion = %{
              id: System.unique_integer([:positive]),
              mentor_id: mentor_id,
              team_id: team_id,
              assigned_at: DateTime.utc_now(),
              status: :active
            }

            guardar_asignacion(asignacion)
            IO.puts("Mentor #{mentor.nombre} asignado al equipo #{team_id}")
            {:ok, asignacion}

          _asignacion_existente ->
            {:error, "El mentor ya está asignado a este equipo"}
        end
    end
  end

  @doc """
  Envía feedback de un mentor a un equipo específico.
  """
  def enviar_feedback(mentor_id, team_id, feedback) do
    case {obtener_mentor_por_id(mentor_id), verificar_equipo_existe(team_id)} do
      {nil, _} ->
        {:error, "Mentor no encontrado"}

      {_mentor, false} ->
        {:error, "Equipo no encontrado"}

      {mentor, true} ->
        # Crear registro de feedback
        feedback_record = %{
          id: System.unique_integer([:positive]),
          mentor_id: mentor_id,
          team_id: team_id,
          feedback: feedback,
          timestamp: DateTime.utc_now()
        }

        # Guardar feedback en CSV
        guardar_feedback(feedback_record)

        # Agregar feedback al proyecto del equipo
        case ProjectService.obtener_proyecto_por_equipo(team_id) do
          nil ->
            IO.puts("Feedback guardado, pero el equipo no tiene proyecto aún")
            {:ok, feedback_record}

          _proyecto ->
            case ProjectService.agregar_feedback(team_id, mentor_id, feedback) do
              {:ok, _proyecto_actualizado} ->
                IO.puts("Feedback de #{mentor.nombre} enviado al equipo #{team_id}")
                {:ok, feedback_record}

              {:error, reason} ->
                {:error, "Error al agregar feedback al proyecto: #{reason}"}
            end
        end
    end
  end

  @doc """
  Obtiene todos los feedbacks de un mentor específico.
  """
  def obtener_feedbacks_por_mentor(mentor_id) do
    listar_feedbacks()
    |> Enum.filter(fn feedback -> feedback.mentor_id == mentor_id end)
    |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})
  end

  @doc """
  Obtiene todos los feedbacks recibidos por un equipo.
  """
  def obtener_feedbacks_por_equipo(team_id) do
    listar_feedbacks()
    |> Enum.filter(fn feedback -> feedback.team_id == team_id end)
    |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})
  end

  @doc """
  Lista las asignaciones activas de mentores.
  """
  def listar_asignaciones_activas do
    listar_asignaciones()
    |> Enum.filter(fn asignacion -> asignacion.status == :active end)
  end

  @doc """
  Obtiene los equipos asignados a un mentor específico.
  """
  def obtener_equipos(mentor_id) do
    listar_asignaciones()
    |> Enum.filter(fn asignacion ->
      asignacion.mentor_id == mentor_id and asignacion.status == :active
    end)
    |> Enum.map(& &1.team_id)
  end

  @doc """
  Obtiene estadísticas de mentoría.
  """
  def obtener_estadisticas do
    mentores = listar_mentores()
    asignaciones = list_active_assignments()
    feedbacks = listar_feedbacks()

    mentores_activos = asignaciones
                      |> Enum.map(& &1.mentor_id)
                      |> Enum.uniq()
                      |> length()

    equipos_con_mentor = asignaciones
                        |> Enum.map(& &1.team_id)
                        |> Enum.uniq()
                        |> length()

    %{
      total_mentores: length(mentores),
      mentores_activos: mentores_activos,
      equipos_con_mentor: equipos_con_mentor,
      total_feedbacks: length(feedbacks),
      asignaciones_activas: length(asignaciones)
    }
  end

  # Funciones privadas

  defp obtener_mentor_por_id(mentor_id) do
    listar_mentores()
    |> Enum.find(fn mentor -> mentor.id == mentor_id end)
  end

  defp obtener_mentor_por_nombre(nombre) do
    listar_mentores()
    |> Enum.find(fn mentor ->
      String.downcase(mentor.nombre) == String.downcase(nombre)
    end)
  end

  defp verificar_equipo_existe(team_id) do
    # Esta función debería verificar en TeamService si el equipo existe
    # Por simplicidad, asumimos que existe si team_id es válido
    is_integer(team_id) and team_id > 0
  end

  defp obtener_asignacion(mentor_id, team_id) do
    listar_asignaciones()
    |> Enum.find(fn asignacion ->
      asignacion.mentor_id == mentor_id and
      asignacion.team_id == team_id and
      asignacion.status == :active
    end)
  end

  defp listar_mentores do
    case File.exists?(@mentors_csv) do
      false -> []
      true ->
        @mentors_csv
        |> File.read!()
        |> String.split("\n")
        |> Enum.drop(1)
        |> Enum.filter(&(&1 != ""))
        |> Enum.map(&parsear_mentor_desde_csv/1)
        |> Enum.filter(&(&1 != nil))
    end
  end

  defp listar_asignaciones do
    case File.exists?(@assignments_csv) do
      false -> []
      true ->
        @assignments_csv
        |> File.read!()
        |> String.split("\n")
        |> Enum.drop(1)
        |> Enum.filter(&(&1 != ""))
        |> Enum.map(&parsear_asignacion_desde_csv/1)
        |> Enum.filter(&(&1 != nil))
    end
  end

  defp listar_feedbacks do
    case File.exists?(@feedback_csv) do
      false -> []
      true ->
        @feedback_csv
        |> File.read!()
        |> String.split("\n")
        |> Enum.drop(1)
        |> Enum.filter(&(&1 != ""))
        |> Enum.map(&parsear_feedback_desde_csv/1)
        |> Enum.filter(&(&1 != nil))
    end
  end

  defp guardar_mentor(mentor) do
    crear_csv_mentores_si_no_existe()
    mentor_fila = mentor_a_fila_csv(mentor)
    File.write!(@mentors_csv, mentor_fila <> "\n", [:append])
  end

  defp guardar_asignacion(asignacion) do
    crear_csv_asignaciones_si_no_existe()
    asignacion_fila = asignacion_a_fila_csv(asignacion)
    File.write!(@assignments_csv, asignacion_fila <> "\n", [:append])
  end

  defp guardar_feedback(feedback) do
    crear_csv_feedback_si_no_existe()
    feedback_fila = feedback_a_fila_csv(feedback)
    File.write!(@feedback_csv, feedback_fila <> "\n", [:append])
  end

  # Funciones de serialización CSV

  defp mentor_a_fila_csv(mentor) do
    experiencia_string = Enum.join(mentor.experiencia, ";")
    "#{mentor.id}, #{mentor.nombre}, #{experiencia_string}"
  end

  defp asignacion_a_fila_csv(asignacion) do
    "#{asignacion.id}, #{asignacion.mentor_id}, #{asignacion.team_id}, #{DateTime.to_iso8601(asignacion.assigned_at)}, #{asignacion.status}"
  end

  defp feedback_a_fila_csv(feedback) do
    feedback_escaped = String.replace(feedback.feedback, ",", "\\,")
    "#{feedback.id}, #{feedback.mentor_id}, #{feedback.team_id}, #{feedback_escaped}, #{DateTime.to_iso8601(feedback.timestamp)}"
  end

  defp parsear_mentor_desde_csv(linea) do
    campos = linea |> String.split(",") |> Enum.map(&String.trim/1)

    case campos do
      [id, nombre, experiencia_string] ->
        experiencia = if experiencia_string == "" do
          []
        else
          String.split(experiencia_string, ";")
        end

        %{__struct__: Domain.Mentor,
          id: String.to_integer(id),
          nombre: nombre,
          experiencia: experiencia}
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp parsear_asignacion_desde_csv(linea) do
    campos = linea |> String.split(",") |> Enum.map(&String.trim/1)

    case campos do
      [id, mentor_id, team_id, assigned_at_str, status_str] ->
        {:ok, assigned_at, _} = DateTime.from_iso8601(assigned_at_str)

        %{
          id: String.to_integer(id),
          mentor_id: String.to_integer(mentor_id),
          team_id: String.to_integer(team_id),
          assigned_at: assigned_at,
          status: String.to_existing_atom(status_str)
        }
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp parsear_feedback_desde_csv(linea) do
    campos = linea |> String.split(",") |> Enum.map(&String.trim/1)

    case campos do
      [id, mentor_id, team_id, feedback_text, timestamp_str] ->
        {:ok, timestamp, _} = DateTime.from_iso8601(timestamp_str)
        feedback_unescaped = String.replace(feedback_text, "\\,", ",")

        %{
          id: String.to_integer(id),
          mentor_id: String.to_integer(mentor_id),
          team_id: String.to_integer(team_id),
          feedback: feedback_unescaped,
          timestamp: timestamp
        }
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp crear_csv_mentores_si_no_existe do
    unless File.exists?(@mentors_csv) do
      File.write!(@mentors_csv, "id, nombre, experiencia\n")
    end
  end

  defp crear_csv_asignaciones_si_no_existe do
    unless File.exists?(@assignments_csv) do
      File.write!(@assignments_csv, "id, mentor_id, team_id, assigned_at, status\n")
    end
  end

  defp crear_csv_feedback_si_no_existe do
    unless File.exists?(@feedback_csv) do
      File.write!(@feedback_csv, "id, mentor_id, team_id, feedback, timestamp\n")
    end
  end
end
