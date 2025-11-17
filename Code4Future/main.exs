defmodule Main do
  @moduledoc """
  Módulo principal para la gestión de la hackathon.
  """
  alias Services.TeamService
  alias Services.ProjectService
  alias Services.MentorService

  @doc """
  Función principal que inicia el proceso de gestión de la hackathon.
  """
  def main do
    IO.puts("=== GESTIÓN DE HACKATHON ===")
    IO.puts("")
    mostrar_menu_principal()
  end

  defp mostrar_menu_principal do
    IO.puts("MENU PRINCIPAL")
    IO.puts("¿Qué deseas hacer?")
    IO.puts("1. Crear equipo completo (equipo + miembros + proyecto + mentor)")
    IO.puts("2. Usar comandos interactivos")
    IO.puts("3. Salir")
    IO.write("Selecciona una opción (1-3): ")

    opcion = IO.read(:line) |> String.trim()

    case opcion do
      "1" ->
        flujo_crear_equipo_completo()
        mostrar_menu_principal()

      "2" ->
        modo_comandos()
        mostrar_menu_principal()

      "3" ->
        IO.puts("¡Gracias por usar el sistema de gestión de hackathon!")
        IO.puts("¡Hasta luego!")

      _ ->
        IO.puts("Opción inválida. Intenta de nuevo.")
        mostrar_menu_principal()
    end
  end

  defp modo_comandos do
    IO.puts("")
    IO.puts("=== MODO COMANDOS ===")
    mostrar_ayuda()
    loop_comandos()
  end

  defp loop_comandos do
    IO.write("hackathon> ")
    comando = IO.read(:line) |> String.trim()

    case procesar_comando(comando) do
      :salir ->
        IO.puts("Saliendo del modo comandos...")
      :continuar ->
        loop_comandos()
    end
  end

  defp procesar_comando(comando) do
    partes = String.split(comando, " ", trim: true)

    case partes do
      ["/teams"] ->
        comando_teams()
        :continuar

      ["/project", nombre_equipo] ->
        comando_project(nombre_equipo)
        :continuar

      ["/join", nombre_equipo] ->
        comando_join(nombre_equipo)
        :continuar

      ["/help"] ->
        mostrar_ayuda()
        :continuar

      ["exit"] ->
        :salir

      ["salir"] ->
        :salir

      [] ->
        :continuar

      _ ->
        IO.puts("Comando no reconocido. Escribe /help para ver comandos disponibles.")
        :continuar
    end
  end

  defp comando_teams do
    equipos = TeamService.listar_equipos()

    if length(equipos) == 0 do
      IO.puts("No hay equipos registrados.")
    else
      IO.puts("EQUIPOS REGISTRADOS:")
      IO.puts("==================")
      Enum.each(equipos, fn equipo ->
        proyecto = ProjectService.obtener_proyecto_por_equipo(equipo.id)
        proyecto_info = if proyecto, do: " - Proyecto: #{proyecto.titulo}", else: " - Sin proyecto"

        IO.puts("#{equipo.nombre} (#{length(equipo.miembros)} miembros)#{proyecto_info}")
      end)
      IO.puts("")
    end
  end

  defp comando_project(nombre_equipo) do
    case TeamService.obtener_equipo_por_nombre(nombre_equipo) do
      nil ->
        IO.puts("Equipo '#{nombre_equipo}' no encontrado.")

      equipo ->
        case ProjectService.obtener_proyecto_por_equipo(equipo.id) do
          nil ->
            IO.puts("El equipo '#{nombre_equipo}' no tiene proyecto asignado.")

          proyecto ->
            IO.puts("INFORMACIÓN DEL PROYECTO - #{nombre_equipo}")
            IO.puts("=========================================")
            IO.puts("Título: #{proyecto.titulo}")
            IO.puts("Descripción: #{proyecto.descripcion}")
            IO.puts("Categoría: #{proyecto.categoria}")
            IO.puts("Progreso: #{proyecto.progreso}%")
            IO.puts("Miembros del equipo: #{length(equipo.miembros)}")

            if length(proyecto.feedbacks) > 0 do
              IO.puts("Feedbacks recibidos: #{length(proyecto.feedbacks)}")
              IO.puts("Último feedback: #{List.first(proyecto.feedbacks)}")
            else
              IO.puts("Sin feedbacks aún.")
            end

            # Mostrar mentor si tiene
            mostrar_mentor_comando(equipo.id)
            IO.puts("")
        end
    end
  end

  defp comando_join(nombre_equipo) do
    case TeamService.obtener_equipo_por_nombre(nombre_equipo) do
      nil ->
        IO.puts("Equipo '#{nombre_equipo}' no encontrado.")
        IO.write("¿Deseas crear este equipo? (s/n): ")
        respuesta = IO.read(:line) |> String.trim() |> String.downcase()

        if respuesta in ["s", "si", "yes", "y"] do
          TeamService.crear_equipo(nombre_equipo)
          IO.puts("Equipo '#{nombre_equipo}' creado exitosamente!")
        end

      equipo ->
        IO.write("Ingresa tu ID de participante: ")
        id_input = IO.read(:line) |> String.trim()

        case Integer.parse(id_input) do
          {id_participante, ""} ->
            case TeamService.unirse_a_equipo(id_participante, nombre_equipo) do
              {:ok, _equipo_actualizado} ->
                IO.puts("¡Te has unido exitosamente al equipo '#{nombre_equipo}'!")
                mostrar_info_equipo(equipo)

              {:error, mensaje} ->
                IO.puts("Error al unirse: #{mensaje}")
            end

          _ ->
            IO.puts("ID inválido. Debe ser un número.")
        end
    end
    IO.puts("")
  end



  defp mostrar_ayuda do
    IO.puts("COMANDOS DISPONIBLES:")
    IO.puts("====================")
    IO.puts("/teams                    → Listar equipos registrados")
    IO.puts("/project <nombre_equipo>  → Mostrar información del proyecto de un equipo")
    IO.puts("/join <nombre_equipo>     → Unirse a un equipo")
    IO.puts("/help                     → Mostrar esta ayuda")
    IO.puts("exit / salir              → Salir del modo comandos")
    IO.puts("")
    IO.puts("Ejemplos:")
    IO.puts("  /teams")
    IO.puts("  /project equipo1")
    IO.puts("  /join equipo1")
    IO.puts("")
  end

  defp mostrar_mentor_comando(team_id) do
    teams_mentors = MentorService.listar_asignaciones_activas()
                   |> Enum.filter(fn asignacion -> asignacion.team_id == team_id end)

    if length(teams_mentors) > 0 do
      IO.puts("Mentor asignado:")
      Enum.each(teams_mentors, fn asignacion ->
        mentores = MentorService.list_mentors()
        mentor = Enum.find(mentores, fn m -> m.id == asignacion.mentor_id end)

        if mentor do
          experiencia_str = Enum.join(mentor.experiencia, ", ")
          IO.puts("  - #{mentor.nombre} (#{experiencia_str})")
        end
      end)
    else
      IO.puts("Sin mentor asignado")
    end
  end

  defp mostrar_info_equipo(equipo) do
    IO.puts("INFORMACIÓN DEL EQUIPO:")
    IO.puts("Nombre: #{equipo.nombre}")
    IO.puts("Miembros actuales: #{length(equipo.miembros)}")

    if length(equipo.miembros) > 0 do
      IO.puts("Lista de miembros:")
      Enum.each(equipo.miembros, fn miembro ->
        IO.puts("  - #{miembro.nombre} (ID: #{miembro.id})")
      end)
    end
  end

  defp flujo_crear_equipo_completo do
    IO.puts("")
    IO.puts("=== CREAR EQUIPO COMPLETO ===")

    # Crear equipo
    equipo = crear_equipo()

    # Agregar miembros
    agregar_miembros(equipo)

    # Crear proyecto para el equipo
    crear_proyecto_para_equipo(equipo)

    # Registrar mentor
    registrar_mentor_para_equipo(equipo)

    # Mostrar resultado final
    mostrar_resumen_final(equipo.nombre)

    IO.puts("")
    IO.write("Presiona Enter para continuar...")
    IO.read(:line)
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

  defp crear_proyecto_para_equipo(equipo) do
    IO.puts("CREAR PROYECTO PARA EL EQUIPO")
    IO.write("¿Deseas crear un proyecto para este equipo? (s/n): ")
    respuesta = IO.read(:line) |> String.trim() |> String.downcase()

    case respuesta do
      "s" ->
        crear_proyecto_interactivo(equipo.id)
      "si" ->
        crear_proyecto_interactivo(equipo.id)
      "y" ->
        crear_proyecto_interactivo(equipo.id)
      "yes" ->
        crear_proyecto_interactivo(equipo.id)
      _ ->
        IO.puts("Saltando creación de proyecto.")
        IO.puts("")
    end
  end

  defp registrar_mentor_para_equipo(equipo) do
    IO.puts("REGISTRO DE MENTOR")
    IO.write("¿Deseas registrar un mentor para este equipo? (s/n): ")
    respuesta = IO.read(:line) |> String.trim() |> String.downcase()

    case respuesta do
      "s" ->
        registrar_mentor_interactivo(equipo.id)
      "si" ->
        registrar_mentor_interactivo(equipo.id)
      "y" ->
        registrar_mentor_interactivo(equipo.id)
      "yes" ->
        registrar_mentor_interactivo(equipo.id)
      _ ->
        IO.puts("Saltando registro de mentor.")
        IO.puts("")
    end
  end

  defp registrar_mentor_interactivo(team_id) do
    IO.puts("=== DATOS DEL MENTOR ===")

    IO.puts("¿Qué deseas hacer?")
    IO.puts("1. Registrar nuevo mentor")
    IO.puts("2. Asignar mentor existente")
    IO.write("Elige una opción (1-2): ")

    opcion = IO.read(:line) |> String.trim()

    case opcion do
      "1" ->
        crear_nuevo_mentor(team_id)
      "2" ->
        asignar_mentor_existente(team_id)
      _ ->
        IO.puts("Opción inválida. Intenta de nuevo.")
        registrar_mentor_interactivo(team_id)
    end
  end

  defp crear_nuevo_mentor(team_id) do
    nombre = solicitar_nombre_mentor()
    experiencia = solicitar_experiencia_mentor()

    case MentorService.registrar_mentor(nombre, experiencia) do
      {:ok, mentor} ->
        IO.puts("Mentor '#{mentor.nombre}' registrado exitosamente!")
        IO.puts("ID del mentor: #{mentor.id}")
        IO.puts("Experiencia: #{Enum.join(mentor.experiencia, ", ")}")
        IO.puts("")

        case MentorService.asignar_a_team(mentor.id, team_id) do
          {:ok, _asignacion} ->
            IO.puts("Mentor asignado al equipo exitosamente!")
            enviar_feedback_inicial(mentor.id, team_id)

          {:error, mensaje} ->
            IO.puts("Error al asignar mentor: #{mensaje}")
        end

      {:error, mensaje} ->
        IO.puts("Error al crear mentor: #{mensaje}")
        IO.puts("")
    end
  end

  defp asignar_mentor_existente(team_id) do
    mentores = MentorService.list_mentors()

    if length(mentores) == 0 do
      IO.puts("No hay mentores registrados. Creando nuevo mentor...")
      crear_nuevo_mentor(team_id)
    else
      IO.puts("MENTORES DISPONIBLES:")
      Enum.with_index(mentores, 1) |> Enum.each(fn {mentor, index} ->
        experiencia_str = Enum.join(mentor.experiencia, ", ")
        IO.puts("   #{index}. #{mentor.nombre} (#{experiencia_str})")
      end)

      IO.write("Selecciona un mentor (número) o '0' para crear uno nuevo: ")
      input = IO.read(:line) |> String.trim()

      case Integer.parse(input) do
        {0, ""} ->
          crear_nuevo_mentor(team_id)

        {numero, ""} when numero > 0 and numero <= length(mentores) ->
          mentor_seleccionado = Enum.at(mentores, numero - 1)

          case MentorService.asignar_a_team(mentor_seleccionado.id, team_id) do
            {:ok, _asignacion} ->
              IO.puts("Mentor #{mentor_seleccionado.nombre} asignado al equipo!")
              enviar_feedback_inicial(mentor_seleccionado.id, team_id)

            {:error, mensaje} ->
              IO.puts("Error al asignar mentor: #{mensaje}")
          end

        _ ->
          IO.puts("Selección inválida. Intenta de nuevo.")
          asignar_mentor_existente(team_id)
      end
    end
  end

  defp solicitar_nombre_mentor do
    IO.write("Ingresa el nombre del mentor: ")
    nombre = IO.read(:line) |> String.trim()

    if nombre == "" do
      IO.puts("El nombre no puede estar vacío.")
      solicitar_nombre_mentor()
    else
      nombre
    end
  end

  defp solicitar_experiencia_mentor do
    IO.puts("Selecciona las áreas de experiencia del mentor:")
    IO.puts("1. Web")
    IO.puts("2. Mobile")
    IO.puts("3. AI/ML")
    IO.puts("4. Gaming")
    IO.puts("5. IoT")
    IO.puts("6. Desktop")
    IO.puts("7. Cloud")
    IO.puts("8. Security")
    IO.puts("")
    IO.puts("Puedes seleccionar múltiples opciones separadas por coma (ej: 1,3,7)")
    IO.write("O escribe áreas personalizadas: ")

    input = IO.read(:line) |> String.trim()

    if String.contains?(input, ",") or Regex.match?(~r/^\d+$/, input) do
      numeros = input
                |> String.split(",")
                |> Enum.map(&String.trim/1)
                |> Enum.map(&Integer.parse/1)
                |> Enum.filter(fn
                  {_num, ""} -> true
                  _ -> false
                end)
                |> Enum.map(fn {num, ""} -> num end)

      experiencias = Enum.map(numeros, fn num ->
        case num do
          1 -> "Web"
          2 -> "Mobile"
          3 -> "AI/ML"
          4 -> "Gaming"
          5 -> "IoT"
          6 -> "Desktop"
          7 -> "Cloud"
          8 -> "Security"
          _ -> nil
        end
      end) |> Enum.filter(&(&1 != nil))

      if length(experiencias) > 0 do
        experiencias
      else
        IO.puts("Selección inválida. Intenta de nuevo.")
        solicitar_experiencia_mentor()
      end
    else
      if input == "" do
        IO.puts("Debes especificar al menos un área de experiencia.")
        solicitar_experiencia_mentor()
      else
        [input]
      end
    end
  end

  defp enviar_feedback_inicial(mentor_id, team_id) do
    IO.write("¿Quieres que el mentor envíe un feedback inicial? (s/n): ")
    respuesta = IO.read(:line) |> String.trim() |> String.downcase()

    case respuesta do
      "s" ->
        IO.write("Ingresa el feedback inicial: ")
        feedback = IO.read(:line) |> String.trim()

        if feedback != "" do
          case MentorService.enviar_feedback(mentor_id, team_id, feedback) do
            {:ok, _feedback_record} ->
              IO.puts("Feedback inicial enviado!")
            {:error, mensaje} ->
              IO.puts("Error al enviar feedback: #{mensaje}")
          end
        end

      "si" ->
        enviar_feedback_inicial(mentor_id, team_id)

      _ ->
        IO.puts("Saltando feedback inicial.")
    end

    IO.puts("")
  end

  defp crear_proyecto_interactivo(team_id) do
    IO.puts("=== DATOS DEL PROYECTO ===")

    # Solicitar título
    titulo = solicitar_titulo()

    # Solicitar descripción
    descripcion = solicitar_descripcion()

    # Solicitar categoría
    categoria = solicitar_categoria()

    # Crear el proyecto usando ProjectService.registrar_proyecto/4
    case ProjectService.registrar_proyecto(team_id, titulo, descripcion, categoria) do
      {:ok, proyecto} ->
        IO.puts("¡Proyecto '#{proyecto.titulo}' creado exitosamente!")
        IO.puts("ID del proyecto: #{proyecto.id}")
        IO.puts("Categoria: #{proyecto.categoria}")
        IO.puts("Progreso inicial: #{proyecto.progreso}%")
        IO.puts("")

        # Preguntar si se quiere actualizar el progreso inicial
        actualizar_progreso_inicial(team_id)

      {:error, mensaje} ->
        IO.puts("Error al crear proyecto: #{mensaje}")
        IO.puts("")
    end
  end

  defp solicitar_titulo do
    IO.write("Ingresa el titulo del proyecto: ")
    titulo = IO.read(:line) |> String.trim()

    if titulo == "" do
      IO.puts("El titulo no puede estar vacío.")
      solicitar_titulo()
    else
      titulo
    end
  end

  defp solicitar_descripcion do
    IO.write("Ingresa la descripcion del proyecto: ")
    descripcion = IO.read(:line) |> String.trim()

    if descripcion == "" do
      IO.puts("La descripcion no puede estar vacía.")
      solicitar_descripcion()
    else
      descripcion
    end
  end

  defp solicitar_categoria do
    IO.puts("Selecciona la categoria del proyecto:")
    IO.puts("1. Web")
    IO.puts("2. Mobile")
    IO.puts("3. AI/ML")
    IO.puts("4. Gaming")
    IO.puts("5. IoT")
    IO.puts("6. Desktop")
    IO.puts("7. Cloud")
    IO.puts("8. Security")
    IO.write("Elige una opción (1-8) o escribe tu propia categoria: ")

    input = IO.read(:line) |> String.trim()

    case input do
      "1" -> "Web"
      "2" -> "Mobile"
      "3" -> "AI/ML"
      "4" -> "Gaming"
      "5" -> "IoT"
      "6" -> "Desktop"
      "7" -> "Cloud"
      "8" -> "Security"
      categoria_personalizada when categoria_personalizada != "" ->
        categoria_personalizada
      _ ->
        IO.puts("Opcion invalida. Intenta de nuevo.")
        solicitar_categoria()
    end
  end

  defp actualizar_progreso_inicial(team_id) do
    IO.write("¿Quieres establecer un progreso inicial? (0-100, o Enter para mantener 0): ")
    input = IO.read(:line) |> String.trim()

    case input do
      "" ->
        IO.puts("Progreso mantenido en 0%")
        IO.puts("")

      progreso_str ->
        case Integer.parse(progreso_str) do
          {progreso, ""} when progreso >= 0 and progreso <= 100 ->
            # Usar ProjectService.actualizar_progreso/2
            case ProjectService.actualizar_progreso(team_id, progreso) do
              {:ok, _proyecto} ->
                IO.puts("Progreso actualizado a #{progreso}%")
                IO.puts("")
              {:error, mensaje} ->
                IO.puts("Error al actualizar progreso: #{mensaje}")
                IO.puts("")
            end

          _ ->
            IO.puts("Progreso inválido. Debe ser un número entre 0 y 100.")
            actualizar_progreso_inicial(team_id)
        end
    end
  end

  defp mostrar_resumen_final(nombre_equipo) do
    IO.puts("=== RESUMEN FINAL ===")

    case TeamService.obtener_equipo_por_nombre(nombre_equipo) do
      nil ->
        IO.puts("Error: No se pudo encontrar el equipo.")

      equipo ->
        IO.puts("Nombre del equipo: #{equipo.nombre}")
        IO.puts("ID del equipo: #{equipo.id}")
        IO.puts("Total miembros: #{length(equipo.miembros)}")
        IO.puts("")

        # Mostrar miembros
        if length(equipo.miembros) > 0 do
          IO.puts("MIEMBROS:")
          Enum.each(equipo.miembros, fn miembro ->
            IO.puts("   - ID: #{miembro.id}, Nombre: #{miembro.nombre}")
          end)
        else
          IO.puts("Sin miembros registrados.")
        end

        IO.puts("")

        # Mostrar proyecto si existe usando ProjectService.obtener_proyecto_por_equipo/1
        case ProjectService.obtener_proyecto_por_equipo(equipo.id) do
          nil ->
            IO.puts("Sin proyecto asignado")

          proyecto ->
            IO.puts("PROYECTO:")
            IO.puts("Titulo: #{proyecto.titulo}")
            IO.puts("Descripcion: #{proyecto.descripcion}")
            IO.puts("Categoria: #{proyecto.categoria}")
            IO.puts("Progreso: #{proyecto.progreso}%")
            IO.puts("Feedbacks: #{length(proyecto.feedbacks)}")
        end

        IO.puts("")

        # Mostrar mentor asignado
        mostrar_mentor_asignado(equipo.id)

        IO.puts("")
        IO.puts("Datos guardados en CSV")
        IO.puts("¡Todo listo para la hackathon!")
    end
  end

  defp mostrar_mentor_asignado(team_id) do
    teams_mentors = MentorService.listar_asignaciones_activas()
                   |> Enum.filter(fn asignacion -> asignacion.team_id == team_id end)

    if length(teams_mentors) > 0 do
      IO.puts("MENTOR ASIGNADO:")
      Enum.each(teams_mentors, fn asignacion ->
        mentores = MentorService.list_mentors()
        mentor = Enum.find(mentores, fn m -> m.id == asignacion.mentor_id end)

        if mentor do
          experiencia_str = Enum.join(mentor.experiencia, ", ")
          IO.puts("Nombre: #{mentor.nombre}")
          IO.puts("Experiencia: #{experiencia_str}")
          IO.puts("Asignado: #{DateTime.to_date(asignacion.assigned_at)}")

          feedbacks = MentorService.obtener_feedbacks_por_equipo(team_id)
          if length(feedbacks) > 0 do
            IO.puts("Feedbacks recibidos: #{length(feedbacks)}")
          end
        end
      end)
    else
      IO.puts("Sin mentor asignado")
    end
  end

end
