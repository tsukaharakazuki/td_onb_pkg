delete from ${table}
where td_time_range(time,
  '${date}',
  '${moment(date).add(1, "days").format("YYYY-MM-DD")}',
  '${timezone}')
