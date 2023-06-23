defmodule GradeInator.AssignmentListTest do
  use GradeInator.DataCase

  alias GradeInator.AssignmentList

  describe "assignments" do
    alias GradeInator.AssignmentList.Assignment

    import GradeInator.AssignmentListFixtures

    @invalid_attrs %{assignment_description: nil, assignment_name: nil, deadline: nil, visible: nil}

    test "list_assignments/0 returns all assignments" do
      assignment = assignment_fixture()
      assert AssignmentList.list_assignments() == [assignment]
    end

    test "get_assignment!/1 returns the assignment with given id" do
      assignment = assignment_fixture()
      assert AssignmentList.get_assignment!(assignment.id) == assignment
    end

    test "create_assignment/1 with valid data creates a assignment" do
      valid_attrs = %{assignment_description: "some assignment_description", assignment_name: "some assignment_name", deadline: ~N[2023-04-15 10:49:00], visible: true}

      assert {:ok, %Assignment{} = assignment} = AssignmentList.create_assignment(valid_attrs)
      assert assignment.assignment_description == "some assignment_description"
      assert assignment.assignment_name == "some assignment_name"
      assert assignment.deadline == ~N[2023-04-15 10:49:00]
      assert assignment.visible == true
    end

    test "create_assignment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = AssignmentList.create_assignment(@invalid_attrs)
    end

    test "update_assignment/2 with valid data updates the assignment" do
      assignment = assignment_fixture()
      update_attrs = %{assignment_description: "some updated assignment_description", assignment_name: "some updated assignment_name", deadline: ~N[2023-04-16 10:49:00], visible: false}

      assert {:ok, %Assignment{} = assignment} = AssignmentList.update_assignment(assignment, update_attrs)
      assert assignment.assignment_description == "some updated assignment_description"
      assert assignment.assignment_name == "some updated assignment_name"
      assert assignment.deadline == ~N[2023-04-16 10:49:00]
      assert assignment.visible == false
    end

    test "update_assignment/2 with invalid data returns error changeset" do
      assignment = assignment_fixture()
      assert {:error, %Ecto.Changeset{}} = AssignmentList.update_assignment(assignment, @invalid_attrs)
      assert assignment == AssignmentList.get_assignment!(assignment.id)
    end

    test "delete_assignment/1 deletes the assignment" do
      assignment = assignment_fixture()
      assert {:ok, %Assignment{}} = AssignmentList.delete_assignment(assignment)
      assert_raise Ecto.NoResultsError, fn -> AssignmentList.get_assignment!(assignment.id) end
    end

    test "change_assignment/1 returns a assignment changeset" do
      assignment = assignment_fixture()
      assert %Ecto.Changeset{} = AssignmentList.change_assignment(assignment)
    end
  end
end
