preplotFromPick <- function(x, pick, ...)
{
    pp <- predVals(x, xvars = pick, ...)
    ans <- structure(pp, class = c("preplot.polywog", "data.frame"))
    return(ans)
}

##' Univariate and bivariate fitted value plots
##'
##' Generates plots of the relationship between input variables and the expected
##' value of the outcome, using \code{\link{predVals}} as a backend.
##'
##' By default, a univariate plot generated by \code{plot.polywog} shows the
##' relationship between the selected input variable and the expected outcome
##' while holding all other covariates at "central" values (as in
##' \code{\link{predVals}}).  The values that the other variables are held out
##' can be changed by supplying additional arguments to \code{...}, as in the
##' examples below.
##'
##' Similarly, a bivariate plot shows the relationship between two input
##' variables and the expected outcome while holding all else fixed.  If either
##' variable is binary or categorical, the plot will show the relationship
##' between one variable and the expected outcome across each value/level of the
##' other.
##' @param x a fitted model of class \code{"polywog"}, typically the output
##' of \code{\link{polywog}}.
##' @param which selection of variables to plot: a character vector containing
##' one or two names of raw input variables (see \code{x$varNames}).  May also
##' be a numeric vector corresponding to indices of \code{x$varNames}.
##' If \code{which = NULL}, a plot of each individual term will be generated.
##' @param ask logical: whether to display an interactive menu of terms to
##' select.
##' @param auto.set.par logical: whether to temporarily change the graphics
##' parameters so that multiple plots are displayed in one window (e.g., each
##' univariate plot when \code{which = NULL}).
##' @param interval logical: whether to display bootstrap confidence intervals
##' around each fitted value.  Not available for bivariate plots unless
##' \code{FUN3d = "persp3d"}.
##' @param level confidence level for the intervals.
##' @param bag logical: whether to use "bootstrap aggregation" to generate the
##' main fitted values (if \code{FALSE}, they are calculated from the main model
##' fit).
##' @param FUN3D which plotting function to use to generate bivariate plots.
##' Valid options include \code{"\link{contour}"} (the default) and
##' \code{"\link{filled.contour}"}; \code{"\link[lattice]{wireframe}"}, which
##' requires the \pkg{lattice} package; and \code{"\link[rgl]{persp3d}"}, which
##' requires the \pkg{rgl} package.
##' @param control.plot list of arguments to be passed to the underlying
##' plotting functions (e.g., axis labels and limits).
##' @param ... additional arguments to be passed to \code{\link{predVals}}.
##' @return An object of class \code{preplot.polywog}, invisibly.  This is a
##' data frame generated by \code{\link{predVals}} that contains all information
##' used in plotting.
##' @author Brenton Kenkel and Curtis S. Signorino
##' @importFrom stringr str_split
##' @method plot polywog
##' @export
##' @examples
##' ## Using occupational prestige data
##' data(Prestige, package = "car")
##' Prestige <- transform(Prestige, income = income / 1000)
##'
##' ## Fit a polywog model with bootstrap iterations
##' set.seed(22)
##' fit1 <- polywog(prestige ~ education + income + type, data = Prestige,
##'                 boot = 10)
##'
##' ## All univariate relationships
##' plot(fit1)
##'
##' ## Predicted prestige across occupational categories
##' plot(fit1, which = "type",
##' control.plot = list(xlab = "occupational category"))
##'
##' ## Predicted prestige by education across occupational categories
##' plot(fit1, which = c("education", "type"))
##'
##' ## Joint effect of education and income
##' plot(fit1, which = c("education", "income"), n = 20)
##'
##' ## Bring up interactive menu
##' \dontrun{
##' plot(fit1, ask = TRUE)
##' 
##'   # displays menu:
##'   # Select one or two variable numbers (separated by spaces), or 0 to exit:
##' 
##'   # 1: education
##'   # 2: income
##'   # 3: type
##' }
plot.polywog <- function(x, which = NULL, ask = FALSE, auto.set.par = TRUE,
                         interval = TRUE, level = 0.95, bag = TRUE,
                         FUN3D = c("contour", "filled.contour", "wireframe",
                         "persp3d"),
                         control.plot = list(),
                         ...)
{
    FUN3D <- match.arg(FUN3D)
    pp <- NULL  # To avoid return error when no plot selected

    ## Extract regressor names
    xnames <- x$varNames

    if (ask) {
        while (TRUE) {
            ## Display menu of options
            askout <- paste(seq_along(xnames), ": ", xnames, sep="")
            askout <-
                c("Select one or two variable numbers (separated by spaces), or 0 to exit:",
                  "", askout, "")
            writeLines(askout)
            pick <- readline("Selection: ")

            ## Parse selection into variable names
            pick <- str_split(pick, " ")[[1]]
            pick <- as.integer(pick[pick != ""])
            if (any(is.na(pick)) || any(pick > length(xnames)))
                stop("Selected an invalid option")
            if (length(pick) > 2)
                stop("Cannot select more than two variables")
            if (any(pick < 1))
                break
            pick <- xnames[pick]
            pp <- preplotFromPick(x, pick = pick, interval = interval, level =
                                  level, bag = bag, ...)
            plot(pp, auto.set.par = auto.set.par, FUN3D = FUN3D, control.plot =
                 control.plot)
        }
    } else if (!is.null(which)) {
        if (length(which) > 2)
            stop("Cannot select more than two variables")
        pick <- if (is.numeric(which)) xnames[which] else which
        pp <- preplotFromPick(x, pick = pick, interval = interval, level =
                              level, bag = bag, ...)
        plot(pp, auto.set.par = auto.set.par, FUN3D = FUN3D, control.plot =
             control.plot)
    } else {
        ## Plot all univariate terms
        if (auto.set.par) {
            mfrow <- ceiling(sqrt(length(xnames)))
            mfcol <- ceiling(length(xnames) / mfrow)
            op <- par(mfrow = c(mfrow, mfcol))
            on.exit(par(op))
        }
        pp <- list()
        for (i in seq_along(xnames)) {
            ppi <- preplotFromPick(x, pick = xnames[i], interval = interval,
                                   level = level, bag = bag, ...)
            plot(ppi, auto.set.par = auto.set.par, FUN3D = FUN3D, control.plot =
                 control.plot)
            pp[[i]] <- ppi
        }
    }

    invisible(pp)
}

##' @S3method plot preplot.polywog
plot.preplot.polywog <- function(x, auto.set.par = TRUE,
                                 FUN3D = c("contour", "filled.contour",
                                 "wireframe", "persp3d"),
                                 control.plot = list(),
                                 ...)
{
    xvars <- attr(x, "xvars")
    xcol <- attr(x, "xcol")
    whichFactors <- sapply(xcol, function(i) is.factor(x[, i]) ||
                           all(x[, i] %in% c(0, 1)))
    if (all(whichFactors == c(FALSE, TRUE))) {
        ## Reorder if only the second variable is categorical
        xvars <- rev(xvars)
        xcol <- rev(xcol)
    }

    ## Possibilities:
    ##   Two variables, at least one categorical: multiple plots broken up by
    ##     levels of the first
    ##   Two variables, both continuous: contour plot
    ##   Single variable, categorical: box plot (of sorts)
    ##   Single variable, continuous: scatterplot
    if (length(whichFactors) == 2 && any(whichFactors)) {
        ## Two variables, at least one categorical

        ## Set up the plot
        col <- xcol[1]
        nf <- length(unique(x[, col]))
        if (auto.set.par) {
            mfrow <- ceiling(sqrt(nf))
            mfcol <- ceiling(nf / mfrow)
            if (!exists("..op")) {
                ..op <- par(mfrow = c(mfrow, mfcol))
                on.exit(par(..op))
            } else {
                par(mfrow = c(mfrow, mfcol))
            }
        }

        ## Plot the relationship at each value of the factor/binary variable
        for (i in seq_len(nf)) {
            vali <- unique(x[, col])[i]
            xx <- x[x[, col] == vali, , drop = FALSE]
            attr(xx, "xcol") <- xcol[2]
            attr(xx, "xvars") <- xvars[2]
            control.plot$main <- paste(xvars[1], "=", vali)
            plot(xx, auto.set.par = auto.set.par, control.plot = control.plot)
        }
    } else if (length(whichFactors) == 2) {
        ## Two variables, both continuous

        ## Take user input about which 3D plotting function to use
        FUN3D <- match.arg(FUN3D)
        if (FUN3D == "wireframe" && !require("lattice")) {
            stop("'lattice' package required for FUN3D = \"wireframe\"")
        } else if (FUN3D == "persp3d" && !require("rgl")) {
            stop("'rgl' package required for FUN3D = \"persp3d\"")
        }

        ## Extract data
        var1 <- unique(x[, xcol[1]])
        var2 <- unique(x[, xcol[2]])
        fit <- matrix(x$fit, nrow = length(var1))

        ## Make plot
        if (FUN3D == "wireframe") {
            cl <- list(x = fit, row.values = var1, column.values = var2)
            cl <- c(cl, control.plot)
            if (is.null(cl$xlab))
                cl$xlab <- xvars[1]
            if (is.null(cl$ylab))
                cl$ylab <- xvars[2]
            if (is.null(cl$zlab))
                cl$zlab <- "fitted value"
            print(do.call(FUN3D, cl))
        } else if (FUN3D == "persp3d") {
            cl <- list(x = var1, y = var2, z = fit)
            cl <- c(cl, control.plot)
            if (is.null(cl$xlab))
                cl$xlab <- xvars[1]
            if (is.null(cl$ylab))
                cl$ylab <- xvars[2]
            if (is.null(cl$zlab))
                cl$zlab <- "fitted value"
            do.call(FUN3D, cl)
            if (attr(x, "interval")) {
                ## Confidence regions
                upr <- matrix(x$upr, nrow = length(var1))
                lwr <- matrix(x$lwr, nrow = length(var1))
                persp3d(x = var1, y = var2, z = upr,
                        col = "gray70", alpha = 0.7, add = TRUE)
                persp3d(x = var1, y = var2, z = lwr,
                        col = "gray70", alpha = 0.7, add = TRUE)
            }
        } else {
            cl <- list(z = fit, x = var1, y = var2)
            cl <- c(cl, control.plot)
            if (is.null(cl$xlab))
                cl$xlab <- xvars[1]
            if (is.null(cl$ylab))
                cl$ylab <- xvars[2]
            do.call(FUN3D, cl)
        }
    } else if (whichFactors[1]) {
        ## One variable, categorical

        ## Manually set up a "boxplot" with fitted values and bars for
        ## confidence levels
        boxStats <- list()
        boxStats$stats <- matrix(x$fit, nrow = 5, ncol = nrow(x), byrow =
                                 TRUE)
        if (attr(x, "interval")) {
            boxStats$stats[1, ] <- x$lwr
            boxStats$stats[5, ] <- x$upr
        }
        boxStats$n <- rep(1, nrow(x))
        boxStats$conf <- boxStats$stats[c(1, 5), ]
        boxStats$out <- numeric(0)
        boxStats$group <- numeric(0)
        boxStats$names <- as.character(x[, xcol])

        cl <- list(z = boxStats)
        cl <- c(cl, control.plot)
        if (is.null(cl$xlab))
            cl$xlab <- xvars[1]
        if (is.null(cl$ylab))
            cl$ylab <- "fitted value"
        do.call(bxp, cl)
    } else {
        ## One variable, continuous

        cl <- list(x = x[, xcol], y = x$fit, type = "l")
        cl <- c(cl, control.plot)
        if (is.null(cl$xlab))
            cl$xlab <- xvars[1]
        if (is.null(cl$ylab))
            cl$ylab <- "fitted value"
        if (is.null(cl$ylim))
            cl$ylim <- c(min(x$fit, x$upr, x$lwr), max(x$fit, x$upr, x$lwr))
        do.call(plot, cl)
        if (attr(x, "interval")) {
            lines(x[, xcol], x$lwr, lty = 2)
            lines(x[, xcol], x$upr, lty = 2)
        }
    }

    invisible(x)
}
