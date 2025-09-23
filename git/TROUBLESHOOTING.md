# Forgejo Runner Troubleshooting

## Problem: Runner does not connect ("unauthenticated: unregistered runner")

### Symptoms
- Runner logs show repeated errors like:
  > failed to fetch task ... error="unauthenticated: unregistered runner"
- No jobs are picked up by the runner.

### Checklist
1. **Check docker-compose.yaml**
   - Ensure the `runner-daemon` service has the correct `environment` variables:
     - `RUNNER_TOKEN` (must be valid and not expired)
     - `SHARED_SECRET` (must match the `git` service)
     - `RUNNER_LABELS` (optional, but should be set if referenced)
   - The `links` or `depends_on` for `runner-daemon` should include `git` and `docker-in-docker`.
   - The `command` for `runner-daemon` should include a registration step, e.g.:
     ```sh
     forgejo-runner register --no-interactive --instance http://git:3000 --token ${RUNNER_TOKEN} --name runner --labels "${RUNNER_LABELS}"
     ```
   - The `git` service should expose port 3000 and be on the same Docker network as the runner.

2. **Check Environment Variables**
   - Make sure your `.env` file or environment has the correct values for all variables referenced in `docker-compose.yaml`.
   - If you see warnings about unset variables (e.g. `RUNNER_LABELS`), set them or provide defaults.

3. **Runner Registration**
   - If the runner is not registered, it will not authenticate. The registration command should succeed and not be skipped.
   - If the token is invalid or expired, re-generate it from the Forgejo web UI (Admin > Actions Runners > Generate Token).

4. **Service Startup Order**
   - The `git` service (Forgejo) must be up and accessible before the runner registers. If not, the registration will fail and the runner will remain unregistered.
   - Use `depends_on` to help with startup order, but be aware it does not wait for the service to be ready, only started.

5. **Network Connectivity**
   - The runner must be able to reach the Forgejo instance at the address specified (e.g., `http://git:3000`).
   - Check Docker network settings and service names. Use `docker-compose ps` to verify container names and status.

6. **Logs**
   - Check logs for both the runner and Forgejo server for authentication or registration errors.
   - Use `docker logs <container>` to view logs.

### Recovery Steps


If you see `unauthenticated: unregistered runner` and you manage tokens and registration via docker-compose (not the web UI), try the following:
   1. **Always use the `mise run git-start` script to start your stack.** This script parses `images.jsonc` and sets the correct `RUNNER_LABELS` before running `docker compose up -d`. Running `docker compose up -d` directly will not set labels and can cause registration or job pickup to fail.
   2. Stop the runner container if it's running.
   3. Ensure your `.env` or compose file has a valid `RUNNER_TOKEN` and `SHARED_SECRET` (these should be generated and managed by your automation, not manually from the web UI).
   4. Double-check that the `runner-daemon` service in `docker-compose.yaml` is running the registration command on startup, and that it is not failing silently (see logs for registration output).
   5. Make sure the `git` service is fully up and accessible before the runner attempts to register. You may need to add a wait/retry loop in the runner's startup command.
   6. Run `mise run git-start` from the project root or `cd git && mise run git-start` to ensure labels and all environment variables are set up correctly.
   7. Watch the logs for successful registration and connection.

**Note:** If you do not use the web UI to fetch tokens, ensure your automation or provisioning scripts are generating and injecting valid tokens into the environment before starting the runner. If the runner still fails to register, check for network issues, service startup order, or token mismatches between the runner and Forgejo server.

**Labels troubleshooting:**
If the runner registers but has no labels, it is likely because `RUNNER_LABELS` was not set. Always use the `mise run git-start` script to ensure labels are parsed and exported from `images.jsonc`.

---

Add more troubleshooting steps here as you encounter new issues, especially any related to docker-compose configuration or service dependencies.
