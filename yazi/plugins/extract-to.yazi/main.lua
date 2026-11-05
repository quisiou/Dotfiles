-- Uses 7zz. For tar.* / tgz, 7zz needs two steps (decompress, then untar),
-- so those are piped through sh.
local function extract(file, dest)
  local script = [[
    case "$1" in
      *.tar.*|*.tgz|*.tbz2|*.txz)
        7zz x -so "$1" | 7zz x -si -ttar -o"$2" -y ;;
      *)
        7zz x -o"$2" -y "$1" ;;
    esac
  ]]
  return Command("sh"):arg({ "-c", script, "sh", file, dest }):stderr(Command.PIPED):output()
end

local get_target = ya.sync(function()
    local h = cx.active.current.hovered
    if not h or h.cha.is_dir then return nil end
    return tostring(h.url), tostring(cx.active.current.cwd)
end)

-- "foo.tar.gz" -> "foo", "bar.zip" -> "bar"
local function stem(path)
    local name = path:match("([^/]+)$")
    name = name:gsub("%.tar%.[%w]+$", ""):gsub("%.[^.]+$", "")
    return name
end

return {
    entry = function()
        local file, cwd = get_target()
        if not file then
            return ya.notify { title = "Extract", content = "Hover an archive first", level = "warn", timeout = 3 }
        end

        local value, event = ya.input {
            title = "Extract to (empty = archive name):",
            pos = { "top-center", y = 3, w = 50 },
        }
        if event ~= 1 then return end -- cancelled

        local name = (value and value ~= "") and value or stem(file)
        local dest = name:sub(1, 1) == "/" and name or (cwd .. "/" .. name)

        local ok, err = Command("mkdir"):arg({ "-p", dest }):status()
        if not ok then
            return ya.notify { title = "Extract", content = "mkdir failed: " .. tostring(err), level = "error", timeout = 5 }
        end

        local out, err2 = extract(file, dest)
        if not out or not out.status.success then
            local msg = err2 and tostring(err2) or (out and out.stderr) or "unknown error"
            return ya.notify { title = "Extract failed", content = msg, level = "error", timeout = 6 }
        end

        ya.notify { title = "Extract", content = "Extracted to " .. dest, level = "info", timeout = 3 }
    end,
}
