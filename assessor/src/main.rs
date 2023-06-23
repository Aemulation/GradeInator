use mysql::{params, prelude::Queryable, PooledConn};
use std::path::Path;

use std::process::Command;

use serde::Deserialize;
use serde_json::{Map, Value};

use anyhow::Result;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AssessionError {
    #[error("SCP error: {stderr:?}")]
    ScpError { stderr: String },

    #[error("assess.sh returned code: {exit_code}")]
    AssessionScriptError { exit_code: String },
}

#[derive(Deserialize, Debug)]
struct AssessionResult {
    result: String,
    scores: Map<String, Value>,
}

#[derive(Deserialize, Debug)]
struct AssessionOutput {
    result: AssessionResult,
    debug_log: String,
}

fn insert_assession_output_into_db(
    conn: &mut PooledConn,
    submission_id: i64,
    assession_output: AssessionOutput,
) -> std::result::Result<(), Box<dyn std::error::Error>> {
    conn.exec_batch(
        r"INSERT INTO submission_scores (`submission_id`, `assignment_score_id`, `value`) VALUES (:submission_id, (SELECT `id` FROM `assignment_scores` WHERE `key` = :key AND `assignment_id` = (SELECT `assignment_id` FROM `submissions` WHERE `id` = :submission_id)), :value)",
        assession_output.result.scores.iter().map(|(key, value)| {
            params! {
                submission_id,
                key,
                "value" => match value {
                    Value::String(string) => string.to_string(),
                    Value::Number(number) => number.to_string(),
                    Value::Bool(bool) => bool.to_string(),
                    _ => unimplemented!(),
                }
            }
        }),
    )?;

    conn.exec_iter(
        r"INSERT INTO submission_scores (`submission_id`, `assignment_score_id`, `value`) VALUES (:submission_id, (SELECT `id` FROM `assignment_scores` WHERE `key` = :key AND `assignment_id` = (SELECT `assignment_id` FROM `submissions` WHERE `id` = :submission_id)), :value)",
        params! {
            submission_id,
            "key" => "debug_log",
            "value" => assession_output.debug_log,
        },
    )?;

    conn.exec_iter(
        "UPDATE `submissions` SET `result` = :result, `state_id` = (SELECT `id` FROM `submission_states` WHERE `state` = \"graded\") WHERE `id` = :submission_id",
        params! {
            "result" => assession_output.result.result,
            submission_id,
        },
    )?;

    Ok(())
}

fn insert_assession_error_into_db(
    conn: &mut PooledConn,
    submission_id: i64,
    error_str: &str,
) -> std::result::Result<(), Box<dyn std::error::Error>> {
    conn.exec_iter(
        "UPDATE `submissions` SET `result` = :result, `state_id` = (SELECT `id` FROM `submission_states` WHERE `state` = \"grade error\") WHERE `id` = :submission_id",
        params! {
            "result" => "error",
            submission_id,
        },
    )?;

    conn.exec_iter(
        r"INSERT INTO submission_scores (`submission_id`, `assignment_score_id`, `value`) VALUES (:submission_id, (SELECT `id` FROM `assignment_scores` WHERE `key` = :key AND `assignment_id` = (SELECT `assignment_id` FROM `submissions` WHERE `id` = :submission_id)), :value)",
        params! {
            submission_id,
            "key" => "debug_log",
            "value" => error_str,
        },
    )?;

    Ok(())
}

fn scp_assess_files(assess_files: &Path, server_address: &str) -> Result<()> {
    let output = Command::new("scp")
        .args([
            String::from("-r"),
            format!("{}/.", assess_files.display()),
            format!("{server_address}:~/grade_inator/1/"),
        ])
        .output()?;

    if output.status.success() {
        Ok(())
    } else {
        anyhow::bail!(AssessionError::ScpError {
            stderr: String::from_utf8(output.stderr)?,
        })
    }
}

fn scp_submission_files(submission_files: &Path, server_address: &str) -> Result<()> {
    let output = Command::new("scp")
        .args([
            String::from("-r"),
            format!("{}", submission_files.display()),
            format!("{server_address}:~/grade_inator/1/"),
        ])
        .output()?;

    if output.status.success() {
        Ok(())
    } else {
        anyhow::bail!(AssessionError::ScpError {
            stderr: String::from_utf8(output.stderr)?,
        })
    }
}

fn run_assession(
    server_address: &str,
    id: &str,
) -> std::result::Result<(), Box<dyn std::error::Error>> {
    let screen_session_name = format!("grade_inator_{id}");

    let _result = Command::new("ssh")
        .args([
            server_address,
            "screen",
            "-S",
            screen_session_name.as_str(),
            "-dm",
            "$HOME/grade_inator/run_grade.sh",
            id,
        ])
        .output()?;

    Ok(())
}

fn wait_for_assession(
    server_address: &str,
    id: &str,
) -> std::result::Result<(), Box<dyn std::error::Error>> {
    let screen_session_name = format!("grade_inator_{id}");

    loop {
        std::thread::sleep(std::time::Duration::from_secs(5));
        let result = Command::new("ssh")
            .args([server_address, "screen", "-ls"])
            .output()?;

        let out = String::from_utf8(result.stdout)?;
        if !out.contains(screen_session_name.as_str()) {
            return Ok(());
        }
    }
}

fn _kill_assession(
    server_address: &str,
    id: &str,
) -> std::result::Result<(), Box<dyn std::error::Error>> {
    let screen_session_name = format!("grade_inator_{id}");

    Command::new("ssh")
        .args([
            server_address,
            "screen",
            "-X",
            "-S",
            screen_session_name.as_str(),
            "quit",
        ])
        .output()?;

    Ok(())
}

fn fetch_assession_result(server_address: &str, id: &str) -> Result<AssessionOutput> {
    let exit_code_path = format!("~/grade_inator/{id}/exit_code.txt");
    let std_out_path = format!("~/grade_inator/{id}/stdout.txt");
    let std_err_path = format!("~/grade_inator/{id}/stderr.txt");

    let exit_code = Command::new("ssh")
        .args([server_address, "cat", exit_code_path.as_str()])
        .output()?;

    let debug_log = Command::new("ssh")
        .args([server_address, "cat", std_err_path.as_str()])
        .output()?;

    if exit_code.stdout.first().unwrap() != &48u8 {
        let mut exit_code = String::from_utf8(exit_code.stdout)?;
        if exit_code.chars().last().unwrap() == '\n' {
            exit_code.pop();
        }

        eprintln!("{}", std::str::from_utf8(debug_log.stdout.as_slice())?);

        anyhow::bail!(AssessionError::AssessionScriptError { exit_code })
    }

    let assession_result = Command::new("ssh")
        .args([server_address, "tail", "-1", std_out_path.as_str()])
        .output()?;

    let assession_result: AssessionResult =
        serde_json::from_str(std::str::from_utf8(&assession_result.stdout)?)?;

    Ok(AssessionOutput {
        result: assession_result,
        debug_log: String::from_utf8(debug_log.stdout)?,
    })
}

fn assess(
    assignment_id: i64,
    submission_id: i64,
) -> std::result::Result<AssessionOutput, Box<dyn std::error::Error>> {
    const SERVER_ADDRESS: &str = "...";
    let assess_files_path =
        format!(".../grade_inator/priv/static/assignments/{assignment_id}/grade_files");
    let assess_files_path = Path::new(&assess_files_path);
    let submission_files_path =
        format!(".../grade_inator/priv/static/submissions/{submission_id}/submission_files");
    let submission_files_path = Path::new(&submission_files_path);

    scp_assess_files(assess_files_path, SERVER_ADDRESS)?;
    scp_submission_files(submission_files_path, SERVER_ADDRESS)?;

    run_assession(SERVER_ADDRESS, "1")?;
    wait_for_assession(SERVER_ADDRESS, "1")?;

    Ok(fetch_assession_result(SERVER_ADDRESS, "1")?)
}

fn main() -> std::result::Result<(), Box<dyn std::error::Error>> {
    let url = "mysql://root:admin@localhost:3306/grade_inator_dev";
    let pool = mysql::Pool::new(url)?;

    let mut conn = pool.get_conn()?;

    loop {
        let result = conn.query_first::<mysql::Row, _>(
            r"SELECT id as submission_id, assignment_id FROM submissions WHERE state_id = 1 order by updated_at asc",
        )?;

        if let Some(row) = result {
            let submission_id = row.get::<i64, _>(0).unwrap();
            let assignment_id = row.get::<i64, _>(1).unwrap();

            match assess(assignment_id, submission_id) {
                Ok(assession_output) => {
                    insert_assession_output_into_db(&mut conn, submission_id, assession_output)?
                }
                Err(assession_error) => {
                    insert_assession_error_into_db(
                        &mut conn,
                        submission_id,
                        assession_error.to_string().as_str(),
                    )?;

                    eprintln!("{assession_error}");
                }
            }
        } else {
            eprintln!("Currently no submissions to grade");

            std::thread::sleep(std::time::Duration::from_secs(3));
        }
    }
}