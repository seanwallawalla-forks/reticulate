
pip_version <- function(python) {

  # if we don't have pip, just return a placeholder version
  if (!file.exists(python))
    return(numeric_version("0.0"))

  # otherwise, ask pip what version it is
  command <- "import sys; import pip; sys.stdout.write(pip.__version__)"
  version <- system2(python, c("-c", shQuote(command)), stdout = TRUE, stderr = TRUE)

  # remove any beta components from version string
  idx <- regexpr("[[:alpha:]]", version)
  if (idx != -1)
    version <- substring(version, 1, idx - 1)

  # construct numeric version
  numeric_version(version)

}

pip_install <- function(python,
                        packages,
                        pip_options = character(),
                        ignore_installed = FALSE,
                        conda = "auto",
                        envname = NULL)
{
  # construct command line arguments
  args <- c("-m", "pip", "install", "--upgrade")
  if (ignore_installed)
    args <- c(args, "--ignore-installed")
  args <- c(args, pip_options)

  # quote in case of version constraints like 'Pillow<8.3'
  # but don't double quote if already quoted
  packages <- shQuote(gsub("[\"']", "", packages))
  args <- c(args, packages)

  # figure out if we should go though conda_run()
  if (conda == "auto") {
    info <- python_info(python)
    if (info$type != "conda" || numeric_conda_version(info$conda) < "4.9")
      conda <- NULL
  }

  result <- if (is.null(conda) || identical(conda, FALSE))
    system2t(python, args)
  else
    conda_run2(python, args, conda = conda, envname = envname)


  if (result != 0L) {
    pkglist <- paste(shQuote(packages), collapse = ", ")
    msg <- paste("Error installing package(s):", pkglist)
    stop(msg, call. = FALSE)
  }

  invisible(packages)
}

pip_uninstall <- function(python, packages) {

  # run it
  args <- c("-m", "pip", "uninstall", "--yes", packages)
  result <- system2t(python, args)
  if (result != 0L) {
    pkglist <- paste(shQuote(packages), collapse = ", ")
    msg <- paste("Error removing package(s):", pkglist)
    stop(msg, call. = FALSE)
  }

  packages

}

pip_freeze <- function(python) {

  # run pip freeze to list dependencies
  args <- c("-m", "pip", "freeze")
  output <- system2(python, args, stdout = TRUE)

  # match explicit version requests + direct references
  matches <- strsplit(output, "(==|@)")

  # keep original output string
  matches <- .mapply(c, list(matches, output), MoreArgs = NULL)

  # drop unmatched lines
  n <- vapply(matches, length, FUN.VALUE = numeric(1))
  matches <- matches[n == 3]

  # build output columns
  packages    <- vapply(matches, `[[`, 1L, FUN.VALUE = character(1))
  versions    <- vapply(matches, `[[`, 2L, FUN.VALUE = character(1))
  requirement <- vapply(matches, `[[`, 3L, FUN.VALUE = character(1))

  # return as data.frame
  data.frame(
    package     = packages,
    version     = versions,
    requirement = requirement,
    stringsAsFactors = FALSE
  )

}
