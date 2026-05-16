local record inspect
    metamethod __call: function(_: self, root: any, options?: {string: any}): string
end

return inspect
