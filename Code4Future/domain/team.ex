defmodule Domain.Team do
  @moduledoc """
  Representa un equipo de la hackathon.
  """

  defstruct [:id, :name, :members, :project_id]

  @doc """
  Crea un nuevo equipo con el nombre dado.
  """
  def create_team(name) do
    %__MODULE__{
      id: System.unique_integer([:positive]),
      name: name,
      members: [],
      project_id: nil
    }
  end

  @doc """
  Agrega un participante al equipo.
  """
  def add_member(team, participant) do
    if has_member?(team, participant.id) do
      team
    else
      %{team | members: [participant | team.members]}
    end
  end

  @doc """
  Remueve un participante del equipo.
  """
  def remove_member(team, participant) do
    nuevos_miembros = Enum.reject(team.members, fn member -> member.id == participant.id end)
    %{team | members: nuevos_miembros}
  end

  @doc """
  Verifica si un equipo tiene un miembro con el ID de participante dado.
  """
  def has_member?(team, participant_id) do
    Enum.any?(team.members, fn member -> member.id == participant_id end)
  end
end
