// Copyright (c) 2021, Qualcomm Innovation Center, Inc. All rights reserved.
//
// SPDX-License-Identifier: BSD-3-Clause
//! Process spawning utilities
use async_io::block_on;
use futures_lite::io::AsyncWriteExt;
use smol_timeout::TimeoutExt;
use std::ffi::OsStr;
use std::io::{Result, Error, ErrorKind};
use std::process;
use std::process::{Command, ExitStatus, Output};
use async_process::unix::CommandExt;
use std::time::Duration;

#[derive(Debug)]
pub struct ChildResult {
    pub stdout: String,
    pub stderr: String,
    pub status: ExitStatus,
}

/// Execute a `command` with `args` and capture the output as a String
pub fn execute_capture_output<S: AsRef<OsStr>>(command: &str, args: &[S]) -> Result<ChildResult> {
    let output = Command::new(command).args(args).output()?;

    Ok(ChildResult {
        stdout: String::from_utf8_lossy(&output.stdout).to_string(),
        stderr: String::from_utf8_lossy(&output.stderr).to_string(),
        status: output.status,
    })
}

/// Send SIGTERM to a process
fn kill_gracefully(pid: i32) {
    unsafe {
        libc::kill(pid, libc::SIGTERM);
    }
}

/// Send SIGKILL to a process
fn kill_forcefully(pid: i32) {
    unsafe {
        libc::kill(pid, libc::SIGKILL);
    }
}

/// Mask certainy signals when executing subprocesses
// SAFETY: simple signal handling
unsafe fn pre_execute() {
    let mut set: libc::sigset_t = core::mem::MaybeUninit::uninit().assume_init();

    // GDB spawned under a controlling TTY will inherit it. This means it will also receive
    // SIGWINCH signals, which can prevent it from properly returning piped output to the parent
    // With this, we don't need to create a dedicated PTY and session
    libc::sigemptyset(&mut set);
    libc::sigaddset(&mut set, libc::SIGWINCH);
    // It will also receive user Ctrl+C signals which is not desired as this can create random
    // triage errors during GDB script processing
    libc::sigaddset(&mut set, libc::SIGINT);
    libc::sigprocmask(libc::SIG_BLOCK, &mut set, core::ptr::null_mut());
}

pub fn check_mysql_server_online() -> bool {

    let mut cur_mysqld_idx = rayon::current_thread_index().unwrap_or(0);
    cur_mysqld_idx += 7000;
    let mut cur_mysql_idx_str:String = ":".to_owned();
    cur_mysql_idx_str.push_str(cur_mysqld_idx.to_string().as_str());

    let mut cmd_check_signal = process::Command::new("lsof")
        .args(["-i", "-P"])
        .output().unwrap().stdout;

    let mut cmd_check_signal_str = std::str::from_utf8(&cmd_check_signal).unwrap();

    // log::info!("Debug: lsof, getting cmd res: {}, matching with mysql_idx_str: {}\n\n\n", cmd_check_signal_str, cur_mysql_idx_str);

    return if cmd_check_signal_str.find(cur_mysql_idx_str.as_str()) != None {
        true
    } else {
        false
    }
}

/// Execute a `command` with `args` while enforcing a timeout of `timeout_ms`, after which the
/// target process is killed. `input` can be passed if input is to be given to the process via
/// STDIN
pub fn execute_capture_output_timeout<S: AsRef<OsStr>>(
    command: &str,
    args: &[S],
    client_command_and_args: &[S],
    timeout_ms: u64,
    input: Option<Vec<u8>>
) -> Result<ChildResult> {

    while check_mysql_server_online() {
        // Server is still up? Wait for a couple seconds.
        // log::warn!("Warning: For command: {:?}, server is still up. ", command);
        std::thread::sleep(Duration::from_secs(5));
    }

    let output: Output = block_on(async {
        // SAFETY: only pre_exec call back is unsafe
        let cmd = unsafe {
            async_process::Command::new(command)
                .stdin(async_process::Stdio::null())
                .stdout(async_process::Stdio::piped())
                .stderr(async_process::Stdio::piped())
                .pre_exec(|| Ok(pre_execute()) )
                .args(args)
                .spawn()
        }?;

        std::thread::sleep(Duration::from_secs(3));
        while !check_mysql_server_online() {
            // Server is still up? Wait for a couple seconds.
            // log::info!("Info: For command: {:?}, DBMS server is still waiting to wake up. ", command);
            std::thread::sleep(Duration::from_secs(3));
        }

        // Run the client mysql. Pass in the query.
        let mut client_cmd = if input.is_none() {
            async_process::Command::new(&client_command_and_args[0])
                .stdin(async_process::Stdio::null())
                .stdout(async_process::Stdio::null())
                .stderr(async_process::Stdio::null())
                .args(&client_command_and_args[1..])
                .spawn()
        } else {
            async_process::Command::new(&client_command_and_args[0])
                .stdin(async_process::Stdio::piped())
                .stdout(async_process::Stdio::null())
                .stderr(async_process::Stdio::null())
                .args(&client_command_and_args[1..])
                .spawn()
        }?;

        if let Some(data) = input {
            let mut stdin: async_process::ChildStdin = client_cmd.stdin.take().unwrap();

            // XXX: this can deadlock
            stdin.write_all(data.as_ref()).await?;

            // log::info!("Passing in client cmd: {}", String::from_utf8(data).unwrap());
        }

        // let client_cmd_str_stdout = client_cmd.output().await?.stdout;
        // log::info!("Debug: client_cmd_str_stdout: {:?} \n\n\n", client_cmd_str_stdout);

        let pid = cmd.id();
        let client_pid = client_cmd.id();

        let output = cmd.output();

        let result = output
            .timeout(Duration::from_millis(timeout_ms))
            .await
            .map_or_else(
                || {
                    // this is racy, but its honestly the best we can do without crazy logic
                    kill_gracefully(pid as i32);
                    kill_gracefully(client_pid as i32);

                    // give the child sometime to clean up (with a debugger this means ending the
                    // process tree)
                    std::thread::sleep(std::time::Duration::from_millis(100));

                    // once again very racy
                    kill_forcefully(pid as i32);
                    kill_forcefully(client_pid as i32);

                    // wait for the background async_process thread to wait() on the PID
                    // this is also pretty racy
                    std::thread::sleep(std::time::Duration::from_millis(100));

                    Err(Error::new(ErrorKind::TimedOut, "Process exceeded timeout"))
                },
                |r| r,
            );

        while check_mysql_server_online() {
            // Server is still up? Wait for a couple seconds.
            // log::warn!("Warning: For command: {:?}, DBMS server is not killed after finishing debugging. ", command);
            std::thread::sleep(Duration::from_secs(3));
        }

        result
    })?;

    Ok(ChildResult {
        stdout: String::from_utf8_lossy(&output.stdout).to_string(),
        stderr: String::from_utf8_lossy(&output.stderr).to_string(),
        status: output.status,
    })
}
