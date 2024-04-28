module SortBot

import HTTP, JSON3, Dates

export URL, TOKEN, get_updates, send_message, runbot

const TOKEN = readchomp(match(r"token.txt", readdir()))
const URL = "https://api.telegram.org/bot$TOKEN"

const global offset = Ref{Int}()

"Get updates using long polling from the specified telegram API url.
Returns the list of updates, which are dictionaries. If no updates are found or
timeout occurs, the returned list is empty.

The parameter `all` set to **false** tells the API to flush the history;
Take care when using this parameter because there is no way to get the
most recent updates without flushing the old ones and they **cannot be recovered**."
function get_updates(url::String; timeout::Int, all::Bool)::Vector
    query_parameters = Dict("timeout" => timeout)

    if !all && isassigned(offset)
        query_parameters["offset"] = offset[]
    end

    response = HTTP.get("$url/getUpdates", query=query_parameters)
    updates = JSON3.read(response.body).result

    if !isempty(updates)
        max_update_id = maximum(u -> u.update_id, updates)
        offset[] = max_update_id + 1
    end

    updates
end

function send_message(url::String, msg, text::String) # reply::Bool=false)
    query_parameters = Dict("text" => text, "chat_id" => msg.chat.id)
    # if reply
    #     query_parameters["reply_parameters"] = Dict("message_id" => msg.message_id)
    # end
    HTTP.request(:POST, "$url/sendMessage", query=query_parameters)
end

function runbot(f::Function, url::String; timeout::Int=60, log::Bool=true)
    all_messaged = Set()
    served = @elapsed while true
        updates = get_updates(url, all=false, timeout=timeout)
        isempty(updates) && break

        tasks = map(updates) do u
            push!(all_messaged, u.message.chat.id)
            Threads.@spawn f(u.message)
        end
        wait.(tasks)
    end

    log || return nothing

    now = Dates.format(Dates.now(), "HH:MM")
    send_message.(
        url,
        "Timed out ($(timeout)s of waiting) at $now after $(round(served, digits=2))s of serving",
        all_messaged,
    )
end

end