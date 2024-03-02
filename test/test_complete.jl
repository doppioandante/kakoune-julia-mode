using Test
import REPL

include("../repl.jl")

@testset "call cmd_complete with substring" begin
    s = "print"
    substring = s[1:4]
    cmd_complete(Module(), substring)
    @test true
end

@testset "simple eval test" begin
    mod = Module()
    res = cmd_eval(mod, "1 + 1")
    @test res == "2"
end


@testset "completion test" begin
    @testset "get_contextual_completion" begin
        mod = Module()
        completions, crange = get_contextual_completion(mod, "print")
        @test crange == 1:5
        @test length(completions) > 0

        completions, crange = get_contextual_completion(mod, "\\lamb")
        @test crange == 1:5
        @test length(completions) == 1
        @test REPL.REPLCompletions.completion_text(completions[1]) == "\\lambda"

        completions, crange = get_contextual_completion(mod, "\\lambda")
        @test crange == 1:7
        @test length(completions) == 1
        @test REPL.REPLCompletions.completion_text(completions[1]) == "λ"

        completions, crange = get_contextual_completion(mod, "NonExistent.")
        @test crange == 1:1
        @test length(completions) == 0

        completions, crange = get_contextual_completion(mod, "Base.")
        @test crange == 6:5
        @test length(completions) > 0

        completions, crange = get_contextual_completion(mod, "Base.print")
        @test REPL.REPLCompletions.completion_text(completions[1]) == "print"
        @test crange == 6:10
    end

    @testset "completion_to_kak" begin
        mod = Module()
        completions, _ = get_contextual_completion(mod, "print")

        menu_item = completion_to_menu_item(completions[1]; mod_completion = false, to_complete = "print")
        @test menu_item == "\"print||print   {MenuInfo}print\""

        completions, _ = get_contextual_completion(mod, "\\lamb")

        menu_item = completion_to_menu_item(completions[1]; mod_completion = false, to_complete = "print")
        @test menu_item == "\"\\lambda||\\lambda   {MenuInfo}λ\""

        cmd_eval(mod, "module MyModule; field = 1; end")
        completions, crange = get_contextual_completion(mod, "MyModule.")
        @test crange == 10:9
        @test length(completions) > 0

        menu_item = completion_to_menu_item(completions[1]; mod_completion = true, to_complete = "MyModule.")
        @test menu_item == "\"MyModule.eval||eval   {MenuInfo}eval\""
    end

    @testset "cmd_complete" begin
        mod = Module()
        kak_input = cmd_complete(mod, "print")
        @test kak_input == "1:5 \"print||print   {MenuInfo}print\" \"println||println   {MenuInfo}println\" \"printstyled||printstyled   {MenuInfo}printstyled\""

        cmd_eval(mod, "module MyModule; field = 1; end")
        kak_input = cmd_complete(mod, "MyModule.")
        @test kak_input == "1:9 \"MyModule.eval||eval   {MenuInfo}eval\" \"MyModule.field||field   {MenuInfo}field\" \"MyModule.include||include   {MenuInfo}include\""
    end
end
