check_epochlen_is_60 <- function(agdb, algorithm) {
  assert_that(attr(agdb, "epochlen") == 60,
              msg = paste0(algorithm, " assumes 60sec epochs. ",
                          "Aggregate epochs with `collapse_epochs`."))
}

check_no_missing_timestamps <- function(agdb) {
  assert_that(has_missing_epochs(agdb) == FALSE,
              msg = paste0("Missing timestamps. ",
                           "Epochs should be evenly spaced from ",
                           "first(timestamp) to last(timestamp)."))
}

check_no_missing_counts <- function(agdb, var) {
  assert_that(noNA(agdb[[var]]),
              msg = paste0("Missing ", var, " counts. These ",
                           "can be imputed with `impute_epochs`."))
}

check_no_missing_state <- function(agdb) {
  assert_that(has_name(agdb, "sleep"),
              msg = paste0("Missing asleep/awake (S/W) indicator column. ",
                           "State can be inferred with `apply_sadeh` ",
                           "or `apply_cole_kripke.`"))
  assert_that(noNA(agdb[["sleep"]]),
              msg = "Missing asleep/awake values.")
}

check_args_sleep_scores <- function(agdb, algorithm) {
  check_epochlen_is_60(agdb, algorithm)
  check_no_missing_timestamps(agdb)
  check_no_missing_counts(agdb, "axis1")
}

check_args_sleep_periods <- function(agdb, algorithm) {
  check_epochlen_is_60(agdb, algorithm)
  check_no_missing_timestamps(agdb)
  check_no_missing_state(agdb)
}

check_args_nonwear_periods <- function(agdb, algorithm, use_magnitude) {
  assert_that(attr(agdb, "epochlength") <= 60,
              msg = "Nonwear algorithms are not compatible with epochlength > 60s.")

  check_no_missing_timestamps(agdb)
  check_no_missing_counts(agdb, "axis1")

  if (use_magnitude) {
    check_no_missing_counts(agdb, "axis2")
    check_no_missing_counts(agdb, "axis3")
  }
}

check_args_filter <- function(agdb, var) {
  assert_that(has_name(agdb, var))
  check_no_missing_timestamps(agdb)
  check_no_missing_counts(agdb, var)
}

check_args_collapse_method <- function(agdb, epoch_len_out) {
  check_no_missing_timestamps(agdb)
  check_no_missing_counts(agdb, "axis1")
  #assert_that(epoch_len_out == 60,
  #            msg = "Use `collapse_epochs` to aggregate to 60s epochs.")
  assert_that(exact_division(epoch_len_out, attr(agdb, "epochlen")),
              msg = paste0("Output epoch length is not an exact multiple ",
                           "of input epoch length."))
}

exact_division <- function(a, b) {
  (a %% b) == 0
}

check_args_cutpoints <- function(agdb, cutpoints, use_magnitude,
                                 custom_cutpoints, cutpoints_list) {
  assert_that(tolower(cutpoints) %in% cutpoints_list,
    msg = cat("`cutpoints` must be one of: ", paste(cutpoints_list, collapse = ", ")))

  if (tolower(cutpoints) == "custom") {
    if (length(custom_cutpoints) != 2)
      stop("If `cutpoints` is custom, then a list needs ",
        "to be specified in format: list(c(0, 99, 100, 1952), c(\"sedentary\", \"light\"))")

    if (length(custom_cutpoints[[1]])%%2)
      stop("Your `custom_cutpoints` need to have an even number ",
           "of categories")
  }

  assert_that(has_name(agdb, "axis1"))
  if (use_magnitude) {
    assert_that(has_name(agdb, "axis2"))
    assert_that(has_name(agdb, "axis3"))
  }
}

check_args_summary <- function(agdb, vars) {
  for (var in vars) assert_that(has_name(agdb, var))
}
