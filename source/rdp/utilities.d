module utilities;
import std.traits : isIntegral;

/**

*/
pragma(inline, true);
public pure nothrow @system
ubyte[] convertToBigEndianBytes(T)(T value)
if (isIntegral!T)
{
    if (value <= byte.max && value >= byte.min)
    {
        return [ cast(ubyte) value ];
    }

    ubyte[] ret;
    ret.length = T.sizeof;
    *cast(T *) ret.ptr = value;
    
    version (LittleEndian)
    {
        import std.algorithm.mutation : reverse;
        reverse(ret);
    }
    
    return ret;
}

/**
    Because many of the 
*/
pragma(inline, true);
public pure nothrow @system
ubyte[] bigEndianFewestBytesEncode(T)(T value)
if (isIntegral!T)
{
    ubyte[] ret = convertToBigEndianBytes(value);
    size_t startOfNonPadding = 0u;
    if (value >= 0)
    {
        for (size_t i = 0u; i < (ret.length - 1); i++)
        {
            if (ret[i] != 0x00u) break;
            if (!(ret[(i + 1)] & 0b10000000u)) startOfNonPadding++;
        }
    }
    else
    {
        for (size_t i = 0u; i < (ret.length - 1); i++)
        {
            if (ret[i] != 0xFFu) break;
            if (ret[(i + 1)] & 0b10000000u) startOfNonPadding++;
        }
    }
    return ret[startOfNonPadding .. $];
}