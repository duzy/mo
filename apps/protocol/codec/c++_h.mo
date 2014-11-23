def field_type($type, $size) {
    if $type eq 'number'
        if $size == 1
            "uint8_t";
        elsif $size == 2
            "uint16_t";
        elsif $size == 4
            "uint32_t";
        elsif $size == 8
            "uint64_t";
        else
            "bignum";
        end
    else
        $type;
    end
}

def field_name($name) {
    join('_',split(' ',$name))
}

template Cpp_h
--------------
class $(.name)
{
.for message ;
    /**
     * MESSAGE `$(.name)`
     */
.   for field ;
    $(field_type(.type, .size)) $(field_name(.name));
.   end
.end

public:
.for message ;
    /**
     * MESSAGE `$(.name)`
     */
.   for field ;
    $(field_type(.type, .size)) get_$(field_name(.name))() const;
.   end
    
.end
};
