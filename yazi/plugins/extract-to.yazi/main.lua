-- yazi/plugins/extract-to.yazi/main.lua


-- tar family goes through tar (it auto-detects gz/xz/bz2/zst on extraction),
-- everything else (zip, 7z, rar, ...) goes through 7zz.
local function extract(file, dest)
  local script = [[
    case "$1" in
      *.tar|*.tar.gz|*.tar.xz|*.tar.bz2|*.tar.zst|*.tgz|*.txz|*.tbz2|*.tbz|*.tzst)
        tar -xf "$1" -C "$2" ;;
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

        local st, err = Command("mkdir"):arg({ "-p", dest }):status()
        if not st or not st.success then
            return ya.notify { title = "Extract", content = "mkdir failed: " .. tostring(err or "non-zero exit"), level = "error", timeout = 5 }
        end

        local out, err2 = extract(file, dest)
        if not out or not out.status.success then
            local msg = err2 and tostring(err2) or (out and out.stderr) or "unknown error"
            return ya.notify { title = "Extract failed", content = msg, level = "error", timeout = 6 }
        end

        ya.notify { title = "Extract", content = "Extracted to " .. dest, level = "info", timeout = 3 }
    end,
}
