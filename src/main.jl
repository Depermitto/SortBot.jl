include("SortBot.jl")
using .SortBot


runbot(URL, timeout=100) do update
    nums = split(text(update), n -> !isnumeric(n) && n != '-') .|>
           (n -> tryparse(Int, n)) |>
           filter(!isnothing) |>
           sort! |>
           (nums -> join(nums, ", "))

    if isempty(nums)
        send_message(URL, "I haven't found any numbers in the message you sent me", chat_id(update))
    else
        send_message(URL, "I have found some numbers and sorted them", chat_id(update))
        send_message(URL, nums, chat_id(update))
    end
end