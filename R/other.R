#   IGraph R package
#   Copyright (C) 2005-2012  Gabor Csardi <csardi.gabor@gmail.com>
#   334 Harvard street, Cambridge, MA 02139 USA
#   
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc.,  51 Franklin Street, Fifth Floor, Boston, MA
#   02110-1301 USA
#
###################################################################



#' Running mean of a time series
#' 
#' \code{running_mean} calculates the running mean in a vector with the given
#' bin width.
#' 
#' The running mean of \code{v} is a \code{w} vector of length
#' \code{length(v)-binwidth+1}. The first element of \code{w} id the average of
#' the first \code{binwidth} elements of \code{v}, the second element of
#' \code{w} is the average of elements \code{2:(binwidth+1)}, etc.
#'
#' @aliases running.mean
#' @param v The numeric vector.
#' @param binwidth Numeric constant, the size of the bin, should be meaningful,
#' ie. smaller than the length of \code{v}.
#' @return A numeric vector of length \code{length(v)-binwidth+1}
#' @author Gabor Csardi \email{csardi.gabor@@gmail.com}
#' @export
#' @keywords manip
#' @examples
#' 
#' running_mean(1:100, 10)
#' 
running_mean <- function(v, binwidth) {

  v <- as.numeric(v)
  binwidth <- as.numeric(binwidth)
  if (length(v) < binwidth) {
    stop("Vector too short for this binwidth.")
  }
  
  on.exit( .Call(C_R_igraph_finalizer) )
  .Call(C_R_igraph_running_mean, v, binwidth)
}



#' Sampling a random integer sequence
#' 
#' This function provides a very efficient way to pull an integer random sample
#' sequence from an integer interval.
#' 
#' The algorithm runs in \code{O(length)} expected time, even if
#' \code{high-low} is big. It is much faster (but of course less general) than
#' the builtin \code{sample} function of R.
#'
#' @aliases igraph.sample
#' @param low The lower limit of the interval (inclusive).
#' @param high The higher limit of the interval (inclusive).
#' @param length The length of the sample.
#' @return An increasing numeric vector containing integers, the sample.
#' @author Gabor Csardi \email{csardi.gabor@@gmail.com}
#' @references Jeffrey Scott Vitter: An Efficient Algorithm for Sequential
#' Random Sampling, \emph{ACM Transactions on Mathematical Software}, 13/1,
#' 58--67.
#' @export
#' @keywords datagen
#' @examples
#' 
#' rs <- sample_seq(1, 100000000, 10)
#' rs
#' 
sample_seq <- function(low, high, length) {
  if (length>high-low+1) {
    stop("length too big for this interval")
  }
  
  on.exit( .Call(C_R_igraph_finalizer) )
  .Call(C_R_igraph_random_sample, as.numeric(low), as.numeric(high),
        as.numeric(length))
}

#' Common handler for vertex type arguments in igraph functions
#'
#' This function takes the \code{types} and \code{graph} arguments from a
#' public igraph function call and validates the vertex type vector.
#'
#' When the provided vertex types are NULL and the graph has a \code{types}
#' vertex attribute, then the value of this vertex attribute will be used as
#' vertex types. Non-logical vertex type vectors are coerced into logical
#' vectors after printing a warning.
#'
#' @param types the vertex types
#' @param graph the graph
#' @param required whether the graph has to be bipartite
#' @return A logical vector representing the resolved vertex type for each
#' vertex in the graph
#' @author Tamas Nepusz \email{ntamas@@gmail.com}
#' @keywords internal
#'
handle_vertex_type_arg <- function(types, graph, required = T) {
  if (is.null(types) && "type" %in% vertex_attr_names(graph)) { 
    types <- V(graph)$type 
  } 
  if (!is.null(types)) {
    if (!is.logical(types)) {
      warning("vertex types converted to logical")
    }
    types <- as.logical(types)
    if (any(is.na(types))) {
      stop("`NA' is not allowed in vertex types")
    }
  }
  if (is.null(types) && required) {
    stop("Not a bipartite graph, supply `types' argument or add a vertex attribute named `type'")
  }
  return(types)
}

igraph.match.arg <- function(arg, choices, several.ok=FALSE) {
  if (missing(choices)) {
    formal.args <- formals(sys.function(sys.parent()))
    choices <- eval(formal.args[[deparse(substitute(arg))]])
  }

  arg <- tolower(arg)
  choices <- tolower(choices)

  match.arg(arg=arg, choices=choices, several.ok=several.ok)
}

igraph.i.spMatrix <- function(M) {
  if (M$type == "triplet") {
    Matrix::sparseMatrix(dims=M$dim, i=M$i+1L, j=M$p+1L, x=M$x)
  } else {
    new("dgCMatrix", Dim=M$dim, Dimnames=list(NULL, NULL),
        factors=list(), i=M$i, p=M$p, x=M$x)
  }
}



#' Deprecated function, used to set random seed of the C library's RNG
#' 
#' @param seed Ignored.
#' @author Gabor Csardi \email{csardi.gabor@@gmail.com}
#' @export

srand <- function(seed) {
  warning("This function does nothing, as calling srand from R packages\n",
          "is now not allowed. If you want to reproduce your past\n",
          "results, use an older version of igraph, e.g. 0.7.1")
}


#' Convex hull of a set of vertices
#' 
#' Calculate the convex hull of a set of points, i.e. the covering polygon that
#' has the smallest area.
#' 
#' 
#' @aliases convex.hull convex_hull
#' @param data The data points, a numeric matrix with two columns.
#' @return A named list with components: \item{resverts}{The indices of the
#' input vertices that constritute the convex hull.} \item{rescoords}{The
#' coordinates of the corners of the convex hull.}
#' @author Tamas Nepusz \email{ntamas@@gmail.com}
#' @references Thomas H. Cormen, Charles E. Leiserson, Ronald L. Rivest, and
#' Clifford Stein. Introduction to Algorithms, Second Edition. MIT Press and
#' McGraw-Hill, 2001. ISBN 0262032937. Pages 949-955 of section 33.3: Finding
#' the convex hull.
#' @keywords graphs
#' @examples
#' 
#' M <- cbind( runif(100), runif(100) )
#' convex_hull(M)
#' @export

convex_hull <- convex_hull
