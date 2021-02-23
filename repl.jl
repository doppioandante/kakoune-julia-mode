import REPL

repl_module = Module()
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
           completions_res = REPL.REPLCompletions.completions(String(to_complete), length(to_complete), repl_module)
           completions = completions_res[1]
           completion_range = completions_res[2]
           kakoune_completions = String[]
           completion_success = completions_res[3] && !isempty(completion_range) && !isempty(completions)
           if completion_success
               for c in completions
                   completion_cmd = ""
                   completion_unhandled = false
                   if c isa REPL.REPLCompletions.BslashCompletion
	                   completion_text = REPL.REPLCompletions.completion_text(c)
                       completion_cmd = "echo \'a\'"
	                   completion_menu = completion_text
                   elseif c isa REPL.REPLCompletions.ModuleCompletion
	                   completion_text = REPL.REPLCompletions.completion_text(c)
                       completion_cmd = ""
                       completion_menu = "$(c.mod)   {MenuInfo}$(c.mod)"
                   else
                       completion_unhandled = true
                   end

                   if !completion_unhandled
	                   push!(kakoune_completions, "\"$completion_text|$completion_cmd|$completion_menu\"")
                   end
               end
           end
           completion_success &= !isempty(kakoune_completions)
           open(output_fifo_path, "w") do fifo
               if completion_success
                   output = "$(completion_range.start):$(length(completion_range))"
                   output *= " "
                   output *= join(kakoune_completions, " ")
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
