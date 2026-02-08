-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                     CLAUDE CODE HARNESS FOR NEOVIM                        ║
-- ║         Full IDE integration: terminal, diffs, file watching              ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ── State ───────────────────────────────────────────────────────────────────
M.state = {
  -- Terminal
  term_buf = nil,
  term_win = nil,
  term_chan = nil,

  -- Diff view
  diff_buf = nil,
  diff_win = nil,

  -- Modified files
  modified_buf = nil,
  modified_win = nil,
  modified_files = {},

  -- File watcher
  watcher_timer = nil,
  watched_files = {},

  -- Layout
  layout_open = false,
}

-- ── Configuration ───────────────────────────────────────────────────────────
M.config = {
  terminal_width = 80,        -- Width of Claude terminal
  diff_height = 15,           -- Height of diff panel
  watch_interval = 1000,      -- File watch interval (ms)
  auto_watch = true,          -- Auto-watch files Claude modifies

  -- Claude CLI flags
  claude = {
    model = nil,              -- nil = default, or "opus", "sonnet", "haiku"
    continue_session = false, -- --continue flag
    resume = nil,             -- --resume <session_id>
    chrome = false,           -- --chrome for browser automation
    mcp = {},                 -- MCP servers to enable
    permission_mode = nil,    -- nil, "plan", "full"
    verbose = false,          -- --verbose
    max_turns = nil,          -- --max-turns N
    custom_flags = "",        -- Any additional flags
  },
}

-- ══════════════════════════════════════════════════════════════════════════════
-- TERMINAL MANAGEMENT
-- ══════════════════════════════════════════════════════════════════════════════

-- Build Claude command with flags
local function build_claude_cmd()
  local cmd = "claude"
  local c = M.config.claude

  if c.model then
    cmd = cmd .. " --model " .. c.model
  end

  if c.continue_session then
    cmd = cmd .. " --continue"
  end

  if c.resume then
    cmd = cmd .. " --resume " .. c.resume
  end

  if c.chrome then
    cmd = cmd .. " --chrome"
  end

  if c.mcp and #c.mcp > 0 then
    for _, server in ipairs(c.mcp) do
      cmd = cmd .. " --mcp " .. server
    end
  end

  if c.permission_mode then
    cmd = cmd .. " --permission-mode " .. c.permission_mode
  end

  if c.verbose then
    cmd = cmd .. " --verbose"
  end

  if c.max_turns then
    cmd = cmd .. " --max-turns " .. c.max_turns
  end

  if c.custom_flags and c.custom_flags ~= "" then
    cmd = cmd .. " " .. c.custom_flags
  end

  return cmd
end

function M.open_terminal(opts)
  opts = opts or {}

  if M.state.term_win and vim.api.nvim_win_is_valid(M.state.term_win) then
    vim.api.nvim_set_current_win(M.state.term_win)
    return
  end

  -- Create vertical split on right
  vim.cmd("botright vsplit")
  M.state.term_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(M.state.term_win, M.config.terminal_width)

  -- Create or reuse terminal buffer
  if M.state.term_buf and vim.api.nvim_buf_is_valid(M.state.term_buf) and not opts.restart then
    vim.api.nvim_win_set_buf(M.state.term_win, M.state.term_buf)
  else
    -- Create new terminal with claude
    M.state.term_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(M.state.term_win, M.state.term_buf)

    local cmd = build_claude_cmd()
    vim.notify("Starting: " .. cmd, vim.log.levels.INFO)

    M.state.term_chan = vim.fn.termopen(cmd, {
      on_stdout = function(_, data)
        M.parse_claude_output(data)
      end,
      on_exit = function()
        M.state.term_chan = nil
        vim.notify("Claude Code exited", vim.log.levels.INFO)
      end,
    })

    vim.api.nvim_buf_set_name(M.state.term_buf, "Claude Code")
  end

  -- Window options
  vim.wo[M.state.term_win].number = false
  vim.wo[M.state.term_win].relativenumber = false
  vim.wo[M.state.term_win].signcolumn = "no"

  -- Start in terminal mode
  vim.cmd("startinsert")
end

function M.close_terminal()
  if M.state.term_win and vim.api.nvim_win_is_valid(M.state.term_win) then
    vim.api.nvim_win_close(M.state.term_win, true)
  end
  M.state.term_win = nil
end

function M.toggle_terminal()
  if M.state.term_win and vim.api.nvim_win_is_valid(M.state.term_win) then
    M.close_terminal()
  else
    M.open_terminal()
  end
end

function M.focus_terminal()
  if M.state.term_win and vim.api.nvim_win_is_valid(M.state.term_win) then
    vim.api.nvim_set_current_win(M.state.term_win)
    vim.cmd("startinsert")
  else
    M.open_terminal()
  end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SEND TO CLAUDE
-- ══════════════════════════════════════════════════════════════════════════════

local function get_visual_selection()
  local _, ls, cs = unpack(vim.fn.getpos("'<"))
  local _, le, ce = unpack(vim.fn.getpos("'>"))
  local lines = vim.api.nvim_buf_get_lines(0, ls - 1, le, false)
  if #lines == 0 then return "" end
  if #lines == 1 then
    lines[1] = string.sub(lines[1], cs, ce)
  else
    lines[1] = string.sub(lines[1], cs)
    lines[#lines] = string.sub(lines[#lines], 1, ce)
  end
  return table.concat(lines, "\n")
end

function M.send_to_claude(text)
  if not M.state.term_chan then
    M.open_terminal()
    -- Wait a bit for terminal to initialize
    vim.defer_fn(function()
      if M.state.term_chan then
        vim.api.nvim_chan_send(M.state.term_chan, text)
      end
    end, 500)
  else
    vim.api.nvim_chan_send(M.state.term_chan, text)
  end
end

function M.send_selection()
  local selection = get_visual_selection()
  if selection == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end

  -- Format for Claude
  local filepath = vim.fn.expand("%:p")
  local filetype = vim.bo.filetype
  local text = string.format(
    "Here's code from %s:\n```%s\n%s\n```\n",
    filepath, filetype, selection
  )

  M.send_to_claude(text)
  M.focus_terminal()
end

function M.send_file()
  local filepath = vim.fn.expand("%:p")
  M.send_to_claude("@" .. filepath .. " ")
  M.focus_terminal()
end

function M.send_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, "\n")
  local filepath = vim.fn.expand("%:p")
  local filetype = vim.bo.filetype

  local text = string.format(
    "Here's the full content of %s:\n```%s\n%s\n```\n",
    filepath, filetype, content
  )

  M.send_to_claude(text)
  M.focus_terminal()
end

function M.ask(prompt)
  if prompt then
    M.send_to_claude(prompt .. "\n")
    M.focus_terminal()
  else
    vim.ui.input({ prompt = "Ask Claude: " }, function(input)
      if input and input ~= "" then
        M.send_to_claude(input .. "\n")
        M.focus_terminal()
      end
    end)
  end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- DIFF VIEW
-- ══════════════════════════════════════════════════════════════════════════════

function M.open_diff()
  if M.state.diff_win and vim.api.nvim_win_is_valid(M.state.diff_win) then
    vim.api.nvim_set_current_win(M.state.diff_win)
    return
  end

  -- Create horizontal split at bottom
  vim.cmd("botright split")
  M.state.diff_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(M.state.diff_win, M.config.diff_height)

  -- Create buffer for diff
  M.state.diff_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(M.state.diff_win, M.state.diff_buf)
  vim.api.nvim_buf_set_option(M.state.diff_buf, "filetype", "diff")
  vim.api.nvim_buf_set_name(M.state.diff_buf, "Git Diff")

  -- Window options
  vim.wo[M.state.diff_win].number = false
  vim.wo[M.state.diff_win].relativenumber = false
  vim.wo[M.state.diff_win].signcolumn = "no"
  vim.wo[M.state.diff_win].cursorline = true

  M.refresh_diff()
end

function M.close_diff()
  if M.state.diff_win and vim.api.nvim_win_is_valid(M.state.diff_win) then
    vim.api.nvim_win_close(M.state.diff_win, true)
  end
  M.state.diff_win = nil
  M.state.diff_buf = nil
end

function M.toggle_diff()
  if M.state.diff_win and vim.api.nvim_win_is_valid(M.state.diff_win) then
    M.close_diff()
  else
    M.open_diff()
  end
end

function M.refresh_diff()
  if not M.state.diff_buf or not vim.api.nvim_buf_is_valid(M.state.diff_buf) then
    return
  end

  -- Get git diff
  local diff = vim.fn.system("git diff --color=never 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    diff = "Not a git repository or no changes"
  elseif diff == "" then
    diff = "No uncommitted changes"
  end

  local lines = vim.split(diff, "\n")
  vim.api.nvim_buf_set_option(M.state.diff_buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(M.state.diff_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.state.diff_buf, "modifiable", false)
end

function M.show_file_diff(filepath)
  filepath = filepath or vim.fn.expand("%:p")

  if not M.state.diff_win or not vim.api.nvim_win_is_valid(M.state.diff_win) then
    M.open_diff()
  end

  local diff = vim.fn.system("git diff --color=never -- " .. vim.fn.shellescape(filepath) .. " 2>/dev/null")
  if vim.v.shell_error ~= 0 or diff == "" then
    diff = "No changes in " .. filepath
  end

  local lines = vim.split(diff, "\n")
  vim.api.nvim_buf_set_option(M.state.diff_buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(M.state.diff_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.state.diff_buf, "modifiable", false)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- MODIFIED FILES PANEL
-- ══════════════════════════════════════════════════════════════════════════════

function M.open_modified()
  if M.state.modified_win and vim.api.nvim_win_is_valid(M.state.modified_win) then
    vim.api.nvim_set_current_win(M.state.modified_win)
    return
  end

  -- Create split below terminal
  if M.state.term_win and vim.api.nvim_win_is_valid(M.state.term_win) then
    vim.api.nvim_set_current_win(M.state.term_win)
    vim.cmd("belowright split")
  else
    vim.cmd("botright split")
  end

  M.state.modified_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(M.state.modified_win, 10)

  -- Create buffer
  M.state.modified_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(M.state.modified_win, M.state.modified_buf)
  vim.api.nvim_buf_set_name(M.state.modified_buf, "Modified Files")

  -- Window options
  vim.wo[M.state.modified_win].number = false
  vim.wo[M.state.modified_win].relativenumber = false
  vim.wo[M.state.modified_win].signcolumn = "no"
  vim.wo[M.state.modified_win].cursorline = true

  -- Keymaps
  local opts = { buffer = M.state.modified_buf, silent = true }
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    local filepath = line:match("^[%s]*[MA%?]+%s+(.+)$") or line:match("^%s*(.+)$")
    if filepath and filepath ~= "" then
      -- Find the editor window and open file there
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if buf ~= M.state.term_buf and buf ~= M.state.diff_buf and buf ~= M.state.modified_buf then
          vim.api.nvim_set_current_win(win)
          vim.cmd("edit " .. filepath)
          return
        end
      end
    end
  end, opts)

  vim.keymap.set("n", "d", function()
    local line = vim.api.nvim_get_current_line()
    local filepath = line:match("^[%s]*[MA%?]+%s+(.+)$") or line:match("^%s*(.+)$")
    if filepath then
      M.show_file_diff(filepath)
    end
  end, opts)

  vim.keymap.set("n", "q", M.close_modified, opts)

  M.refresh_modified()
end

function M.close_modified()
  if M.state.modified_win and vim.api.nvim_win_is_valid(M.state.modified_win) then
    vim.api.nvim_win_close(M.state.modified_win, true)
  end
  M.state.modified_win = nil
  M.state.modified_buf = nil
end

function M.toggle_modified()
  if M.state.modified_win and vim.api.nvim_win_is_valid(M.state.modified_win) then
    M.close_modified()
  else
    M.open_modified()
  end
end

function M.refresh_modified()
  if not M.state.modified_buf or not vim.api.nvim_buf_is_valid(M.state.modified_buf) then
    return
  end

  -- Get git status
  local status = vim.fn.system("git status --porcelain 2>/dev/null")
  local lines = { "╭─ Modified Files ─────────────────────────────────────────────╮" }

  if vim.v.shell_error ~= 0 then
    table.insert(lines, "│  Not a git repository                                        │")
  elseif status == "" then
    table.insert(lines, "│  No modified files                                           │")
  else
    for line in status:gmatch("[^\r\n]+") do
      table.insert(lines, "│  " .. line .. string.rep(" ", 60 - #line) .. "│")
    end
  end

  table.insert(lines, "╰──────────────────────────────────────────────────────────────╯")
  table.insert(lines, "")
  table.insert(lines, "  [Enter] Open file    [d] Show diff    [q] Close")

  vim.api.nvim_buf_set_option(M.state.modified_buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(M.state.modified_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.state.modified_buf, "modifiable", false)

  -- Store files for watching
  M.state.modified_files = {}
  for line in status:gmatch("[^\r\n]+") do
    local filepath = line:match("^[%s]*[MA%?]+%s+(.+)$")
    if filepath then
      table.insert(M.state.modified_files, filepath)
    end
  end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- FILE WATCHING
-- ══════════════════════════════════════════════════════════════════════════════

function M.start_watching()
  if M.state.watcher_timer then
    return
  end

  M.state.watcher_timer = vim.loop.new_timer()
  M.state.watcher_timer:start(0, M.config.watch_interval, vim.schedule_wrap(function()
    M.check_file_changes()
  end))

  vim.notify("File watching started", vim.log.levels.INFO)
end

function M.stop_watching()
  if M.state.watcher_timer then
    M.state.watcher_timer:stop()
    M.state.watcher_timer:close()
    M.state.watcher_timer = nil
    vim.notify("File watching stopped", vim.log.levels.INFO)
  end
end

function M.check_file_changes()
  -- Refresh modified files panel if open
  if M.state.modified_buf and vim.api.nvim_buf_is_valid(M.state.modified_buf) then
    M.refresh_modified()
  end

  -- Refresh diff if open
  if M.state.diff_buf and vim.api.nvim_buf_is_valid(M.state.diff_buf) then
    M.refresh_diff()
  end

  -- Check for external changes to open buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local filepath = vim.api.nvim_buf_get_name(buf)
      if filepath ~= "" and vim.fn.filereadable(filepath) == 1 then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd("checktime")
        end)
      end
    end
  end
end

-- Parse Claude output to detect file modifications
function M.parse_claude_output(data)
  if not data then return end

  for _, line in ipairs(data) do
    -- Detect file write patterns from Claude
    local written = line:match("Wrote to ([%w%p]+)") or
                    line:match("Created ([%w%p]+)") or
                    line:match("Updated ([%w%p]+)")
    if written then
      table.insert(M.state.watched_files, written)
      vim.schedule(function()
        M.refresh_modified()
        M.refresh_diff()
        -- Reload the file if it's open
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          local bufname = vim.api.nvim_buf_get_name(buf)
          if bufname:match(written .. "$") then
            vim.api.nvim_buf_call(buf, function()
              vim.cmd("edit!")
            end)
          end
        end
      end)
    end
  end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- FULL LAYOUT
-- ══════════════════════════════════════════════════════════════════════════════

function M.open_layout()
  if M.state.layout_open then
    return
  end

  -- Open Claude terminal on right
  M.open_terminal()

  -- Open modified files below terminal
  M.open_modified()

  -- Open diff at bottom
  M.open_diff()

  -- Start file watching
  M.start_watching()

  -- Focus back on editor
  vim.cmd("wincmd h")

  M.state.layout_open = true
end

function M.close_layout()
  M.close_terminal()
  M.close_modified()
  M.close_diff()
  M.stop_watching()
  M.state.layout_open = false
end

function M.toggle_layout()
  if M.state.layout_open then
    M.close_layout()
  else
    M.open_layout()
  end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CLAUDE FLAGS CONFIGURATION
-- ══════════════════════════════════════════════════════════════════════════════

function M.set_model(model)
  M.config.claude.model = model
  vim.notify("Claude model: " .. (model or "default"), vim.log.levels.INFO)
end

function M.set_continue(enable)
  M.config.claude.continue_session = enable
  vim.notify("Continue session: " .. tostring(enable), vim.log.levels.INFO)
end

function M.set_chrome(enable)
  M.config.claude.chrome = enable
  vim.notify("Chrome mode: " .. tostring(enable), vim.log.levels.INFO)
end

function M.set_permission_mode(mode)
  M.config.claude.permission_mode = mode
  vim.notify("Permission mode: " .. (mode or "default"), vim.log.levels.INFO)
end

function M.set_verbose(enable)
  M.config.claude.verbose = enable
  vim.notify("Verbose: " .. tostring(enable), vim.log.levels.INFO)
end

function M.set_custom_flags(flags)
  M.config.claude.custom_flags = flags
  vim.notify("Custom flags: " .. flags, vim.log.levels.INFO)
end

function M.restart()
  -- Kill existing terminal
  if M.state.term_chan then
    vim.fn.jobstop(M.state.term_chan)
  end
  if M.state.term_buf and vim.api.nvim_buf_is_valid(M.state.term_buf) then
    vim.api.nvim_buf_delete(M.state.term_buf, { force = true })
  end
  M.state.term_buf = nil
  M.state.term_chan = nil

  -- Reopen with new settings
  if M.state.term_win and vim.api.nvim_win_is_valid(M.state.term_win) then
    M.open_terminal({ restart = true })
  end
end

function M.show_config()
  local c = M.config.claude
  local lines = {
    "╭─ Claude Configuration ────────────────────────────────────────╮",
    "│                                                                │",
    "│  Model:         " .. string.format("%-45s", c.model or "default") .. "│",
    "│  Continue:      " .. string.format("%-45s", tostring(c.continue_session)) .. "│",
    "│  Resume:        " .. string.format("%-45s", c.resume or "none") .. "│",
    "│  Chrome:        " .. string.format("%-45s", tostring(c.chrome)) .. "│",
    "│  Permission:    " .. string.format("%-45s", c.permission_mode or "default") .. "│",
    "│  Verbose:       " .. string.format("%-45s", tostring(c.verbose)) .. "│",
    "│  Max Turns:     " .. string.format("%-45s", c.max_turns or "unlimited") .. "│",
    "│  Custom Flags:  " .. string.format("%-45s", c.custom_flags ~= "" and c.custom_flags or "none") .. "│",
    "│                                                                │",
    "│  Command: " .. string.format("%-52s", build_claude_cmd():sub(1, 52)) .. "│",
    "╰────────────────────────────────────────────────────────────────╯",
  }
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

function M.configure()
  -- Interactive configuration via vim.ui.select
  vim.ui.select({
    "Model",
    "Continue Session",
    "Chrome Mode",
    "Permission Mode",
    "Verbose",
    "Custom Flags",
    "Show Current Config",
    "Restart Claude",
  }, {
    prompt = "Configure Claude:",
  }, function(choice)
    if not choice then return end

    if choice == "Model" then
      vim.ui.select({ "default", "opus", "sonnet", "haiku" }, {
        prompt = "Select model:",
      }, function(model)
        if model then
          M.set_model(model == "default" and nil or model)
        end
      end)

    elseif choice == "Continue Session" then
      vim.ui.select({ "Enable", "Disable" }, {
        prompt = "Continue previous session?",
      }, function(opt)
        if opt then
          M.set_continue(opt == "Enable")
        end
      end)

    elseif choice == "Chrome Mode" then
      vim.ui.select({ "Enable", "Disable" }, {
        prompt = "Enable Chrome browser automation?",
      }, function(opt)
        if opt then
          M.set_chrome(opt == "Enable")
        end
      end)

    elseif choice == "Permission Mode" then
      vim.ui.select({ "default", "plan", "full" }, {
        prompt = "Permission mode:",
      }, function(mode)
        if mode then
          M.set_permission_mode(mode == "default" and nil or mode)
        end
      end)

    elseif choice == "Verbose" then
      vim.ui.select({ "Enable", "Disable" }, {
        prompt = "Verbose output?",
      }, function(opt)
        if opt then
          M.set_verbose(opt == "Enable")
        end
      end)

    elseif choice == "Custom Flags" then
      vim.ui.input({ prompt = "Custom flags: ", default = M.config.claude.custom_flags }, function(flags)
        if flags then
          M.set_custom_flags(flags)
        end
      end)

    elseif choice == "Show Current Config" then
      M.show_config()

    elseif choice == "Restart Claude" then
      M.restart()
    end
  end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- ACCEPT/REJECT CHANGES
-- ══════════════════════════════════════════════════════════════════════════════

function M.accept_changes()
  local filepath = vim.fn.expand("%:p")
  vim.fn.system("git add " .. vim.fn.shellescape(filepath))
  M.refresh_modified()
  M.refresh_diff()
  vim.notify("Changes accepted: " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
end

function M.reject_changes()
  local filepath = vim.fn.expand("%:p")
  local confirm = vim.fn.confirm("Reject all changes to " .. vim.fn.expand("%:t") .. "?", "&Yes\n&No", 2)
  if confirm == 1 then
    vim.fn.system("git checkout -- " .. vim.fn.shellescape(filepath))
    vim.cmd("edit!")
    M.refresh_modified()
    M.refresh_diff()
    vim.notify("Changes rejected: " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
  end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SETUP
-- ══════════════════════════════════════════════════════════════════════════════

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Commands
  vim.api.nvim_create_user_command("Claude", M.toggle_terminal, {})
  vim.api.nvim_create_user_command("ClaudeLayout", M.toggle_layout, {})
  vim.api.nvim_create_user_command("ClaudeDiff", M.toggle_diff, {})
  vim.api.nvim_create_user_command("ClaudeModified", M.toggle_modified, {})
  vim.api.nvim_create_user_command("ClaudeSend", M.send_selection, { range = true })
  vim.api.nvim_create_user_command("ClaudeFile", M.send_file, {})
  vim.api.nvim_create_user_command("ClaudeBuffer", M.send_buffer, {})
  vim.api.nvim_create_user_command("ClaudeAsk", function(cmd)
    M.ask(cmd.args ~= "" and cmd.args or nil)
  end, { nargs = "?" })
  vim.api.nvim_create_user_command("ClaudeAccept", M.accept_changes, {})
  vim.api.nvim_create_user_command("ClaudeReject", M.reject_changes, {})
  vim.api.nvim_create_user_command("ClaudeWatch", M.start_watching, {})
  vim.api.nvim_create_user_command("ClaudeUnwatch", M.stop_watching, {})

  -- Configuration commands
  vim.api.nvim_create_user_command("ClaudeConfig", M.configure, {})
  vim.api.nvim_create_user_command("ClaudeRestart", M.restart, {})
  vim.api.nvim_create_user_command("ClaudeShowConfig", M.show_config, {})

  vim.api.nvim_create_user_command("ClaudeModel", function(cmd)
    local model = cmd.args ~= "" and cmd.args or nil
    M.set_model(model)
    if M.state.term_chan then M.restart() end
  end, {
    nargs = "?",
    complete = function() return { "opus", "sonnet", "haiku" } end,
  })

  vim.api.nvim_create_user_command("ClaudeContinue", function()
    M.config.claude.continue_session = true
    M.restart()
  end, {})

  vim.api.nvim_create_user_command("ClaudeChrome", function()
    M.config.claude.chrome = not M.config.claude.chrome
    vim.notify("Chrome: " .. tostring(M.config.claude.chrome), vim.log.levels.INFO)
    if M.state.term_chan then M.restart() end
  end, {})

  vim.api.nvim_create_user_command("ClaudeFlags", function(cmd)
    M.set_custom_flags(cmd.args)
    if M.state.term_chan then M.restart() end
  end, { nargs = "*" })

  -- Auto-refresh on buffer write
  vim.api.nvim_create_autocmd("BufWritePost", {
    callback = function()
      vim.defer_fn(function()
        M.refresh_modified()
        M.refresh_diff()
      end, 100)
    end,
  })

  -- Auto-reload files modified externally
  vim.opt.autoread = true
  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
    callback = function()
      vim.cmd("checktime")
    end,
  })

  -- Terminal keymaps for Claude Code
  -- Pass all Claude keybindings through, use Ctrl+Space to exit terminal mode
  vim.api.nvim_create_autocmd("TermOpen", {
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local opts = { buffer = buf, noremap = true, silent = true }

      local function send(seq)
        local job_id = vim.b.terminal_job_id
        if job_id then
          vim.api.nvim_chan_send(job_id, seq)
        end
      end

      -- EXIT TERMINAL MODE: Ctrl+Space
      vim.keymap.set("t", "<C-Space>", "<C-\\><C-n>", opts)

      -- ESCAPE: pass through to Claude Code (single and double for rewind)
      vim.keymap.set("t", "<Esc>", function() send("\x1b") end, opts)

      -- NEWLINES: Ctrl+J and Shift+Enter
      vim.keymap.set("t", "<C-j>", function() send("\n") end, opts)
      vim.keymap.set("t", "<S-Enter>", function() send("\x1b[13;2u") end, opts)
      vim.keymap.set("t", "<M-CR>", function() send("\n") end, opts)

      -- MODEL/THINKING: Alt+P, Alt+T, Alt+M
      vim.keymap.set("t", "<M-p>", function() send("\x1bp") end, opts)
      vim.keymap.set("t", "<M-t>", function() send("\x1bt") end, opts)
      vim.keymap.set("t", "<M-m>", function() send("\x1bm") end, opts)

      -- PERMISSION MODE: Shift+Tab
      vim.keymap.set("t", "<S-Tab>", function() send("\x1b[Z") end, opts)
    end,
  })

  -- Auto-enter insert mode when clicking on terminal (mouse click or focus)
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
      if buftype == "terminal" then
        vim.cmd("startinsert")
      end
    end,
  })
end

return M
