defmodule GradeInator.SubmissionListTest do
  use GradeInator.DataCase

  alias GradeInator.SubmissionList

  describe "submissions" do
    alias GradeInator.SubmissionList.Submission

    import GradeInator.SubmissionListFixtures

    @invalid_attrs %{assignment_id: nil, state: nil}

    test "list_submissions/0 returns all submissions" do
      submission = submission_fixture()
      assert SubmissionList.list_submissions() == [submission]
    end

    test "get_submission!/1 returns the submission with given id" do
      submission = submission_fixture()
      assert SubmissionList.get_submission!(submission.id) == submission
    end

    test "create_submission/1 with valid data creates a submission" do
      valid_attrs = %{assignment_id: 42, state: :ungraded}

      assert {:ok, %Submission{} = submission} = SubmissionList.create_submission(valid_attrs)
      assert submission.assignment_id == 42
      assert submission.state == :ungraded
    end

    test "create_submission/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SubmissionList.create_submission(@invalid_attrs)
    end

    test "update_submission/2 with valid data updates the submission" do
      submission = submission_fixture()
      update_attrs = %{assignment_id: 43, state: :graded}

      assert {:ok, %Submission{} = submission} = SubmissionList.update_submission(submission, update_attrs)
      assert submission.assignment_id == 43
      assert submission.state == :graded
    end

    test "update_submission/2 with invalid data returns error changeset" do
      submission = submission_fixture()
      assert {:error, %Ecto.Changeset{}} = SubmissionList.update_submission(submission, @invalid_attrs)
      assert submission == SubmissionList.get_submission!(submission.id)
    end

    test "delete_submission/1 deletes the submission" do
      submission = submission_fixture()
      assert {:ok, %Submission{}} = SubmissionList.delete_submission(submission)
      assert_raise Ecto.NoResultsError, fn -> SubmissionList.get_submission!(submission.id) end
    end

    test "change_submission/1 returns a submission changeset" do
      submission = submission_fixture()
      assert %Ecto.Changeset{} = SubmissionList.change_submission(submission)
    end
  end

  describe "submissions" do
    alias GradeInator.SubmissionList.Submission

    import GradeInator.SubmissionListFixtures

    @invalid_attrs %{}

    test "list_submissions/0 returns all submissions" do
      submission = submission_fixture()
      assert SubmissionList.list_submissions() == [submission]
    end

    test "get_submission!/1 returns the submission with given id" do
      submission = submission_fixture()
      assert SubmissionList.get_submission!(submission.id) == submission
    end

    test "create_submission/1 with valid data creates a submission" do
      valid_attrs = %{}

      assert {:ok, %Submission{} = submission} = SubmissionList.create_submission(valid_attrs)
    end

    test "create_submission/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SubmissionList.create_submission(@invalid_attrs)
    end

    test "update_submission/2 with valid data updates the submission" do
      submission = submission_fixture()
      update_attrs = %{}

      assert {:ok, %Submission{} = submission} = SubmissionList.update_submission(submission, update_attrs)
    end

    test "update_submission/2 with invalid data returns error changeset" do
      submission = submission_fixture()
      assert {:error, %Ecto.Changeset{}} = SubmissionList.update_submission(submission, @invalid_attrs)
      assert submission == SubmissionList.get_submission!(submission.id)
    end

    test "delete_submission/1 deletes the submission" do
      submission = submission_fixture()
      assert {:ok, %Submission{}} = SubmissionList.delete_submission(submission)
      assert_raise Ecto.NoResultsError, fn -> SubmissionList.get_submission!(submission.id) end
    end

    test "change_submission/1 returns a submission changeset" do
      submission = submission_fixture()
      assert %Ecto.Changeset{} = SubmissionList.change_submission(submission)
    end
  end
end
