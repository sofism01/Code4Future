defmodule Domain.Team do
  @moduledoc """
  Representa un equipo de la hackathon.
  """

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
    if existe_miembro?(equipo, participante.id) do
      equipo
    else
      %{equipo | miembros: [participante | equipo.miembros]}
    end
  end

  @doc """
  Remueve un participante del equipo.
  """
  def eliminar_miembro(equipo, participante) do
    nuevos_miembros = Enum.reject(equipo.miembros, fn miembro -> miembro.id == participante.id end)
    %{equipo | miembros: nuevos_miembros}
  end

  @doc """
  Verifica si un equipo tiene un miembro con el ID de participante dado.
  """
  def existe_miembro?(equipo, participante_id) do
    Enum.any?(equipo.miembros, fn miembro -> miembro.id == participante_id end)
  end
end
