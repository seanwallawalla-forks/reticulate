
#' Install Python
#'
#' Download and install Python, using the [pyenv](https://github.com/pyenv/pyenv).
#' and [pyenv-win](https://github.com/pyenv-win/pyenv-win) projects.
#'
#' In general, it is recommended that Python virtual environments are created
#' using the copies of Python installed by [install_python()]. For example:
#'
#' ```
#' library(reticulate)
#' version <- "3.8.10"
#' install_python(version)
#' virtualenv_create("my-environment", version = version)
#' use_virtualenv("my-environment")
#'
#' # There is also support for a ":latest" suffix to select the latest patch release
#' install_python("3.8:latest") # install latest patch available at python.org
#'
#' # select the latest 3.8.* patch installed locally
#' virtualenv_create("my-environment", version = "3.8:latest")
#' ```
#'
#' @param version The version of Python to install.
#'
#' @param list Boolean; if set, list the set of available Python versions?
#'
#' @param force Boolean; force re-installation even if the requested version
#'   of Python is already installed?
#'
#' @note On macOS and Linux this will build Python from sources, which may take a few minutes.
#' @export
install_python <- function(version = "3.8:latest",
                           list = FALSE,
                           force = FALSE)
{
  # resolve pyenv path
  pyenv <- pyenv_find()
  if (!file.exists(pyenv))
    stop("could not locate 'pyenv' binary")

  # if list is set, then list available versions instead
  if (identical(list, TRUE))
    return(pyenv_list(pyenv = pyenv))

  if(endsWith(version, ":latest"))
    version <-
      pyenv_resolve_latest_patch(version, installed = FALSE, pyenv = pyenv)

  # install the requested package
  status <- pyenv_install(version, force, pyenv = pyenv)
  if (!identical(status, 0L))
    stopf("installation of Python %s failed", version)

  # ensure that virtualenv is installed for older versions of Python
  python <- pyenv_python(version = version)
  version <- python_version(python)
  if (version < "3.5" && !python_has_module(python, "virtualenv"))
    pip_install(python, "virtualenv")

  # return path to python
  python

}
