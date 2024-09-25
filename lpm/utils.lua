local IgnoreMethods = {
    '__gc', '__eq', '__index', '__tostring', 'type', 'typeOf', 'getUserData', 'setUserData', 'destroy', 'update'
}

local function SetFunctions(main_object, sub_object)
    for key, value in pairs(sub_object.__index) do
        for _, method in ipairs(IgnoreMethods) do
            if key == method then
                goto continue
            end
        end

        main_object[key] = function(_, ...)
            return value(sub_object, ...)
        end

        ::continue::
    end
end

return SetFunctions