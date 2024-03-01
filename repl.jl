import REPL

function cmd_eval(mod, code)
   try 
       return string(Base.eval(mod, Meta.parse(code)))
   catch e
   end

   return nothing
end

function get_contextual_completion(mod, to_complete)
    expr = "REPL.REPLCompletions.completions(\"$(escape_string(to_complete))\", $(length(to_complete)))"
    completions_res = REPL.REPLCompletions.completions(String(to_complete), length(to_complete), mod)
    completions = completions_res[1]
    completion_range = completions_res[2]
    completion_success = completions_res[3] && !isempty(completions)

    if completion_success
        return completions, completion_range
    else
        return REPL.REPLCompletions.Completion[], 1:1
    end
end

function completion_to_menu_item(repl_completion)
    completion_cmd = ""
    completion_handled = true
    if repl_completion isa REPL.REPLCompletions.BslashCompletion
        completion_text = REPL.REPLCompletions.completion_text(repl_completion)
        final_completion = REPL.REPLCompletions.bslash_completions(completion_text, length(completion_text))[2][1]
        completion_info = REPL.REPLCompletions.completion_text(final_completion[1])
        completion_menu = "$(completion_text)   {MenuInfo}$(completion_info)"
    elseif repl_completion isa REPL.REPLCompletions.ModuleCompletion
        completion_text = REPL.REPLCompletions.completion_text(repl_completion)
        completion_menu = "$(repl_completion.mod)   {MenuInfo}$(repl_completion.mod)"
    else
        completion_handled = false
    end

    if completion_handled
        return "\"$completion_text|$completion_cmd|$completion_menu\""
    end
    return nothing
end

function cmd_complete(mod, to_complete)
    completions, completion_range = get_contextual_completion(mod, to_complete)

    kakoune_completions = String[]
    for c in completions
       menu_item = completion_to_menu_item(c)

       if menu_item != nothing
           push!(kakoune_completions, menu_item)
       end
    end

    if !isempty(kakoune_completions)
       to_output = "$(completion_range.start):$(length(completion_range))"
       to_output *= " "
       to_output *= join(kakoune_completions, " ")
       return to_output
    else
       return nothing
    end
end

function main()
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
            # complete code
            # reset
            #  |
            #  --> resets the module state
            # quit

            cmd_end = findfirst(' ', command)
            if cmd_end == nothing
                cmd_end = length(command)+1
            end
            # rstrip removes an eventual newline for quit/reset
            cmd_name = rstrip(command[1:cmd_end-1])

            to_output = nothing
            if cmd_name == "eval"
                to_output = cmd_eval(repl_module, rstrip(command[cmd_end+1:end]))
            elseif cmd_name == "complete"
                to_output = cmd_complete(repl_module, rstrip(command[cmd_end+1:end]))
            elseif cmd_name == "reset"
               repl_module = Module()
            elseif cmd_name == "quit"
               is_running = false
            end 

            if to_output != nothing
                open(output_fifo_path, "w") do fifo
                    print(fifo, to_output)
                end
            end
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

