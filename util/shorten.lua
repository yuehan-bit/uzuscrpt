return function(number)
    if number == 0 then return "0" end

    local suffixes = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "SP", "O", "N", "D", "UD", "DD"}
    local is_negative = number < 0
    number = math.abs(number)

    local index = math.floor(math.log10(number))
    index = index - (index % 3)

    local suffix = suffixes[(index / 3) + 1] or ""
    local nearest_multiple = 10 ^ index
    local precision_multiple = 10 ^ 2

    local result = math.floor((number / nearest_multiple) * precision_multiple) / precision_multiple .. suffix
    return is_negative and "-" .. result or result
end
