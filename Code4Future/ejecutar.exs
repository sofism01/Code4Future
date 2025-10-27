# ejecutar.exs
Code.compile_file("domain/participant.ex")
Code.compile_file("domain/team.ex")
Code.compile_file("services/team_service.ex")
Code.compile_file("main.exs")

Main.main()
