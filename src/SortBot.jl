module SortBot

import HTTP, JSON, Dates

export URL, TOKEN, get_updates, send_message, runbot, text, chat_id

const TOKEN = "7130725976:AAHUFdgFFfXuwkertT9l7Yto4YG5ikp0WYg"
const URL = "https://api.telegram.org/bot$TOKEN"

const global offset = Ref{Int}()

"Get updates using long polling from the specified telegram API url.
Returns the list of updates, which are dictionaries. If no updates are found or
timeout occurs, the returned list is empty.

The parameter `all` set to **false** tells the API to flush the history;
Take care when using this parameter because there is no way to get the
most recent updates without flushing the old ones and they **cannot be recovered**."
function get_updates(url::String; timeout::Int, all::Bool)::Vector{Dict}

    query_parameters = Dict("timeout" => timeout)

    if !all && isassigned(offset)
        query_parameters["offset"] = offset[]
    end

    response = HTTP.get("$url/getUpdates", query=query_parameters)
    body = JSON.parse(String(response.body))
    updates = body["result"]

    if !isempty(updates)
        max_update_id = maximum(u -> u["update_id"], updates)
        offset[] = max_update_id + 1
    end

    updates
end

function send_message(url::String, message::String, chat_id::Integer)
    query_parameters = Dict("text" => message, "chat_id" => chat_id)
    HTTP.request(:POST, "$url/sendMessage", query=query_parameters)
end

chat_id(update::Dict)::Integer = update["message"]["chat"]["id"]
text(update::Dict)::String = get(update["message"], "text", "")

function runbot(f::Function, url::String; timeout::Int=60, log::Bool=true)
    last_messaged = []
    served = @elapsed while true
        updates = get_updates(url, all=false, timeout=timeout)
        isempty(updates) && break

        last_messaged = unique!(chat_id.(updates))
        f.(updates)
    end

    log || return nothing

    now = Dates.format(Dates.now(), "HH:MM")
    send_message.(
        url,
        "Timed out ($(timeout)s of waiting) at $now after $(round(served, digits=2))s of serving",
        last_messaged,
    )
end

end