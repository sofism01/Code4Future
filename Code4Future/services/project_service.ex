defmodule Services.ProjectService do
  @moduledoc """
  Gestiona el ciclo de vida de los proyectos en la hackathon.
  """

  alias Domain.Project

  @csv_file "projects.csv"

  @doc """
  Registra un nuevo proyecto para un equipo.
  """
  def registrar_proyecto(team_id, titulo, descripcion, categoria) do
    # Verificar que el equipo no tenga ya un proyecto
    case get_project_by_team(team_id) do
      nil ->
        proyecto = Project.crear_proyecto(team_id, titulo, descripcion, categoria)
        guardar_proyecto(proyecto)
        {:ok, proyecto}

      _proyecto_existente ->
        {:error, "El equipo ya tiene un proyecto registrado"}
    end
  end

  @doc """
  Actualiza el progreso de un proyecto por team_id.
  """
  def actualizar_progreso(team_id, nuevo_progreso) do
    case obtener_proyecto_por_equipo(team_id) do
      nil ->
        {:error, "No se encontró proyecto para el equipo"}

      proyecto ->
        proyecto_actualizado = Project.actualizar_progreso(proyecto, nuevo_progreso)
        actualizar_proyecto_en_csv(proyecto_actualizado)
        {:ok, proyecto_actualizado}
    end
  end

  @doc """
  Agrega feedback de un mentor a un proyecto.
  """
  def agregar_feedback(team_id, mentor_id, feedback) do
    case obtener_proyecto_por_equipo(team_id) do
      nil ->
        {:error, "No se encontró proyecto para el equipo"}

      proyecto ->
        proyecto_con_feedback = Project.agregar_feedback(proyecto, mentor_id, feedback)
        actualizar_proyecto_en_csv(proyecto_con_feedback)
        {:ok, proyecto_con_feedback}
    end
  end

  @doc """
  Obtiene el proyecto de un equipo específico.
  """
  def obtener_proyecto_por_equipo(team_id) do
    listar_proyectos()
    |> Enum.find(fn proyecto -> proyecto.team_id == team_id end)
  end

  @doc """
  Lista todos los proyectos de una categoría específica.
  """
  def listar_proyectos_por_categoria(categoria) do
    listar_proyectos()
    |> Enum.filter(fn proyecto ->
      String.downcase(proyecto.categoria) == String.downcase(categoria)
    end)
  end

  @doc """
  Lista todos los proyectos registrados.
  """
  def listar_proyectos do
    case File.exists?(@csv_file) do
      false -> []
      true ->
        @csv_file
        |> File.read!()
        |> String.split("\n")
        |> Enum.drop(1)
        |> Enum.filter(&(&1 != ""))
        |> Enum.map(&parsear_proyecto_desde_csv/1)
        |> Enum.filter(&(&1 != nil))
    end
  end

   

  # Funciones privadas

  defp guardar_proyecto(proyecto) do
    crear_csv_si_no_existe()
    proyecto_fila = proyecto_a_fila_csv(proyecto)
    File.write!(@csv_file, proyecto_fila <> "\n", [:append])
  end

  defp actualizar_proyecto_en_csv(proyecto_actualizado) do
    proyectos = listar_proyectos()
    proyectos_actualizados = Enum.map(proyectos, fn proyecto ->
      if proyecto.id == proyecto_actualizado.id, do: proyecto_actualizado, else: proyecto
    end)

    guardar_todos_los_proyectos(proyectos_actualizados)
  end

  defp guardar_todos_los_proyectos(proyectos) do
    encabezado = "id, team_id, titulo, descripcion, categoria, progreso, feedbacks\n"
    contenido_csv = encabezado <>
      Enum.map_join(proyectos, "\n", &proyecto_a_fila_csv/1) <>
      "\n"

    File.write!(@csv_file, contenido_csv)
  end

  defp proyecto_a_fila_csv(proyecto) do
    # Convertir feedbacks a string serializado
    feedbacks_string = proyecto.feedbacks
                      |> Enum.map(fn fb ->
                        "#{fb.mentor_id}:#{fb.feedback}:#{DateTime.to_iso8601(fb.timestamp)}"
                      end)
                      |> Enum.join(";")

    descripcion_escaped = String.replace(proyecto.descripcion, ",", "\\,")

    "#{proyecto.id}, #{proyecto.team_id}, #{proyecto.titulo}, #{descripcion_escaped}, #{proyecto.categoria}, #{proyecto.progreso}, #{feedbacks_string}"
  end

  defp parsear_proyecto_desde_csv(linea) do
    campos = linea
            |> String.split(",")
            |> Enum.map(&String.trim/1)

    case campos do
      [id, team_id, titulo, descripcion, categoria, progreso, feedbacks_string] ->
        # Parsear feedbacks desde string
        feedbacks = if feedbacks_string == "" do
          []
        else
          feedbacks_string
          |> String.split(";")
          |> Enum.map(fn feedback_str ->
            case String.split(feedback_str, ":") do
              [mentor_id, feedback, timestamp_str] ->
                {:ok, timestamp, _} = DateTime.from_iso8601(timestamp_str)
                %{
                  mentor_id: String.to_integer(mentor_id),
                  feedback: feedback,
                  timestamp: timestamp
                }
              _ -> nil
            end
          end)
          |> Enum.filter(&(&1 != nil))
        end

        descripcion_unescaped = String.replace(descripcion, "\\,", ",")

        %{__struct__: Domain.Project,
          id: String.to_integer(id),
          team_id: String.to_integer(team_id),
          titulo: titulo,
          descripcion: descripcion_unescaped,
          categoria: categoria,
          progreso: String.to_integer(progreso),
          feedbacks: feedbacks
        }
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp crear_csv_si_no_existe do
    unless File.exists?(@csv_file) do
      File.write!(@csv_file, "id, team_id, titulo, descripcion, categoria, progreso, feedbacks\n")
    end
  end

end
