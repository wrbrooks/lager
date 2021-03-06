#' Calculate the sum of squared residuals for a local model
#' 
#' This function fits a local LAGR model at \code{loc}, and returns its sum of squared residuals (SSR) as a proportion of the SSR from a global model. This proportion is how the bandwidth is specified under \code{nen}.
#' 
#' @param bw kernel bandwidth (distance) to use for fitting the local model
#' @param x matrix of observed covariates
#' @param y vector of observed responses
#' @param family exponential family distribution of the response
#' @param loc location around which to center the kernel
#' @param coords matrix of locations, with each row giving the location at which the corresponding row of data was observed
#' @param dist vector of distances from central location to the observation locations
#' @param kernel kernel function for generating the local observation weights
#' @param longlat \code{TRUE} indicates that the coordinates are specified in longitude/latitude, \code{FALSE} indicates Cartesian coordinates. Default is \code{FALSE}.
#' @param bw bandwidth parameter
#' @param bw.type type of bandwidth - options are \code{dist} for distance (the default), \code{knn} for nearest neighbors (bandwidth a proportion of \code{n}), and \code{nen} for nearest effective neighbors (bandwidth a proportion of the sum of squared residuals from a global model)
#' @param tol.loc tolerance for the tuning of an adaptive bandwidth (e.g. \code{knn} or \code{nen})
#' @param varselect.method criterion to minimize in the regularization step of fitting local models - options are \code{AIC}, \code{AICc}, \code{BIC}, \code{GCV}
#' @param tuning logical indicating whether this model will be used to tune the bandwidth, in which case only the tuning criteria are returned
#' @param D pre-specified matrix of distances between locations
#' @param verbose print detailed information about our progress?
#' 
#' 
lagr.ssr = function(bw, x, y, group.id, family, loc, coords, dist, kernel, target, varselect.method, prior.weights, oracle, verbose, lambda.min.ratio, n.lambda, lagr.convergence.tol, lagr.max.iter) {
    #Calculate the local weights:
    kernel.weights = drop(kernel(dist, bw))
    
    lagr.object = lagr.fit.inner(
        x=x,
        y=y,
        group.id=group.id,
        family=family,
        coords=coords,
        loc=loc,
        varselect.method=varselect.method,
        predict=TRUE,
        tuning=FALSE,
        simulation=FALSE,
        verbose=verbose,
        kernel.weights=kernel.weights,
        prior.weights=prior.weights,
        oracle=oracle,
        lambda.min.ratio=lambda.min.ratio,
        n.lambda=n.lambda, 
        lagr.convergence.tol=lagr.convergence.tol,
        lagr.max.iter=lagr.max.iter
    )
    
    #Compute model-average fitted values and degrees of freedom:
    for (x in lagr.model) {
        #Compiute the model-averaging weights:
        crit = x[['tunelist']][['criterion']]        
        if (varselect.method %in% c("AIC", "AICc")) {
            crit.weights = exp(-0.5*(min(crit)-crit)**2)
        } else if (varselect.method == "wAIC") {
            crit.weights = -crit
        }
        
        fitted = c(fitted, sum(x[['tunelist']][['localfit']] * crit.weights) / sum(crit.weights))
        df = df + sum((1+x[['model']][['results']][['df']]) * crit.weights / x[['weightsum']] ) / sum(crit.weights)
    }
    
    dev.resids = family$dev.resids(y, fitted, weights)
    ll = family$aic(y, n, fitted, weights, sum(dev.resids))
    
    if (verbose) { cat(paste('loc:(', paste(round(loc,3), collapse=","), '), target: ', round(target,3), ', bw:', round(bw,3), ', logLik:', round(ll,3), ', miss:', round(abs(ll-target),3), '\n', sep="")) }
    
    
    return(abs(ll-target))
}
