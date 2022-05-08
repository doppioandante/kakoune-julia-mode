using Test
import REPL

include("../repl.jl")

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
    end

    @testset "completion_to_kak" begin
        mod = Module()
        completions, _ = get_contextual_completion(mod, "print")

        menu_item = completion_to_menu_item(completions[1])
        @test menu_item == "\"print||print   {MenuInfo}print\""

        completions, _ = get_contextual_completion(mod, "\\lamb")

        menu_item = completion_to_menu_item(completions[1])
        @test menu_item == "\"\\lambda||\\lambda   {MenuInfo}λ\""
    end

    @testset "cmd_complete" begin
        mod = Module()
        kak_input = cmd_complete(mod, "print")
        @test kak_input == "1:5 \"print||print   {MenuInfo}print\" \"println||println   {MenuInfo}println\" \"printstyled||printstyled   {MenuInfo}printstyled\""
    end
end
