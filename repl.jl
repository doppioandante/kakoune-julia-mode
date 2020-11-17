import REPL

function create_repl_module()
    repl_module = Module()
    Base.eval(repl_module, Meta.parse("import REPL"))
    return repl_module
end

repl_module = create_repl_module()
is_running = true
while is_running
    input_fifo_path = ARGS[1]
    output_fifo_path = ARGS[2]

    open(input_fifo_path, "r") do input_fifo

        command = read(input_fifo, String)
        # input command format:
        # eval code
        #  |
        #  --> evals line of code. \n is interpreted as newline
        # eval_scratch code
        # complete code
        # reset
        #  |
        #  --> resets the module state
        # quit

        cmd_end = findfirst(' ', command)
        if cmd_end == nothing
            cmd_end = length(command)+1
        end

        cmd_name = command[1:cmd_end-1]
        if cmd_name == "eval"
           try 
               result = Base.eval(repl_module, Meta.parse(command[cmd_end+1:end]))
               open(output_fifo_path, "w") do fifo
                   print(fifo, result)
               end
           catch e
           end
        elseif cmd_name == "complete"
           to_complete = rstrip(command[cmd_end+1:end])
           expr = "REPL.REPLCompletions.completions(\"$(escape_string(to_complete))\", $(length(to_complete)))"
           println(expr)
           completions_res = Base.eval(repl_module, Meta.parse(expr))
           completions = completions_res[1]
           completion_range = completions_res[2]
           text_completions = String[]
           completion_success = completions_res[3] && !isempty(completion_range) && !isempty(completions)
           if completion_success
               for c in completions
                   push!(text_completions, REPL.REPLCompletions.completion_text(c))
               end
           end
           
           open(output_fifo_path, "w") do fifo
               if completion_success
                   output = "$(completion_range.start):$(length(completion_range))"
                   output *= " "
                   output *= join(["\"$c||$c\"" for c in text_completions], " ")
                   print(fifo, output)
                   println(output)
               end
           end
        elseif cmd_name == "reset"
           global repl_module = create_repl_module()
        elseif cmd_name == "quit"
           global is_running = false
        end 
       flush(stdout)
    end
end
