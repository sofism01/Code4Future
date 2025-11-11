# ejecutar.exs
Code.compile_file("domain/participant.ex")
Code.compile_file("domain/message.ex")
Code.compile_file("domain/project.ex")
Code.compile_file("domain/mentor.ex")
Code.compile_file("domain/team.ex")

Code.compile_file("services/team_service.ex")
Code.compile_file("services/project_service.ex")
Code.compile_file("services/mentor_service.ex") 

Code.compile_file("main.exs")

Main.main()
