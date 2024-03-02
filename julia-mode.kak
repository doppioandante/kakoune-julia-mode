declare-option -hidden str julia_mode_source %val{source}

provide-module julia-mode %[

# common FIFO dir for the same kakoune session
declare-option -hidden str julia_mode_dir "/tmp/julia_mode_kakoune/%val{session}"
# julia mode source code (Julia scripts)
declare-option -hidden str julia_mode_eval_output ''

declare-option completions julia_mode_completions

define-command -docstring 'julia-mode-start: Create a background julia REPL for the current kakoune session' \
    julia-mode-start %{ 
    nop %sh{
        dir=$kak_opt_julia_mode_dir
        if [ ! -d ${dir} ]; then
            mkdir -p ${dir}
            mkfifo ${dir}/in ${dir}/out
            ( julia ${kak_opt_julia_mode_source%/*}/repl.jl ${dir}/in ${dir}/out
            )>/dev/null 2>&1 </dev/null &
        fi
    }
}

define-command julia-mode-enable-autocomplete -docstring "Add julia completion candidates to the completer" %{
    set-option window completers option=julia_mode_completions %opt{completers}

    hook window InsertIdle .* %{ try %{
        evaluate-commands -draft %{
            execute-keys <a-h> <a-semicolon>
            julia-mode-complete
        }
    } }
}

define-command julia-mode-complete -docstring "Complete the current selection through the julia REPL" %{
    nop %sh{
        (
            if [ -d ${kak_opt_julia_mode_dir} ]; then
                printf %s\\n "debug hey!"
                (printf 'complete %s' "$kak_selection" > $kak_opt_julia_mode_dir/in) > /dev/null 2>&1 </dev/null
                completion_result=$(cat $kak_opt_julia_mode_dir/out)
                if [ ! -z "${completion_result}" ]; then
                    completion_range=$(printf '%s' "${completion_result}" | cut -d " " -f 1)
                    completion_start=$(printf '%s' "${completion_range}" | cut -d ":" -f 1)
                    completion_len=$(printf '%s' "${completion_range}" | cut -d ":" -f 2)
                    completion_entries=$(printf '%s' "${completion_result}" | cut -d " " -f 2-)

                    completion_header="$kak_cursor_line.$completion_start+$completion_len@$kak_timestamp"
                    printf %s\\n "evaluate-commands -client '${kak_client}' %{ set-option 'buffer=${kak_buffile}' julia_mode_completions \"$completion_header\" $completion_entries  }" | kak -p ${kak_session}
                fi
            fi
        ) > /dev/null 2>&1 < /dev/null &
    }
}


define-command -docstring 'julia-mode-eval: evaluate current cursor selection in the julia REPL' \
    julia-mode-eval %{

    evaluate-commands  -itersel -draft %{
        evaluate-commands  %sh{
            (printf "eval $kak_selection" > $kak_opt_julia_mode_dir/in) > /dev/null 2>&1 </dev/null
            result=$(cat $kak_opt_julia_mode_dir/out)
            escaped_result=$(printf '%s' "$result" | sed  -e "s/'/''/g")
            printf "set-option global julia_mode_eval_output '%s'\n" "$escaped_result"
        }

        evaluate-commands  -save-regs r %{
            set-register r "%opt{julia_mode_eval_output}"
            execute-keys 'A<space><esc>"r<s-p>' 
        }
    }
}

hook global KakEnd .* %{
    nop %sh{
        if [ -d ${kak_opt_julia_mode_dir} ]; then
            (printf 'quit\n' > $kak_opt_julia_mode_dir/in) > /dev/null 2>&1 </dev/null &
            rm -rf ${kak_opt_julia_mode_dir}
        fi
    }
}

]

