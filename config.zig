const std = @import("std");

pub var targets: ?[]std.Build.ResolvedTarget = null;
pub var optimize: std.builtin.OptimizeMode = .Debug;

pub fn default_profile() void {}
