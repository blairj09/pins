library(testthat)
library(pins)

PerformanceReporter <- R6::R6Class(
  "PerformanceReporter",
  inherit = Reporter,
  public = list(
   results = list(
     context = character(0),
     time = numeric(0)
   ),
   last_context = NA_character_,
   last_test = NA_character_,
   last_time = Sys.time(),
   last_test_time = 0,
   n_ok = 0,
   n_skip = 0,
   n_warn = 0,
   n_fail = 0,

   start_context = function(context) {
     private$print_last_test()

     self$last_context <- context
     self$last_time <- Sys.time()
     cat(paste0("\nContext: ", context, "\n"))
   },

   add_result = function(context, test, result) {
     elapsed_time <- as.numeric(Sys.time()) - as.numeric(self$last_time)

     print_message = TRUE
     if (inherits(result, "expectation_failure") ||
         inherits(result, "expectation_error")) {
       self$n_fail <- self$n_fail + 1
     } else if (inherits(result, "expectation_skip")) {
       self$n_skip <- self$n_skip + 1
     } else if (inherits(result, "expectation_warning")) {
       self$n_warn <- self$n_warn + 1
     } else {
       print_message = FALSE
       self$n_ok <- self$n_ok + 1
     }

     if (print_message) {
       cat(
         paste0(test, ": ", private$expectation_type(result), ": ", result$message),
         "\n"
       )
     }

     if (identical(self$last_test, test)) {
       elapsed_time <- self$last_test_time + elapsed_time
       self$results$time[length(self$results$time)] <- elapsed_time
       self$last_test_time <- elapsed_time
     }
     else {
       private$print_last_test()

       self$results$context[length(self$results$context) + 1] <- self$last_context
       self$results$time[length(self$results$time) + 1] <- elapsed_time
       self$last_test_time <- elapsed_time
     }

     self$last_test <- test
     self$last_time <- Sys.time()
   },

   end_reporter = function() {
     private$print_last_test()

     cat("\n")
     data <- data.frame(
       context = self$results$context,
       time = self$results$time
     )

     summary <- aggregate(. ~ context, data, function(e) format(sum(e), width = "9", digits = "3", scientific = F))

     total <- format(sum(data$time), digits = "3", scientific = F)

     cat("\n")
     cat("--- Performance Summary  ----\n\n")
     print(as.data.frame(summary), row.names = FALSE)

     cat(paste0("\nTotal: ", total, "s\n"))

     cat("\n")
     cat("------- Tests Summary -------\n\n")
     self$cat_line("OK:       ", format(self$n_ok, width = 5))
     self$cat_line("Failed:   ", format(self$n_fail, width = 5))
     self$cat_line("Warnings: ", format(self$n_warn, width = 5))
     self$cat_line("Skipped:  ", format(self$n_skip, width = 5))
     cat("\n")
   }
  ),
  private = list(
   print_last_test = function() {
     if (!is.na(self$last_test) &&
         length(self$last_test) > 0 &&
         length(self$last_test_time) > 0) {
       cat(paste0(self$last_test, ": ", self$last_test_time, "\n"))
     }

     self$last_test <- NA_character_
   },
   expectation_type = function(exp) {
     stopifnot(is.expectation(exp))
     gsub("^expectation_", "", class(exp)[[1]])
   }
  )
)

test_check("pins", reporter = "performance")
