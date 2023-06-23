defmodule GradeInatorWeb.DownloadSubmissionController do
  use GradeInatorWeb, :controller

  alias GradeInator.Course.Submission

  def download_submission(conn, %{"submission_id" => submission_id}) do
    submission_id = String.to_integer(submission_id)

    user = get_session(conn, :user)

    if Submission.allowed_to_download(submission_id, user) do
      start_submission_download(conn, submission_id)
    else
      conn
    end
  end

  defp start_submission_download(conn, submission_id) do
    send_download(
      conn,
      {:file, "#{:code.priv_dir(:grade_inator)}/static/submissions/#{submission_id}/submission_files.zip"}
    )
  end
end
