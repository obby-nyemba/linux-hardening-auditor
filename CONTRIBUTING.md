# Contributing

Thanks for helping out. New checks are the easiest way to contribute, and the "Planned checks" list in the README is a good place to start.

## Ground rules

- **Read-only.** A check must never change the system, only report on it.
- **Zero dependencies.** Use only bash and standard Linux tools. If you use an optional tool, check that it exists first (`command -v tool`) and skip gracefully if it doesn't.
- **Explain the fix.** Every warning or failure must include the exact command or setting to fix it.
- **Don't stop the audit.** Use `return` in a check, never `exit`, because checks are loaded with `source` and an `exit` would end the whole run.
- **Be distro-aware.** Don't assume apt. Where it matters, handle pacman, apt and dnf.

## How to add a check

### 1. Create `checks/yourcheck.sh`

```bash
#!/usr/bin/env bash
# checks/yourcheck.sh: one-line description of what this checks

check_yourcheck() {
    section "Your Check Title"

    if [ some_condition ]; then
        pass "Thing is configured safely"
    else
        warn "Thing is configured unsafely" \
             "Exact command or setting that fixes it"
    fi
}
```

### 2. Use the report helpers (from `lib/report.sh`)

| Helper | Use it when | Counts toward score |
|---|---|---|
| `pass "message"` | The check is fine | Yes, as passed |
| `warn "message" "fix"` | Worth fixing, not critical | Yes, as not passed |
| `fail "message" "fix"` | A real security problem | Yes, as not passed |
| `section "Title"` | Starting your check's output | No |

`warn` and `fail` always need **two** arguments. If there's no fix to suggest, pass an empty string: `warn "message" ""`. The script runs with `set -u`, so a missing argument is an error.

### 3. Hook it into `audit.sh`

Add a `source` line with the others:

```bash
source "$SCRIPT_DIR/checks/yourcheck.sh"
```

and call your function before `print_summary`:

```bash
check_yourcheck
```

### 4. Test it

```
bash -n checks/yourcheck.sh && echo "syntax OK"
./audit.sh
```

Test both the passing and the failing case if you can, and run it as a normal user and with `sudo`. A check that needs root should skip with a message when not root, not crash.

## Opt-in checks

A check that sends traffic to other machines, or takes a long time, should not run by default. Follow the `--network` example: add a flag in `audit.sh` and only call the function when it's set.

## Style

- Four-space indentation.
- Declare variables with `local` inside functions.
- Quote your variables (`"$var"`).
- Prefix helper functions with your check name (like `net_why`) so names don't clash.

## Submitting

1. Fork the repo and make a branch: `git checkout -b check-sudoers`
2. Add your check and test it.
3. Add a row to the checks table in `README.md` (and remove it from "Planned checks" if it was listed).
4. Open a pull request that says what the check looks for and why it matters.

By contributing, you agree your work is released under the project's MIT license.