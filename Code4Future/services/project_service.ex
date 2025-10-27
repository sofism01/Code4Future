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

end
