-- yazi/plugins/compress-to.yazi/main.lua


-- Archive format is picked from the extension you type.
local function compress(cwd, out, items)
    local script = [[
        out="$1"; shift
        if [ -e "$out" ]; then echo "$out already exists" >&2; exit 1; fi
        case "$out" in
            *.tar.gz|*.tgz)   tar -czf "$out" -- "$@" ;;
            *.tar.xz|*.txz)   tar -cJf "$out" -- "$@" ;;
            *.tar.bz2|*.tbz2) tar -cjf "$out" -- "$@" ;;
            *.tar)            tar -cf  "$out" -- "$@" ;;
            *.7z)             7zz a -t7z  "$out" -- "$@" ;;
            *)                7zz a -tzip "$out" -- "$@" ;;
        esac
        rc=$?
        # don't leave a half-written archive behind (we know $out didn't exist before)
        [ $rc -ne 0 ] && rm -f "$out"
        exit $rc
    ]]
    local args = { "-c", script, "sh", out }
    for _, i in ipairs(items) do args[#args + 1] = i end
    return Command("sh"):arg(args):cwd(cwd):stderr(Command.PIPED):output()
end

-- selected items may be File objects (have .url) or plain Url objects
local function to_path(x)
    local ok, url = pcall(function() return x.url end)
    if ok and url then return tostring(url) end
    return tostring(x)
end

local get_state = ya.sync(function()
    local paths, single_is_dir = {}, false
    for _, f in pairs(cx.active.selected) do
        paths[#paths + 1] = to_path(f)
    end
    if #paths == 0 then
        local h = cx.active.current.hovered
        if h then
            paths[1] = to_path(h)
            single_is_dir = h.cha.is_dir
        end
    end
    return paths, tostring(cx.active.current.cwd), single_is_dir
end)

local function basename(p) return p:match("([^/]+)/*$") end

local function stem(name)
    name = name:gsub("%.tar%.[%w]+$", ""):gsub("%.[^.]+$", "")
    return name
end

local known = { "%.zip$", "%.7z$", "%.tar$", "%.tar%.gz$", "%.tgz$",
                                "%.tar%.xz$", "%.txz$", "%.tar%.bz2$", "%.tbz2$" }

local function has_known_ext(name)
    for _, pat in ipairs(known) do
        if name:find(pat) then return true end
    end
    return false
end

return {
    entry = function()
        local paths, cwd, single_is_dir = get_state()
        if #paths == 0 then
            return ya.notify { title = "Compress", content = "Nothing selected", level = "warn", timeout = 3 }
        end

        local value, event = ya.input {
            title = "Archive name (.zip .7z .tar .tar.gz .tar.xz .tar.bz2):",
            pos = { "top-center", y = 3, w = 60 },
        }
        if event ~= 1 then return end

        -- items relative to cwd so the archive doesn't embed full paths
        local items = {}
        for _, p in ipairs(paths) do
            items[#items + 1] = p:sub(1, #cwd + 1) == cwd .. "/" and p:sub(#cwd + 2) or p
        end

        local name = value
        if not name or name == "" then
            if #paths == 1 then
                local base = basename(paths[1])
                name = single_is_dir and base or stem(base)
            else
                name = basename(cwd)
            end
        end
        if not has_known_ext(name) then name = name .. ".zip" end

        local out, err = compress(cwd, name, items)
        if not out or not out.status.success then
            local msg = err and tostring(err) or (out and out.stderr) or "unknown error"
            return ya.notify { title = "Compress failed", content = msg, level = "error", timeout = 6 }
        end
        ya.notify { title = "Compress", content = "Created " .. name, level = "info", timeout = 3 }
    end,
}
