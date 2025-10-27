defmodule Domain.Participant do
  @moduledoc """
  Representa un participante de la hackathon.
  """

  defstruct [:id, :nombre, :habilidades, :team_id]

  @doc """
  Crea un nuevo participante con el nombre y habilidades dados.
  """
  def crear_participante(nombre, habilidades) do
    %__MODULE__{
      id: System.unique_integer([:positive]),
      nombre: nombre,
      habilidades: habilidades,
      team_id: nil
    }
  end

  @doc """
  Asigna un participante a un equipo.
  """
  def asignar_a_equipo(participante, team_id) do
    %{participante | team_id: team_id}
  end
end
