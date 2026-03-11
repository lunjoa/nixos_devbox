{ ... }:

{
  # Increase file watcher limits (needed for Node.js / webpack / large projects)
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;
  };

  # RAM-backed scratch space for I/O-heavy builds and test runs.
  # Only consumes RAM for files actually stored (50% is the upper limit, not pre-allocated).
  fileSystems."/tmp/ramdisk" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "size=50%" "mode=1777" ];
  };
}
