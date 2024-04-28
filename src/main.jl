include("SortBot.jl")
using .SortBot


runbot(URL, timeout=200) do msg
    nums = split(get(msg, :text, ""), n -> !(isnumeric(n) || n ∈ ('-', '.'))) .|>
           (n -> tryparse(Float64, n)) |>
           filter(!isnothing) |>
           sort! |>
           (nums -> join(nums, ", "))

    if isempty(nums)
        send_message(URL, msg, "I haven't found any numbers in the message you sent me")
    else
        send_message(URL, msg, "I have found some numbers and sorted them")
        send_message(URL, msg, nums)
    end
end