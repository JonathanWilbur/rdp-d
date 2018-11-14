module interfaces;
import std.traits : isIntegral, isSigned, isSomeString;

/// An interface of something that has at least one measureable spatial dimension
public
interface Tall
{
    /**
        The height of the implementor, given in units that are to be specified
        in the documentation for the implementor, or inferred to be the most
        reasonable units for measuring its height.
    */
    public @property size_t height() const;
}

/// An interface of something that has at least one measureable spatial dimension
public
interface Wide
{
    /**
        The width of the implementor, given in units that are to be specified
        in the documentation for the implementor, or inferred to be the most
        reasonable units for measuring its width.
    */
    public @property size_t width() const;
}

/// An interface of something that has at least one measureable spatial dimension
public
interface Long
{
    /**
        The length of the implementor, given in units that are to be specified
        in the documentation for the implementor, or inferred to be the most
        reasonable units for measuring its length.
    */
    public @property size_t length() const;
}

/// An interface of something that has at least two measureable spatial dimensions
public
interface TwoDimensional : Long, Wide
{
    /**
        The area of the implementor, given in units that are to be specified
        in the documentation for the implementor, or inferred to be the most
        reasonable units for measuring its area.
    */
    public @property size_t area() const;
}

/// An interface of something that has at least two measureable spatial dimensions
public
interface ThreeDimensional : TwoDimensional, Tall
{
    /**
        The surface area of the implementor, given in units that are to be
        specified in the documentation for the implementor, or inferred to be
        the most reasonable units for measuring its surface area.
    */
    public @property size_t surfaceArea() const;

    /**
        The volume of the implementor, given in units that are to be specified
        in the documentation for the implementor, or inferred to be the most
        reasonable units for measuring its volume.
    */
    public @property size_t volume() const;
}

public
interface InOneDimensionalSpace
{
    public @property void x(I)(I value) if (isIntegral!I && isSigned!I);
    public @property I x(I)() const if (isIntegral!I && isSigned!I);
}

// TODO: InTwoDimensionalSpace
// TODO: InThreeDimensionalSpace

/// An interface of something than can be converted to and from bytes.
public
interface Byteable
{
    /**
        The mutator that accepts the raw bytes that represent the thing in
        question and updates the members of it accordingly.

        Returns: the number of bytes read.
    */
    public @property size_t fromBytes(in ubyte[] value);

    /**
        The accessor that returns the raw byte representation of the thing in
        question.
    */
    public @property ubyte[] toBytes() const;
}

/// An interface of something than can be converted to and from a string.
public
interface Stringable : Writeable
{
    /**
        The mutator that accepts a string that represent the thing in
        question and updates the members of it accordingly.
    */
    public @property void fromString(S = string)(S value) if(isSomeString!S);
}

/**
    An interface of something that can be converted to a string, but not really
    the other way around. An example would be an X.509 certificate, which could
    be represented as a string, but there is no standardized string representation.

    If the thing in question _can_ be converted from an interface, use `Stringable`.
*/
public
interface Writeable
{
    /**
        The accessor that returns the string representation of the thing in
        question.
    */
    public @property ubyte[] toString() const;
}

/**
    An interface of something that can be valid or invalid or neither.

    Note that the value returned by a call to `valid()` should never
    be equal to the value returned by a call to `invalid()`. All implementors
    should also implement `invariant`s and/or contracts to ensure that the
    implementor is never both `valid` and `invalid` at the same time.
*/
public
interface Fallible
{
    /// Whether the implementor is valid.
    public @property bool valid() const;

    /// Whether the implementor is invalid.
    public @property bool invalid() const;
}

// TODO: LimitedLength
// TODO: LimitedHeight
// TODO: LimitedWidth
// TODO: LimitedArea
// TODO: LimitedSurfaceArea
// TODO: LimitedVolume
// TODO: Temporal
// TODO: TextPacket