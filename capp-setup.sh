export CAPP_ROOT=$PWD
capp () {
  # Convert the Bash function arguments into a semicolon-separated CMake list
  arglist="$(printf ';%q' "$@")"
  stdout="$(cmake -DCAPP_CMDLINE_ARGS="$arglist" -P "$CAPP_ROOT/capp.cmake")" || return
  case $1 in
    "load"|"unload")
      eval "$stdout"
      ;;
    *)
      echo "$stdout"
  esac
}
