defmodule Domain.Team do
  @moduledoc """
  Representa un equipo de la hackathon.
  """

  alias Domain.Participant

  defstruct [:id, :nombre, :miembros, :id_proyecto]

  @doc """
  Crea un nuevo equipo con el nombre dado.
  """
  def crear_equipo(nombre) do
    %__MODULE__{
      id: System.unique_integer([:positive]),
      nombre: nombre,
      miembros: [],
      id_proyecto: nil
    }
  end

  @doc """
  Agrega un participante al equipo.
  """
  def agregar_miembro(equipo, participante) do
    # Verificar que sea un struct Participant
  unless is_struct(participante, Participant) do
    raise ArgumentError, "El segundo argumento debe ser un struct Domain.Participant"
  end

  if existe_miembro?(equipo, participante.id) do
    equipo
  else
    # Asignar el participante al equipo
    participante_actualizado = Participant.asignar_a_equipo(participante, equipo.id)
    %{equipo | miembros: [participante_actualizado | equipo.miembros]}
  end
  end

  @doc """
  Remueve un participante del equipo.
  """
  def eliminar_miembro(equipo, participante) do
    # Encontrar el participante y resetear su team_id
  # participante_sin_equipo = %{participante | team_id: nil}

  nuevos_miembros = Enum.reject(equipo.miembros, fn miembro ->
    miembro.id == participante.id
  end)

  %{equipo | miembros: nuevos_miembros}
  end

  @doc """
  Verifica si un equipo tiene un miembro con el ID de participante dado.
  """
  def existe_miembro?(equipo, participante_id) do
    Enum.any?(equipo.miembros, fn miembro -> miembro.id == participante_id end)
  end

  @doc """
Crea un equipo y agrega participantes iniciales.
"""
def crear_equipo_con_participantes(nombre, lista_participantes \\ []) do
  equipo = crear_equipo(nombre)

  Enum.reduce(lista_participantes, equipo, fn participante, acc_equipo ->
    agregar_miembro(acc_equipo, participante)
  end)
end

@doc """
Obtiene información detallada del equipo incluyendo habilidades de miembros.
"""
def obtener_info_equipo(equipo) do
  todas_las_habilidades =
    equipo.miembros
    |> Enum.flat_map(& &1.habilidades)
    |> Enum.uniq()

  %{
    id: equipo.id,
    nombre: equipo.nombre,
    cantidad_miembros: length(equipo.miembros),
    miembros: equipo.miembros,
    habilidades_del_equipo: todas_las_habilidades,
    id_proyecto: equipo.id_proyecto
  }
end

end
