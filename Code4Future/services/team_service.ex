defmodule Services.TeamService do
  @moduledoc """
  Encargado de la creación, búsqueda y administración de equipos.
  """

  alias Domain.Team

  @csv_file "teams.csv"

  @doc """
  Crea un nuevo equipo con el nombre dado.
  """
  def crear_equipo(nombre) do
    equipo = Team.crear_equipo(nombre)
    guardar_equipo(equipo)
    equipo
  end

  @doc """
  Lista todos los equipos existentes.
  """
  def listar_equipos do
    case File.exists?(@csv_file) do
      false -> []
      true ->
        @csv_file
        |> File.read!()
        |> String.split("\n")
        |> Enum.drop(1)  # Quitar encabezado
        |> Enum.filter(&(&1 != ""))
        |> Enum.map(&parsear_equipo_desde_csv/1)
        |> Enum.filter(&(&1 != nil))
    end
  end

  @doc """
  Un participante se une a un equipo por nombre.
  """
  def unirse_a_equipo(id_participante, nombre_equipo) do
    case obtener_equipo_por_nombre(nombre_equipo) do
      nil ->
        {:error, "Equipo no encontrado"}
      equipo ->
        participante = %{id: id_participante, nombre: "Participante #{id_participante}"}
        equipo_actualizado = Team.agregar_miembro(equipo, participante)
        actualizar_equipo_en_csv(equipo_actualizado)
        {:ok, equipo_actualizado}
    end
  end

  @doc """
  Busca un equipo por nombre.
  """
  def obtener_equipo_por_nombre(nombre) do
    equipos = listar_equipos()
    Enum.find(equipos, fn equipo -> equipo.nombre == nombre end)
  end

  @doc """
  Asigna un proyecto a un equipo.
  """
  def asignar_proyecto(equipo_id, proyecto_id) do
    equipos = listar_equipos()
    case Enum.find(equipos, fn equipo -> equipo.id == equipo_id end) do
      nil ->
        {:error, "Equipo no encontrado"}
      equipo ->
        equipo_actualizado = %{equipo | id_proyecto: proyecto_id}
        actualizar_equipo_en_csv(equipo_actualizado)
        {:ok, equipo_actualizado}
    end
  end

  # Funciones privadas

  defp guardar_equipo(equipo) do
  crear_csv_si_no_existe()
  equipo_fila = equipo_a_fila_csv(equipo)
  File.write!(@csv_file, equipo_fila <> "\n", [:append])
end

  defp actualizar_equipo_en_csv(equipo_actualizado) do # Actualizar equipo en CSV
    equipos = listar_equipos()
    equipos_actualizados = Enum.map(equipos, fn equipo ->
      if equipo.id == equipo_actualizado.id, do: equipo_actualizado, else: equipo
    end)

    guardar_todos_los_equipos(equipos_actualizados)
  end

 defp guardar_todos_los_equipos(equipos) do # Sobrescribir CSV con todos los equipos
  encabezado = "id, nombre, cantidad_miembros, id_proyecto\n"
  contenido_csv = encabezado <>
    Enum.map_join(equipos, "\n", &equipo_a_fila_csv/1) <>
    "\n" 
  File.write!(@csv_file, contenido_csv)
end

  defp equipo_a_fila_csv(equipo) do # Convertir equipo a fila CSV
    cantidad_miembros = length(equipo.miembros || [])
    "#{equipo.id}, #{equipo.nombre}, #{cantidad_miembros}, #{equipo.id_proyecto || ""}"
  end

 defp parsear_equipo_desde_csv(linea) do # Parsear fila CSV a struct Equipo
  # Dividir por coma y quitar espacios de cada elemento
  campos = linea
           |> String.split(",")
           |> Enum.map(&String.trim/1)

  case campos do
    [id, nombre, _cantidad_miembros, id_proyecto] ->
      equipo = Team.crear_equipo(nombre)
      proyecto = if(id_proyecto == "", do: nil, else: id_proyecto)

      %{equipo |
        id: String.to_integer(id),
        id_proyecto: proyecto
      }
    _ -> nil
  end
rescue
  _ -> nil
end

 defp crear_csv_si_no_existe do
  unless File.exists?(@csv_file) do
    File.write!(@csv_file, "id, nombre, cantidad_miembros, id_proyecto\n")
  end
  end
end
