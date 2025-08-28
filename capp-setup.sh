export CAPP_ROOT=$PWD
capp () {
  # Convert the Bash function arguments into a semicolon-separated CMake list
  arglist="$(printf ';%s' "$@")"
  case $1 in
    "load"|"unload")
      stdout="$(cmake -DCAPP_CMDLINE_ARGS="$arglist" -P "$CAPP_ROOT/capp.cmake")" || return
      eval "$stdout"
      unset stdout
      ;;
    *)
      cmake -DCAPP_CMDLINE_ARGS="$arglist" -P "$CAPP_ROOT/capp.cmake"
      ;;
  esac
}
