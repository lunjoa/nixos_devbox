{ ... }:

{
  # Increase file watcher limits (needed for Node.js / webpack / large projects)
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;
  };
}
