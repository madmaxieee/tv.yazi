---@diagnostic disable: redefined-local, undefined-field

local M = {}

local function strip(str)
  return (str:gsub("^%s*(.-)%s*$", "%1"))
end

---@param err Error
local function err_notify(err)
  ya.notify {
    title = "TV",
    content = tostring(err),
    timeout = 5,
    level = "error",
  }
end

local function run_tv(cwd, channel)
  local function _run_tv_internal()
    local child, err = Command("tv")
      :arg({ channel })
      :cwd(tostring(cwd))
      :stdin(Command.INHERIT)
      :stdout(Command.PIPED)
      :stderr(Command.INHERIT)
      :spawn()

    if not child then
      return nil, Err("Failed to start `tv`, error: %s", err)
    end

    local output, err = child:wait_with_output()

    if not output then
      return nil, Err("Cannot read `tv` output, error: %s", err)
    elseif not output.status.success and output.status.code ~= 130 then
      return nil, Err("`tv` exited with error code %s", output.status.code)
    end

    return output.stdout, nil
  end

  local permit = ui.hide()
  local result, err = _run_tv_internal()
  permit:drop()

  return result, err
end

local on_cable_output = {
  files = function(cwd, output)
    if output == "" then
      return
    end
    local url = Url(strip(output))
    if not url.is_absolute then
      url = cwd:join(url)
    end
    ya.emit("reveal", { url, raw = true })
    return nil
  end,
  text = function(cwd, output)
    if output == "" then
      return
    end
    local file, line = output:match [[(.+):(%d+)]]
    if file == nil or line == nil then
      return Err("Output '%s' does not match the expected pattern", output)
    end
    local url = Url(file)
    if not url.is_absolute then
      url = cwd:join(url)
    end
    local line_number = tonumber(line)
    ya.emit("reveal", { url, raw = true })
    ya.emit("shell", {
      ([[nvim "+%d" "$0"]]):format(line_number),
      block = true,
    })
    return nil
  end,
}

function M:entry(job)
  ya.emit("escape", { visual = true })

  local cwd, err = fs.cwd()
  if err ~= nil then
    err_notify(err)
    return
  end

  local cable
  if #job.args == 0 then
    cable = "files"
  elseif #job.args == 1 then
    cable = job.args[1]
  else
    err_notify(Err("expected 0 or 1 argument got %d", #job.args))
    return
  end

  if not on_cable_output[cable] then
    err_notify(Err("expected files or text, got %s", job.args[1]))
    return
  end

  local output, err = run_tv(cwd, cable)
  if err ~= nil then
    err_notify(err)
    return
  end

  local err = on_cable_output[cable](cwd, output)
  if err ~= nil then
    err_notify(err)
    return
  end
end

return M
