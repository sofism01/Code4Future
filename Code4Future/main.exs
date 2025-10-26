defmodule Main do
  alias Services.TeamService

  def main do
    IO.puts("=== CREACIÓN DE EQUIPOS HACKATHON ===")
    IO.puts("")

    # Crear equipo
    equipo = crear_equipo()

    # Agregar miembros
    agregar_miembros(equipo)

    # Mostrar resultado final
    mostrar_equipo_final(equipo.nombre)
  end

  defp crear_equipo do
    IO.puts("CREAR NUEVO EQUIPO")
    IO.write("Ingresa el nombre del equipo: ")
    nombre_equipo = IO.read(:line) |> String.trim()

    if nombre_equipo == "" do
      IO.puts("El nombre no puede estar vacío. Intenta de nuevo.")
      crear_equipo()
    else
      equipo = Services.TeamService.crear_equipo(nombre_equipo)
      IO.puts("Equipo '#{equipo.nombre}' creado exitosamente!")
      IO.puts("ID del equipo: #{equipo.id}")
      IO.puts("")
      equipo
    end
  end

  defp agregar_miembros(equipo) do
    IO.puts("AGREGAR MIEMBROS AL EQUIPO")
    IO.puts("(Escribe 'fin' cuando termines de agregar miembros)")
    IO.puts("")

    agregar_miembro_loop(equipo.nombre, 1)
  end

  defp agregar_miembro_loop(nombre_equipo, contador) do
    IO.write("Miembro ##{contador} - Ingresa ID del participante (o 'fin' para terminar): ")
    input = IO.read(:line) |> String.trim()

    case input do
      "fin" ->
        IO.puts("¡Terminado de agregar miembros!")
        IO.puts("")

      "" ->
        IO.puts("ID vacío. Intenta de nuevo.")
        agregar_miembro_loop(nombre_equipo, contador)

      id_string ->
        case Integer.parse(id_string) do
          {id_participante, ""} ->
            case TeamService.unirse_a_equipo(id_participante, nombre_equipo) do
              {:ok, _equipo_actualizado} ->
                IO.puts("Participante #{id_participante} agregado al equipo!")
                agregar_miembro_loop(nombre_equipo, contador + 1)

              {:error, mensaje} ->
                IO.puts("Error: #{mensaje}")
                agregar_miembro_loop(nombre_equipo, contador)
            end

          _ ->
            IO.puts("ID inválido. Debe ser un número.")
            agregar_miembro_loop(nombre_equipo, contador)
        end
    end
  end

  defp mostrar_equipo_final(nombre_equipo) do
    IO.puts("=== EQUIPO CREADO CORRECTAMENTE ===")

    case TeamService.obtener_equipo_por_nombre(nombre_equipo) do
      nil ->
        IO.puts("Error: No se pudo encontrar el equipo.")

      equipo ->
        IO.puts("Nombre: #{equipo.nombre}")
        IO.puts("ID: #{equipo.id}")
        IO.puts("Total miembros: #{length(equipo.miembros)}")
        IO.puts("Proyecto: #{equipo.id_proyecto || "Sin asignar"}")
        IO.puts("")

        if length(equipo.miembros) > 0 do
          IO.puts("MIEMBROS:")
          Enum.each(equipo.miembros, fn miembro ->
            IO.puts("  - ID: #{miembro.id}, Nombre: #{miembro.nombre}")
          end)
        else
          IO.puts("Sin miembros registrados.")
        end

        IO.puts("")
        IO.puts("Equipo guardado en teams.csv")
        IO.puts("¡Listo para la hackathon!")
    end
  end

end
