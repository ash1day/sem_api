options <- commandArgs(trailingOnly = TRUE)
nobs <- options[1]

library(lavaan)
model <- readLines("./tmp/model.lav")
elems <- readLines("./tmp/elems.lav")
cov <- getCov(elems[1], names=elems[2]) # TODO c("v0", "v1" .. )
fit <- sem(model, sample.cov=cov, sample.nobs=nobs)
summary(fit, standardized=TRUE)
fitMeasures(fit, fit.measures = "all", baseline.model = NULL)
