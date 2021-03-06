local helper = {}

local dir_sep = package.config:sub(1, 1)

-- Return path to root directory when run from `path`.
local function antipath(path)
   local _, level = path:gsub(dir_sep, "")
   return (".."..dir_sep):rep(level)
end

function helper.luacov_config(prefix)
   return {
      statsfile = prefix.."luacov.stats.out",
      modules = {
         luacheck = "src/luacheck/init.lua",
         ["luacheck.*"] = "src"
      },
      exclude = {
         "bin/luacheck$"
      }
   }
end

local luacov = package.loaded.luacov or package.loaded["luacov.runner"]

-- Returns command that runs `luacheck` executable from `loc_path`.
function helper.luacheck_command(loc_path)
   loc_path = loc_path or "."
   local prefix = antipath(loc_path)
   local cmd = ("cd %s && lua"):format(loc_path)

   -- Extend package.path to allow loading this helper and luacheck modules.
   cmd = cmd..(" -e 'package.path=[[%s?.lua;%ssrc%s?.lua;%ssrc%s?%sinit.lua;]]..package.path'"):format(
      prefix, prefix, dir_sep, prefix, dir_sep, dir_sep)

   if luacov then
      -- Launch luacov.
      cmd = cmd..(" -e 'require[[luacov.runner]](require[[spec.helper]].luacov_config([[%s]]))'"):format(prefix)
   end

   return ("%s %sbin%sluacheck.lua"):format(cmd, prefix, dir_sep)
end

function helper.before_command()
   if luacov then
      luacov.pause()
   end
end

function helper.after_command()
   if luacov then
      luacov.resume()
   end
end

return helper
