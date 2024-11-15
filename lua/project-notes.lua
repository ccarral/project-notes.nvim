-- TODO: Autoclose buffer un bufleave

local data_path = vim.fn.stdpath('data')
local handle = vim.uv.new_fs_event()
local notes_buf = nil

local function get_git_head(head_file)
    local f_head = io.open(head_file)
    if f_head then
        local HEAD = f_head:read()
        f_head:close()
        local branch = HEAD:match('ref: refs/heads/(.+)$')
        if branch then
            return branch
        else
            return nil
        end
    end
    return nil
end


function Get_project_unique_fname()
    local normalized_cwd = vim.fn.getcwd():gsub('/', '__')
    local git_branch = get_git_head(".git/HEAD")
    if git_branch then
        return string.format("%s___%s", normalized_cwd, git_branch)
    else
        return string.format("%s", normalized_cwd, git_branch)
    end
end

function Get_notes_full_path()
    return string.format("%s/%s", data_path, Get_project_unique_fname())
end

local notes_path = Get_notes_full_path()

function update_notes_path()
    notes_path = Get_notes_full_path()
end

local function on_branch_change(err, fname, events)
    if err then
        print("Error occurred!")
    else
        vim.schedule(update_notes_path)
        vim.schedule(load_notes)
    end
    handle:stop()
    watch_branch()
end

function watch_branch()
    handle:start('.git/HEAD', {}, on_branch_change)
end

function load_notes()
    vim.api.nvim_buf_set_name(notes_buf, notes_path)
    vim.api.nvim_buf_call(notes_buf, vim.cmd.edit)
    vim.api.nvim_win_set_buf(0, notes_buf)
    vim.api.nvim_buf_set_option(notes_buf, 'filetype', 'markdown')
    vim.api.nvim_buf_set_option(notes_buf, 'autowriteall', true)
end

local function get_notes_buf()
    local buffers = vim.api.nvim_list_bufs()
    for key, buf in pairs(buffers) do
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if buf_name == notes_path then
            return buf
        end
    end
    return vim.api.nvim_create_buf(false, false)
end

local function notes_init()
    watch_branch()
    notes_buf = get_notes_buf()
    load_notes()
end

local function setup()
    vim.api.nvim_create_user_command('Notes', notes_init, {})
end

return { setup = setup }
