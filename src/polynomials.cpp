// Utility functions for working with polynomials

#include <Rcpp.h>

// Compute the polynomial expansion of a vector, according to a 'poly_terms'
// object as returned by polym2()
Rcpp::NumericVector rawToPoly(Rcpp::NumericVector x,
                              Rcpp::IntegerMatrix poly_terms) {
    int n_poly = poly_terms.nrow();
    int n_variables = poly_terms.ncol();

    if (x.size() != n_variables)
        Rcpp::stop("'x' must be the same length as the number of columns in 'poly_terms'");

    // Initialize each as 1 since we're multiplying within the loop
    Rcpp::NumericVector ans(n_poly + 1, 1.0);
    Rcpp::IntegerVector powers;

    // Outside loop: Each row of the polyTerms matrix
    for (int i = 0; i < n_poly; i++) {
        // Inside loop: Each element of the row, which is the power of the
        // corresponding variable of the x vector
        powers = poly_terms.row(i);
        for (int j = 0; j < n_variables; j++) {
            if (powers[j] > 0)
                ans[i+1] *= pow(x[j], powers[j]);
        }
    }

    return ans;
}
