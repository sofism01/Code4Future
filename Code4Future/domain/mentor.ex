defmodule Domain.Mentor do
  @moduledoc """
  Representa un mentor disponible en la hackathon.
  """

  alias Domain.Project

  defstruct [:id, :nombre, :experiencia]

  @doc """
  Crea un nuevo mentor con nombre y área de experiencia.
  """
  def crear_mentor(nombre, experiencia) do
    %__MODULE__{
      id: System.unique_integer([:positive]),
      nombre: nombre,
      experiencia: experiencia
    }
  end

  @doc """
  Permite al mentor dar feedback a un proyecto específico.
  """
  def dar_feedback(mentor, proyecto, feedback) do
    Project.agregar_feedback(proyecto, mentor.id, feedback)
  end

  @doc """
  Obtiene información del mentor.
  """
  def obtener_info_mentor(mentor) do
    %{
      id: mentor.id,
      nombre: mentor.nombre,
      experiencia: mentor.experiencia
    }
  end

  @doc """
  Verifica si un mentor tiene experiencia en una categoría específica.
  """
  def tiene_experiencia?(mentor, categoria) do
    mentor.experiencia
    |> Enum.any?(fn experiencia ->
      String.downcase(experiencia) == String.downcase(categoria)
    end)
  end
end
