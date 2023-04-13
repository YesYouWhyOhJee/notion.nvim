local storage = vim.fn.stdpath("data") .. "/notion/data.txt"
local Job = require('plenary.job')

local parser = require "notion.parse"

local M = {}

M.request = function(callback)
    local file = io.open(storage, "r")
    if file == nil then return end

    local l = file:read("*a")

    local data = {
        sort = {
            direction = "ascending",
            timestamp = "last_edited_time",
        },
    }

    local job = Job:new({
        command = 'curl',
        args = {
            '-X', 'POST',
            '-H', 'Authorization: Bearer ' .. l,
            '-H', 'Content-Type: application/json',
            '-H', 'Notion-Version: 2022-06-28',
            '--data', vim.fn.json_encode(data),
            'https://api.notion.com/v1/search',
        },
        enabled_recording = true,
        on_exit = function(b, code)
            if code == 0 then
                callback(b._stdout_results[1])
            else
                vim.print("[Notion] Error calling API")
            end
        end,
    })

    job:start()
end

M.resolveDatabase = function(id, callback)
    local file = io.open(storage, "r")
    if file == nil then return end
    local l = file:read("*a")

    local job = Job:new({
        command = 'curl',
        args = {
            '-H', 'Authorization: Bearer ' .. l,
            '-H', 'Notion-Version: 2022-06-28',
            'https://api.notion.com/v1/databases/' .. id
        },
        enabled_recording = true,
        on_exit = function(b, code)
            if code == 0 then
                callback(b._stdout_results[1])
            else
                vim.print("[Notion] Error calling API")
            end
        end,
    })

    job:start()
end

local addItemDefaults = {
    title = "No title",
    date = vim.fn.strftime("%Y-%m-%d"),
    topics = "",
    type = ""
}

M.addItem = function(opts)
    opts = vim.tbl_deep_extend("force", addItemDefaults, opts or {})
    return vim.print("WIP")
end

M.deleteItem = function(selection)
    local initData = require "notion".raw()
    local raw = parser.eventList(initData)

    if raw == nil then return end
    local id = raw.ids[selection[1]]

    local file = io.open(storage, "r")

    if file == nil then return end

    local l = file:read("*a")


    local job = Job:new({
        command = 'curl',
        args = {
            '-X', 'DELETE',
            '-H', 'Authorization: Bearer ' .. l,
            '-H', 'Notion-version: 2022-02-22',
            'https://api.notion.com/v1/blocks/' .. id
        },
        enabled_recording = true,
        on_exit = function(b, code)
            if code == 0 then
                vim.print("[Notion] Deleted")
            else
                print("[Notion] Error calling API")
            end
        end,
    })

    job:start()
end

return M
