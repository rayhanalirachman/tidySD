## ---------------------------------------------------------------------------
## Import: an XMILE file -> the three layers plus a sim_spec.
##
## Only what a run needs is read: stocks, flows, auxes, graphical functions,
## initial values and the sim specs. Everything cosmetic (views, XY positions,
## colours, fonts, docs) is ignored on purpose.
## ---------------------------------------------------------------------------

#' Import a model from an XMILE or Vensim file
#'
#' Reads an XMILE model (`.xmile`, `.stmx`, `.itmx`, `.xml` -- the interchange
#' format written by Stella, Vensim, InsightMaker and friends) or a Vensim
#' text model (`.mdl`) and returns the
#' three tidysd layers plus a [sim_spec()], ready for [simulate()].
#'
#' Stocks, flows, auxiliaries, graphical (lookup) functions, initial values,
#' units and the simulation specs are read. Diagram information is not.
#' An auxiliary whose equation is a bare number becomes a [constant()]; every
#' other auxiliary becomes an [aux()] with an equation.
#'
#' Arrayed (subscripted) models, submodules and conveyors/queues are rejected
#' rather than silently mis-translated.
#'
#' @param path Path to the file. The format is taken from the extension.
#' @return A list with `structure`, `equations`, `parameters` and `spec`, to be
#'   passed to [simulate()] or [sd_validate()].
#' @examples
#' m <- sd_import(system.file("extdata", "sir.xmile", package = "tidysd"))
#' sd_variables(m$structure)
#' out <- simulate(m$structure, m$equations, m$parameters, spec = m$spec)
#' head(out)
#' @export
sd_import <- function(path) {
  if (!file.exists(path)) sd_abort(sprintf("No such file: '%s'.", path))
  ext <- tolower(sub(".*\\.", "", basename(path)))
  if (identical(ext, "mdl")) return(parse_mdl(path))
  if (!ext %in% c("xmile", "stmx", "itmx", "xml"))
    sd_abort(sprintf("`sd_import()` does not know how to read a '.%s' file.", ext),
             i = "It reads XMILE (.xmile, .stmx, .itmx, .xml) and Vensim (.mdl).")
  import_xmile(path)
}

x_node <- function(node, xpath) {
  v <- xml2::xml_find_first(node, xpath)
  if (inherits(v, "xml_missing")) NULL else v
}

x_text <- function(node, xpath) {
  v <- x_node(node, xpath)
  if (is.null(v)) NULL else trimws(xml2::xml_text(v))
}

x_num <- function(node, xpath) {
  v <- x_text(node, xpath)
  if (is.null(v) || !nzchar(v)) NULL else suppressWarnings(as.numeric(v))
}

## "12" -> 12, anything else -> NULL.
as_literal <- function(s) {
  if (is.null(s) || !nzchar(s)) return(NULL)
  v <- suppressWarnings(as.numeric(s))
  if (is.na(v)) NULL else v
}

xmile_import_name <- function(x) {
  x <- gsub("\\\\n", " ", x)
  make.names(gsub("[^A-Za-z0-9_]+", "_", trimws(x)))
}

import_xmile <- function(path) {
  doc <- xml2::read_xml(path)
  xml2::xml_ns_strip(doc)

  for (bad in c("dimensions/dim", "module", "conveyor", "queue")) {
    if (length(xml2::xml_find_all(doc, paste0(".//", bad))))
      sd_abort(sprintf("This XMILE model uses <%s>, which `sd_import()` does not read.",
                       sub(".*/", "", bad)),
               i = "Flat, unsubscripted stock-and-flow models import cleanly.")
  }

  model <- x_node(doc, ".//model")
  if (is.null(model)) sd_abort("No <model> element in this XMILE file.")

  nodes <- xml2::xml_find_all(model, "./variables/*")
  kinds <- xml2::xml_name(nodes)
  # ponytail: standalone <gf> definitions and <group> wrappers are skipped;
  # revisit if a real model turns up that defines its lookups that way.
  keep <- kinds %in% c("stock", "flow", "aux")
  nodes <- nodes[keep]; kinds <- kinds[keep]
  if (!length(nodes)) sd_abort("This XMILE model declares no stocks, flows or auxes.")

  raw <- vapply(nodes, function(n) trimws(xml2::xml_attr(n, "name")), character(1))
  nms <- xmile_import_name(raw)
  dup <- nms[duplicated(nms)]
  if (length(dup))
    sd_abort(sprintf("Two XMILE variables map to the same R name: %s.", comma(unique(dup))))
  names(nodes) <- names(kinds) <- nms

  ## ---- flow wiring: XMILE hangs it off the stocks -------------------------
  from <- to <- stats::setNames(vector("list", length(nms)), nms)
  for (i in which(kinds == "stock")) {
    st <- nms[[i]]
    for (f in xmile_import_name(xml2::xml_text(xml2::xml_find_all(nodes[[i]], "./inflow"))))
      if (f %in% nms) to[[f]] <- st
    for (f in xmile_import_name(xml2::xml_text(xml2::xml_find_all(nodes[[i]], "./outflow"))))
      if (f %in% nms) from[[f]] <- st
  }

  els <- list()
  eqs <- list()
  consts <- list()
  inits <- list()
  lk_data <- list()

  for (i in seq_along(nodes)) {
    n <- nodes[[i]]; nm <- nms[[i]]
    units <- x_text(n, "./units")
    label <- if (!identical(raw[[i]], nm)) gsub("\\\\n", " ", raw[[i]]) else NULL
    eqn <- x_text(n, "./eqn") %||% ""

    if (kinds[[i]] == "stock") {
      els[[length(els) + 1L]] <- stock(nm, units = units, label = label,
                                       non_negative = !is.null(x_node(n, "./non_negative")))
      lit <- as_literal(eqn)
      if (!is.null(lit)) inits[[nm]] <- lit
      else eqs[[length(eqs) + 1L]] <-
        rlang::new_formula(call("init", as.symbol(nm)), xmile_import_expr(eqn, nms, raw, nm))
      next
    }

    gf <- x_node(n, "./gf")
    rhs <- xmile_import_expr(eqn, nms, raw, nm)
    if (!is.null(gf)) {
      lk_nm <- paste0(nm, "_gf")
      if (lk_nm %in% nms) sd_abort(sprintf("Cannot name the lookup for '%s': '%s' is taken.",
                                           nm, lk_nm))
      g <- xmile_import_gf_points(gf, nm)
      els[[length(els) + 1L]] <- lookup(lk_nm, input = deparse1_(rhs),
                                        interp = g$interp, range = g$range)
      lk_data[[lk_nm]] <- lookup_data(lk_nm, g$x, g$y)
      rhs <- as.call(list(as.symbol(lk_nm), rhs))
    }

    if (kinds[[i]] == "flow") {
      # ponytail: a flow's <non_negative/> (uniflow) is dropped; tidysd flows are
      # biflows. Revisit if an imported model relies on the clamp.
      els[[length(els) + 1L]] <- flow(nm, from = from[[nm]] %||% .source,
                                      to = to[[nm]] %||% .sink,
                                      units = units, label = label)
    } else {
      lit <- if (is.null(gf)) as_literal(eqn) else NULL
      if (!is.null(lit)) { consts[[nm]] <- lit; next }
      els[[length(els) + 1L]] <- aux(nm, units = units, label = label)
    }
    eqs[[length(eqs) + 1L]] <- rlang::new_formula(as.symbol(nm), rhs)
  }

  nm_meta <- x_text(doc, ".//header/name") %||% sub("\\.[^.]*$", "", basename(path))
  els <- c(list(meta(name = nm_meta, source = basename(path))), els)

  pars <- list()
  if (length(consts)) pars <- c(pars, list(do.call(constant, consts)))
  if (length(inits)) pars <- c(pars, list(do.call(initial, inits)))
  pars <- c(pars, unname(lk_data))

  list(
    structure = do.call(sd_structure, els),
    equations = do.call(sd_equations, eqs),
    parameters = do.call(sd_parameters, pars),
    spec = xmile_spec(doc)
  )
}

xmile_spec <- function(doc) {
  ss <- x_node(doc, ".//sim_specs")
  if (is.null(ss)) return(sim_spec(check_units = FALSE))
  dt <- x_num(ss, "./dt") %||% 1
  dtn <- x_node(ss, "./dt")
  if (!is.null(dtn) && identical(xml2::xml_attr(dtn, "reciprocal"), "true")) dt <- 1 / dt
  method <- if (grepl("rk4|runge", tolower(xml2::xml_attr(ss, "method") %||% ""))) "rk4" else "euler"
  # ponytail: units are read but not checked -- an imported unit string was not
  # written for tidysd's algebra. Flip `check_units` on by hand if you want it.
  sim_spec(start = x_num(ss, "./start") %||% 0,
           stop = x_num(ss, "./stop") %||% 100,
           dt = dt, method = method,
           time_unit = nzchar_or_null(xml2::xml_attr(ss, "time_units")),
           saveat = x_num(ss, "./savestep"),
           check_units = FALSE)
}

nzchar_or_null <- function(x) if (is.null(x) || is.na(x) || !nzchar(x)) NULL else x

## A <gf>: either explicit <xpts>, or an <xscale> spread over the <ypts>.
xmile_import_gf_points <- function(gf, nm) {
  nums <- function(s) as.numeric(strsplit(gsub("\\s", "", s), ",")[[1]])
  y <- x_text(gf, "./ypts")
  if (is.null(y)) sd_abort(sprintf("The graphical function of '%s' has no <ypts>.", nm))
  y <- nums(y)
  xs <- x_text(gf, "./xpts")
  x <- if (!is.null(xs)) nums(xs) else {
    sc <- x_node(gf, "./xscale")
    if (is.null(sc)) sd_abort(sprintf("The graphical function of '%s' has no x values.", nm))
    seq(as.numeric(xml2::xml_attr(sc, "min")), as.numeric(xml2::xml_attr(sc, "max")),
        length.out = length(y))
  }
  if (length(x) != length(y) || anyNA(x) || anyNA(y))
    sd_abort(sprintf("The graphical function of '%s' has unreadable points.", nm))
  type <- tolower(xml2::xml_attr(gf, "type") %||% "continuous")
  list(x = x, y = y,
       interp = if (identical(type, "discrete")) "constant" else "linear",
       range = if (identical(type, "extrapolate")) "extend" else "clamp")
}

## XMILE function names -> tidysd / base R. Anything not listed is left alone,
## so an unsupported function fails loudly when the model is bound.
# ponytail: PULSE is deliberately absent -- XMILE's PULSE(volume, first,
# interval) is not tidysd's pulse(start, width). Map it when someone needs it.
XMILE_IMPORT_FNS <- c(
  ABS = "abs", MIN = "min", MAX = "max", EXP = "exp", LN = "log", LOG10 = "log10",
  SQRT = "sqrt", SIN = "sin", COS = "cos", TAN = "tan", ARCTAN = "atan",
  INT = "trunc", ROUND = "round", MEAN = "mean", SUM = "sum", MOD = "%%",
  TIME = "t", DT = "dt", PI = "pi", STEP = "step", RAMP = "ramp",
  SMTH1 = "smoothN", SMOOTH = "smoothN", SMTH3 = ".gf3_smooth", SMOOTH3 = ".gf3_smooth",
  DELAY1 = "delayN", DELAY3 = ".gf3_delay", DELAY = "delay_fixed",
  FORECAST = "forecast", PREVIOUS = "previous", SELF = "self"
)

rx_escape <- function(x) gsub("([\\^$.|?*+()\\[\\]{}\\\\])", "\\\\\\1", x, perl = TRUE)

## Translate one XMILE equation string into an R expression.
xmile_import_expr <- function(eqn, nms, raw, where, fmt = "XMILE") {
  s <- gsub("\\{[^}]*\\}", " ", eqn)          # XMILE comments
  s <- gsub("[\r\n]+|\\\\n", " ", s)
  ## a bare `=` in XMILE is a comparison; park the two-character operators first
  s <- gsub("<>", "@NE@", s, fixed = TRUE)
  s <- gsub("<=", "@LE@", s, fixed = TRUE)
  s <- gsub(">=", "@GE@", s, fixed = TRUE)
  s <- gsub("=", "==", s, fixed = TRUE)
  s <- gsub("@NE@", "!=", s, fixed = TRUE)
  s <- gsub("@LE@", "<=", s, fixed = TRUE)
  s <- gsub("@GE@", ">=", s, fixed = TRUE)
  # ponytail: one IF ... THEN ... ELSE per equation, not nested. Nested
  # conditionals need a real tokeniser; write one when a model needs it.
  s <- gsub("\\bIF\\b(.+?)\\bTHEN\\b(.+?)\\bELSE\\b(.+)", "ifelse(\\1,\\2,\\3)",
            s, perl = TRUE, ignore.case = TRUE)
  s <- gsub("\\bAND\\b", "&", s, perl = TRUE, ignore.case = TRUE)
  s <- gsub("\\bOR\\b", "|", s, perl = TRUE, ignore.case = TRUE)
  s <- gsub("\\bNOT\\b", "!", s, perl = TRUE, ignore.case = TRUE)

  ## variable names first (longest first), so "max capacity" never meets the
  ## function table. XMILE treats spaces and underscores as the same character.
  o <- order(nchar(raw), decreasing = TRUE)
  for (i in o) {
    pat <- gsub("[ _]+", "[ _]+", rx_escape(gsub("\\\\n", " ", trimws(raw[[i]]))))
    s <- gsub(paste0("(?i)(?<![A-Za-z0-9_.])", pat, "(?![A-Za-z0-9_.])"), nms[[i]], s, perl = TRUE)
  }
  for (f in names(XMILE_IMPORT_FNS))
    s <- gsub(paste0("(?i)(?<![A-Za-z0-9_.])", f, "(?![A-Za-z0-9_.])"), XMILE_IMPORT_FNS[[f]], s,
              perl = TRUE)

  ex <- tryCatch(str2lang(s), error = function(e) NULL)
  if (is.null(ex))
    sd_abort(sprintf("Could not translate the %s equation for '%s'.", fmt, where),
             x = eqn)
  third_order(ex)
}

## SMTH3/DELAY3 are the order-3 cases of smoothN/delayN.
third_order <- function(ex) {
  if (!is.call(ex)) return(ex)
  for (i in seq_along(ex)[-1]) if (!missing_arg_at(ex, i)) ex[[i]] <- third_order(ex[[i]])
  if (is.symbol(ex[[1]])) {
    h <- as.character(ex[[1]])
    if (h %in% c(".gf3_smooth", ".gf3_delay")) {
      ex[[1]] <- as.symbol(if (h == ".gf3_smooth") "smoothN" else "delayN")
      ex$order <- 3
    }
  }
  ex
}

missing_arg_at <- function(ex, i) identical(ex[[i]], quote(expr = ))

## ---------------------------------------------------------------------------
## Import: a Vensim .mdl file -> the same four pieces as the XMILE path.
##
## The format is plain text: `|`-terminated blocks of `LHS = RHS ~ units ~ doc`.
## Splitting on `|` then `~` is all the parsing this needs, so there is no
## tokeniser here; the equation *bodies* go through the XMILE translator above,
## which Vensim's expression syntax is near enough to.
##
## ponytail: deliberately unsupported -- subscripts/arrays (`Var[Dim]`) and
## `:MACRO:` blocks abort by name; lookup tables (`([(0,0)-(1,1)],(0,0)...)`,
## `WITH LOOKUP`) abort too, because reusing the <gf> path would mean parsing
## Vensim's point syntax for no model that has asked for it yet; sketch/view
## sections and quoted "names with punctuation" are dropped silently.
## ---------------------------------------------------------------------------

MDL_CONTROLS <- c("INITIAL TIME", "FINAL TIME", "TIME STEP", "SAVEPER")

parse_mdl <- function(path) {
  txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
  cut <- regexpr("\\\\\\---///", txt, fixed = TRUE)       # sketch section
  if (cut > 0) txt <- substr(txt, 1, cut - 1)
  if (grepl(":MACRO:", txt, fixed = TRUE))
    sd_abort("This Vensim model defines a :MACRO:, which `sd_import()` does not read.")

  ctrl <- list()
  raw <- eqn <- units <- character(0)

  for (b in strsplit(txt, "|", fixed = TRUE)[[1]]) {
    part <- strsplit(b, "~", fixed = TRUE)[[1]]
    lhs_rhs <- gsub("\\{[^}]*\\}", " ", part[[1]])        # inline comments
    lhs_rhs <- trimws(gsub("[\r\n\t]+", " ", lhs_rhs))
    at <- regexpr("=", lhs_rhs, fixed = TRUE)
    if (at < 1) next                                      # group banners, docs
    nm <- trimws(substr(lhs_rhs, 1, at - 1))
    rhs <- trimws(substr(lhs_rhs, at + 1, nchar(lhs_rhs)))
    if (!nzchar(nm) || !nzchar(rhs)) next
    if (grepl("[][]", nm) || grepl("\\[\\s*\\(", rhs))
      sd_abort(sprintf("'%s' uses %s, which `sd_import()` does not read.", nm,
                       if (grepl("[][]", nm)) "subscripts (arrays)" else "a lookup table"),
               i = "Flat, unsubscripted models without lookup tables import cleanly.")
    if (grepl("WITH\\s+LOOKUP", rhs, ignore.case = TRUE))
      sd_abort(sprintf("'%s' uses WITH LOOKUP, which `sd_import()` does not read.", nm))

    key <- toupper(gsub("\\s+", " ", nm))
    if (key %in% MDL_CONTROLS) { ctrl[[key]] <- as_literal(rhs); next }
    raw <- c(raw, nm)
    eqn <- c(eqn, rhs)
    u <- trimws(sub("\\[.*", "", part[2] %||% ""))
    units <- c(units, if (is.na(u) || !nzchar(u)) NA_character_ else u)
  }
  if (!length(raw)) sd_abort("This Vensim model declares no equations.")

  nms <- xmile_import_name(raw)
  dup <- nms[duplicated(nms)]
  if (length(dup))
    sd_abort(sprintf("Two Vensim variables map to the same R name: %s.", comma(unique(dup))))

  is_stock <- grepl("^INTEG\\s*\\(", eqn, ignore.case = TRUE)
  els <- list(meta(name = sub("\\.[^.]*$", "", basename(path)), source = basename(path)))
  eqs <- list(); consts <- list(); inits <- list()
  from <- to <- stats::setNames(vector("list", length(nms)), nms)
  is_flow <- stats::setNames(logical(length(nms)), nms)

  ## ---- stocks first: INTEG(net, init) is also where the wiring lives -------
  for (i in which(is_stock)) {
    nm <- nms[[i]]
    args <- mdl_args(sub("^INTEG\\s*\\(", "", trimws(eqn[[i]]), ignore.case = TRUE))
    if (length(args) != 2L)
      sd_abort(sprintf("INTEG() for '%s' does not have two arguments.", nm))
    els[[length(els) + 1L]] <- stock(nm, units = na_null(units[[i]]),
                                     label = na_null_label(raw[[i]], nm))
    lit <- as_literal(args[[2]])
    if (!is.null(lit)) inits[[nm]] <- lit
    else eqs[[length(eqs) + 1L]] <- rlang::new_formula(
      call("init", as.symbol(nm)),
      mdl_import_expr(args[[2]], nms, raw, nm))

    terms <- mdl_terms(args[[1]], nms, raw)
    if (is.null(terms)) {
      ## net rate is an expression, not a sum of named flows: give it one flow
      f <- paste0(nm, "_net")
      if (f %in% nms) sd_abort(sprintf("Cannot name the net flow of '%s': '%s' is taken.", nm, f))
      els[[length(els) + 1L]] <- flow(f, from = .source, to = nm, units = na_null(units[[i]]))
      eqs[[length(eqs) + 1L]] <- rlang::new_formula(
        as.symbol(f), mdl_import_expr(args[[1]], nms, raw, f))
      next
    }
    for (k in seq_along(terms)) {
      f <- names(terms)[[k]]
      is_flow[[f]] <- TRUE
      if (terms[[k]] > 0) to[[f]] <- nm else from[[f]] <- nm
    }
  }

  ## ---- everything else: flow if a stock claimed it, else aux or constant ---
  for (i in which(!is_stock)) {
    nm <- nms[[i]]; u <- na_null(units[[i]]); lab <- na_null_label(raw[[i]], nm)
    if (is_flow[[nm]]) {
      els[[length(els) + 1L]] <- flow(nm, from = from[[nm]] %||% .source,
                                      to = to[[nm]] %||% .sink, units = u, label = lab)
    } else {
      lit <- as_literal(eqn[[i]])
      if (!is.null(lit)) { consts[[nm]] <- lit; next }
      els[[length(els) + 1L]] <- aux(nm, units = u, label = lab)
    }
    eqs[[length(eqs) + 1L]] <- rlang::new_formula(
      as.symbol(nm), mdl_import_expr(eqn[[i]], nms, raw, nm))
  }

  pars <- list()
  if (length(consts)) pars <- c(pars, list(do.call(constant, consts)))
  if (length(inits)) pars <- c(pars, list(do.call(initial, inits)))

  dt <- ctrl[["TIME STEP"]] %||% 1
  saveper <- ctrl[["SAVEPER"]]
  list(
    structure = do.call(sd_structure, els),
    equations = do.call(sd_equations, eqs),
    parameters = do.call(sd_parameters, pars),
    # ponytail: the .mdl names no integration method; Vensim's default is Euler.
    spec = sim_spec(start = ctrl[["INITIAL TIME"]] %||% 0,
                    stop = ctrl[["FINAL TIME"]] %||% 100,
                    dt = dt, method = "euler",
                    saveat = if (!is.null(saveper) && saveper != dt) saveper,
                    check_units = FALSE)
  )
}

na_null <- function(x) if (is.na(x)) NULL else x
na_null_label <- function(raw, nm) if (identical(raw, nm)) NULL else raw

## The inside of `INTEG(` up to its closing paren, split on top-level commas.
mdl_args <- function(s) {
  chars <- strsplit(s, "")[[1]]
  depth <- 0L; cut <- integer(0); end <- length(chars)
  for (i in seq_along(chars)) {
    ch <- chars[[i]]
    if (ch == "(") depth <- depth + 1L
    else if (ch == ")") { if (depth == 0L) { end <- i - 1L; break }; depth <- depth - 1L }
    else if (ch == "," && depth == 0L) cut <- c(cut, i)
  }
  if (end < 1L) return(character(0))
  bounds <- c(0L, cut, end + 1L)
  trimws(vapply(seq_len(length(bounds) - 1L),
                function(k) paste(chars[seq_len(end)][seq(bounds[[k]] + 1L, bounds[[k + 1L]] - 1L)],
                                  collapse = ""),
                character(1)))
}

## "Births - Deaths" -> c(Births = 1, Deaths = -1); NULL for anything richer,
## which the caller turns into a single net flow instead.
mdl_terms <- function(s, nms, raw) {
  s <- trimws(s)
  if (!grepl("^[-+]?\\s*[A-Za-z][A-Za-z0-9_ ]*(\\s*[-+]\\s*[A-Za-z][A-Za-z0-9_ ]*)*$", s))
    return(NULL)
  pieces <- strsplit(gsub("([-+])", "\n\\1", s), "\n")[[1]]
  pieces <- pieces[nzchar(trimws(pieces))]
  out <- stats::setNames(numeric(0), character(0))
  for (p in pieces) {
    p <- trimws(p)
    sign <- if (startsWith(p, "-")) -1 else 1
    nm <- xmile_import_name(gsub("^[-+]\\s*", "", p))
    if (!nm %in% nms || nm %in% names(out)) return(NULL)
    out[[nm]] <- sign
  }
  if (!length(out)) NULL else out
}

## Vensim's spellings that XMILE does not share, then the shared translator.
mdl_import_expr <- function(eqn, nms, raw, where) {
  s <- gsub("(?i):(AND|OR|NOT):", " \\1 ", eqn, perl = TRUE)
  s <- gsub("(?i)\\bIF\\s+THEN\\s+ELSE\\s*\\(", "ifelse(", s, perl = TRUE)
  s <- gsub("(?i)\\bDELAY\\s+FIXED\\b", "DELAY", s, perl = TRUE)
  s <- gsub("(?i)\\b(SMOOTH|DELAY)\\s+N\\b", "\\1", s, perl = TRUE)
  xmile_import_expr(s, nms, raw, where, fmt = "Vensim")
}
