defmodule GradeInator.Course.Time do
  defp month_num_to_str(month_num) do
    Enum.at(["Jan", "Feb", "Mar", "Apr", "May", "June", "July", "Aug", "Sept", "Oct", "Nov", "Dec"], month_num)
  end

  def get_pretty_datetime(%DateTime{} = deadline) do
      "#{deadline.day} #{month_num_to_str(deadline.month)} #{deadline.year} #{deadline.hour}:#{deadline.minute}"
  end
end
