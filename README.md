# kakoune-julia-mode
Julia completion and evaluation for Kakoune

## Autocompletion
This enables julia autocompletion on julia files:
```
require-module julia-mode

hook global WinSetOption filetype=julia %{
    set buffer indentwidth 0
    julia-mode-start
    julia-mode-enable-autocomplete
}
```

## Evaluation
Select a snippet of code and then run execute `:julia-mode-eval`.
The background Julia session is mantained alive between evaluations, so you can use variables and so on.
