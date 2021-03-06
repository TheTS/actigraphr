% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/apply_weartime.R
\name{apply_weartime_filter}
\alias{apply_weartime_filter}
\title{Apply a weartime filter to an activity data frame}
\usage{
apply_weartime_filter(agdb, hours, days, hours_we = hours, days_we = 0)
}
\arguments{
\item{agdb}{A day-level summary of activity data obtained from \code{\link{summarise_agd}} with the argument \code{time = "1 day"}.}

\item{hours}{The minimum required hours of weartime for a day to be considered valid.}

\item{days}{The minimum number of valid days for the dataset to be valid.}

\item{hours_we}{Same as \code{hours} except for weekend days. Default is same as \code{hours}.}

\item{days_we}{The minimum number of valid weekend days required for the dataset to be valid. Default is 0.}
}
\value{
The input \code{tibble} of activity data only containing rows (days) that meet the weartime criteria.
}
\description{
This function takes a day-level summary as input, and will remove days if they do not meet a weartime criteria.
Generally in physical activity research, days are excluded if the accelerometer is not worn for a sufficient period of time.
}
\details{
The \code{agdb} argument must be obtained from the \code{summarise_agd(time = "1 day")} function.

The \code{days} argument is inclusive of \code{days_we}. You can think of \code{(days = 5, days_we = 1)} as \emph{"Five days in total are required, one of which must be a weekend day"}.
}
\examples{
 data("gtxplus1day")

 summary <- gtxplus1day \%>\%
  apply_weartime() \%>\%
  apply_cutpoints("evenson_children") \%>\%
  summarise_agd("1 day")

  summary \%>\% apply_weartime_filter(hours = 7, days = 3)

  # Example using the IPEN-Adolescent criteria
  summary \%>\% apply_weartime_filter(hours = 10,
                                    days = 5,
                                    hours_we = 8,
                                    days_we = 1)

}
\seealso{
\code{\link{summarise_agd}}
}
