YEAR = 365 * 24 * 60 * 60
Holidays.cache_between(
  Time.now.beginning_of_year, Time.now.end_of_year + 2.years, :co, :mx
)
