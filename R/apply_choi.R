#' Apply the Choi algorithm
#'
#' The Choi algorithm detects periods of non-wear in activity data from an ActiGraph device. Such intervals are likely to represent invalid data and therefore should be excluded from downstream analysis.
#' @param agdb A \code{tibble} (\code{tbl}) of activity data (at least) an \code{epochlength} attribute. The epoch length must be 60 seconds.
#' @param min_period_len Minimum number of consecutive "zero" epochs to start a non-wear period. The default is 90.
#' @param min_window_len The minimum number of consecutive "zero" epochs immediately preceding and following a spike of artifactual movement. The default is 30.
#' @param spike_tolerance Also known as artifactual movement interval. At most \code{spike_tolerance} "nonzero" epochs can occur in sequence during a non-wear period without interrupting it. The default is 2.
#' @param use_magnitude Logical. If true, the magnitude of the vector (axis1, axis2, axis3) is used to measure activity; otherwise the axis1 value is used. The default is FALSE.
#' @details
#' The Choi algorithm extends the Troiano algorithm by requiring that short spikes of artifactual movement during a non-wear period are preceded and followed by \code{min_window_len} consecutive "zero" epochs.
#'
#' This implementation of the algorithm expects that the epochs are 60 second long.
#' @return A summary \code{tibble} of the detected non-wear periods. If the activity data is grouped, then non-wear periods are detected separately for each group.
#' @references L Choi, Z Liu, CE Matthews and MS Buchowski. Validation of accelerometer wear and nonwear time classification algorithm. \emph{Medicine & Science in Sports & Exercise}, 43(2):357–364, 2011.
#' @references ActiLife 6 User's Manual by the ActiGraph Software Department. 04/03/2012.
#' @seealso \code{\link{collapse_epochs}}
#' @examples
#' file <- system.file("extdata", "GT3XPlus-RawData-Day01-10sec.agd",
#'                     package = "actigraph.sleepr")
#' agdb_10s <- read_agd(file)
#' agdb_60s <- collapse_epochs(agdb_10s, 60)
#' agdb_60s_nonwear <- apply_choi(agdb_60s)
#' @export

apply_choi <- function(agdb,
                       min_period_len = 90,
                       min_window_len = 30,
                       spike_tolerance = 2,
                       use_magnitude = FALSE) {

  check_args_nonwear_periods(agdb, "Choi", use_magnitude)
  stopifnot(min_window_len >= spike_tolerance)

  nonwear <- agdb %>%
    do(apply_choi_(., min_period_len, min_window_len,
                   spike_tolerance, use_magnitude))

  attr(nonwear, "nonwear_algorithm") <- "Choi"
  attr(nonwear, "min_period_len") <- min_period_len
  attr(nonwear, "min_window_len") <- min_window_len
  attr(nonwear, "spike_tolerance") <- spike_tolerance
  attr(nonwear, "use_magnitude") <- use_magnitude

  structure(nonwear, class = c("tbl_period", "tbl_df", "tbl", "data.frame"))
}

apply_choi_ <- function(data,
                        min_period_len,
                        min_window_len,
                        spike_tolerance,
                        use_magnitude) {

  data %>%
    mutate(magnitude = sqrt(axis1 ^ 2 + axis2 ^ 2 + axis3 ^ 2),
           count = if (use_magnitude) magnitude else axis1,
           state = ifelse(count == 0, "N", "W")) %>%
    group_by(rleid = rleid(state)) %>%
    summarise(state = first(state),
              start_timestamp = first(timestamp),
              end_timestamp = last(timestamp),
              length = n()) %>%
    # Let (spike, zero, zero, spike) -> (spike of length 4)
    # as long as (zero, zero) is shorter than spike_tolerance
    mutate(state = ifelse(state == "N" & length < spike_tolerance,
                          "W", state)) %>%
    group_by(rleid = rleid(state)) %>%
    summarise(state = first(state),
              start_timestamp = first(start_timestamp),
              end_timestamp = last(end_timestamp),
              length = sum(length)) %>%
    # Ignore artifactual movement intervals
    mutate(state =
             ifelse(state == "W" & length <= spike_tolerance &
                      lead(length, default = 0) >= min_window_len &
                      lag(length, default = 0) >= min_window_len,
                    "N", state)) %>%
    group_by(rleid = rleid(state)) %>%
    summarise(state = first(state),
              start_timestamp = first(start_timestamp),
              end_timestamp =
                last(end_timestamp) + duration(1, units = "mins"),
              length = sum(length)) %>%
    filter(state == "N",
           length >= min_period_len) %>%
    select(start_timestamp, end_timestamp, length)
}