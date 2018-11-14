/**
    A module containing generic exceptions, classes, and interfaces for packets.
*/
module packet;
import interfaces : Byteable, Long;

/// A generic exception for a packet.
public
class PacketException : Exception
{
    public string typeOfPacket;

    /**
        Params:
            typeOfPacket  = The name of the packet that threw this exception, such as "TCP" or "HTTP" or "LDAP".
            msg  = The message for the exception.
            line = The line number where the exception occurred.
            next = The previous exception in the chain of exceptions, if any.
    */
    public @safe @nogc pure nothrow
    this
    (
        string typeOfPacket,
        string msg,
        string file = __FILE__,
        size_t line = __LINE__,
        Throwable next = null
    )
    {
        this.typeOfPacket = typeOfPacket;
        super
        (
            msg,
            file,
            line,
            next
        );
    }
}

/// A generic exception for a packet that is either too small or too large.
public
class PacketSizeException : PacketException
{
    /**
        Params:
            typeOfPacket  = The name of the packet that threw this exception, such as "TCP" or "HTTP" or "LDAP".
            msg  = The message for the exception.
            line = The line number where the exception occurred.
            next = The previous exception in the chain of exceptions, if any.
    */
    public @safe pure nothrow
    this
    (
        string typeOfPacket,
        size_t actualLength,
        size_t minimumLength = size_t.min,
        size_t maximumLength = size_t.max,
        string file = __FILE__,
        size_t line = __LINE__,
        Throwable next = null
    )
    {
        import std.conv : text;
        super
        (
            typeOfPacket,
            (
                "This exception was thrown because you received a " ~
                typeOfPacket ~ " packet that was either too short or too long." ~
                "\nActual length: " ~ text(actualLength) ~
                "\nMinimum length: " ~ (minimumLength == size_t.min ? "INDETERMINATE" : text(minimumLength)) ~
                "\nMaximum length: " ~ (maximumLength == size_t.max ? "INDETERMINATE" : text(maximumLength)) ~
                "\n"
            ),
            file,
            line,
            next
        );
    }
}

/// An exception that is thrown when a packet is longer than is permitted.
public
class PacketTooLargeException : PacketSizeException
{
    /**
        Params:
            typeOfPacket  = The name of the packet that threw this exception, such as "TCP" or "HTTP" or "LDAP".
            actualLength = The length (in bytes) of the packet that threw this exception.
            expectedLength = The minimum length (in bytes) of the packet at which an exception would not have been thrown.
            line = The line number where the exception occurred.
            next = The previous exception in the chain of exceptions, if any.
    */
    public @safe pure nothrow
    this
    (
        string typeOfPacket,
        size_t actualLength,
        size_t maximumLength = size_t.max,
        string file = __FILE__,
        size_t line = __LINE__,
        Throwable next = null
    )
    {
        super
        (
            typeOfPacket,
            actualLength,
            size_t.min,
            maximumLength,
            file,
            line,
            next
        );
    }
}

/// An exception that is thrown when a packet is shorter than is permitted.
public
class PacketTruncationException : PacketSizeException
{
    /**
        Params:
            typeOfPacket  = The name of the packet that threw this exception, such as "TCP" or "HTTP" or "LDAP".
            actualLength = The length (in bytes) of the packet that threw this exception.
            expectedLength = The minimum length (in bytes) of the packet at which an exception would not have been thrown.
            line = The line number where the exception occurred.
            next = The previous exception in the chain of exceptions, if any.
    */
    public @safe pure nothrow
    this
    (
        string typeOfPacket,
        size_t actualLength,
        size_t minimumLength = size_t.min,
        string file = __FILE__,
        size_t line = __LINE__,
        Throwable next = null
    )
    {
        super
        (
            typeOfPacket,
            actualLength,
            minimumLength,
            size_t.max,
            file,
            line,
            next
        );
    }
}

/// An exception that is thrown when a field in a packet has taken on a value it is not permitted to
public
class PacketInvalidException : PacketException
{
    /**
        Params:
            typeOfPacket  = The name of the packet that threw this exception, such as "TCP" or "HTTP" or "LDAP".
            invalidValue = The string representation of the invalid value.
            permittedValues = The string representation of all possible value values. If left blank, it says "INDETERMINATE".
            line = The line number where the exception occurred.
            next = The previous exception in the chain of exceptions, if any.
    */
    public @safe pure nothrow
    this
    (
        string typeOfPacket,
        string invalidValue = "",
        string permittedValues = "",
        string file = __FILE__,
        size_t line = __LINE__,
        Throwable next = null
    )
    {
        super
        (
            typeOfPacket,
            (
                "This exception was thrown because you received a " ~
                typeOfPacket ~ " packet that contained an invalid value." ~
                "\nInvalid value: " ~ (invalidValue == "" ? "INDETERMINATE" : invalidValue) ~
                "\nPermitted values: " ~ (permittedValues == "" ? "INDETERMINATE" : permittedValues) ~
                "\n"
            ),
            file,
            line,
            next
        );
    }
}

/**
    An interface of a packet that can be read from or converted to a sequence
    of bytes.
*/
public
interface BinaryPacket : Byteable, Long
{
    /**
        Sets the header of the packet. The implementor should throw exceptions
        within this property so that an invalid header is never set.
    */
    public @property
    void header(in ubyte[] value)
    out
    {
        assert(this.headerLength >= this.minimumHeaderLength);
        assert(this.headerLength <= this.maximumHeaderLength);
    };

    /**
        Returns the header of the packet. Exceptions should have been thrown by
        the mutator such that an invalid header is never set, and therefore,
        never returned.
    */
    public @property @safe pure
    ubyte[] header() const
    out (value)
    {
        assert(value.length >= this.minimumHeaderLength);
        assert(value.length <= this.maximumHeaderLength);
    };

    /**
        Returns the length of the header. Exceptions should have been thrown by
        the mutator such that a header with an invalid length is never set.
    */
    public @property @safe @nogc pure
    size_t headerLength() const
    out (value)
    {
        assert(value >= this.minimumHeaderLength);
        assert(value <= this.maximumHeaderLength);
    };

    /// Returns the minimum permissible length of the packet header.
    public @property @safe @nogc pure
    size_t minimumHeaderLength() const
    out (value)
    {
        assert(value <= this.maximumHeaderLength);
    };

    /// Returns the maximum permissible length of the packet header.
    public @property @safe @nogc pure
    size_t maximumHeaderLength() const;
    //
    // NOTE:
    // The reason this contract is commented out is that, if it is executed, it
    // calls `this.minimumHeaderLength`, the `out` contract of which calls `this.maximumHeaderLength`
    // in an infinite loop, resulting in a stack overflow.
    //
    // out (value)
    // {
    //     assert(this.minimumHeaderLength <= value);
    // };

    /**
        Sets the content of the packet. The implementor should throw exceptions
        within this property so that invalid content is never set.
    */
    public @property
    void content(in ubyte[] value)
    out
    {
        assert(this.contentLength >= this.minimumContentLength);
        assert(this.contentLength <= this.maximumContentLength);
    };

    /**
        Returns the content of the packet. Exceptions should have been thrown by
        the mutator such that invalid content is never set, and therefore,
        never returned.
    */
    public @property @safe pure
    ubyte[] content() const
    out (value)
    {
        assert(value.length >= this.minimumContentLength);
        assert(value.length <= this.maximumContentLength);
    };

    /**
        Returns the length of the content. Exceptions should have been thrown by
        the mutator such that content with an invalid length is never set.
    */
    public @property @safe @nogc pure
    size_t contentLength() const
    out (value)
    {
        assert(value >= this.minimumContentLength);
        assert(value <= this.maximumContentLength);
    };

    /// Returns the minimum permissible length of the packet content.
    public @property @safe @nogc pure
    size_t minimumContentLength() const
    out (value)
    {
        assert(value <= this.maximumContentLength);
    };

    /// Returns the maximum permissible length of the packet content.
    public @property @safe @nogc pure
    size_t maximumContentLength() const;
    //
    // NOTE:
    // The reason this contract is commented out is that, if it is executed, it
    // calls `this.minimumContentLength`, the `out` contract of which calls `this.maximumContentLength`
    // in an infinite loop, resulting in a stack overflow.
    //
    // out (value)
    // {
    //     assert(this.minimumContentLength <= value);
    // };

    /**
        Sets the footer of the packet. The implementor should throw exceptions
        within this property so that an invalid footer is never set.
    */
    public @property
    void footer(in ubyte[] value)
    out
    {
        assert(this.footerLength >= this.minimumFooterLength);
        assert(this.footerLength <= this.maximumFooterLength);
    };

    /**
        Returns the footer of the packet. Exceptions should have been thrown by
        the mutator such that an invalid footer is never set, and therefore,
        never returned.
    */
    public @property @safe pure
    ubyte[] footer() const
    out (value)
    {
        assert(value.length >= this.minimumFooterLength);
        assert(value.length <= this.maximumFooterLength);
    };

    /**
        Returns the length of the footer. Exceptions should have been thrown by
        the mutator such that a footer with an invalid length is never set.
    */
    public @property @safe @nogc pure
    size_t footerLength() const
    out (value)
    {
        assert(value >= this.minimumFooterLength);
        assert(value <= this.maximumFooterLength);
    };

    /// Returns the minimum permissible length of the packet footer.
    public @property @safe @nogc pure
    size_t minimumFooterLength() const
    out (value)
    {
        assert(value <= this.maximumHeaderLength);
    };

    /// Returns the maximum permissible length of the packet footer.
    public @property @safe @nogc pure
    size_t maximumFooterLength() const;
    //
    // NOTE:
    // The reason this contract is commented out is that, if it is executed, it
    // calls `this.minimumFooterLength`, the `out` contract of which calls `this.maximumFooterLength`
    // in an infinite loop, resulting in a stack overflow.
    //
    // out (value)
    // {
    //     assert(this.minimumFooterLength <= value);
    // };

    // length() is provided by the `Long` interface

    /**
        The smallest length (in bytes) that the entire packet can possibly have
        while still being valid. The default implementation should be:

        ---
        public @property @safe @nogc nothrow pure
        size_t minimumLength() const
        {
            return (this.minimumHeaderLength + this.minimumContentLength + this.minimumFooterLength);
        }
        ---
    */
    public @property @safe @nogc pure
    size_t minimumLength() const
    out (value)
    {
        assert(value >= this.minimumHeaderLength);
        assert(value >= this.minimumContentLength);
        assert(value >= this.minimumFooterLength);
        assert(value <= this.maximumLength);
    }

    /**
        The largest length (in bytes) that the entire packet can possibly
        have while still being valid. The default implementation should be:

        ---
        public @property @safe @nogc nothrow pure
        size_t maximumLength() const
        {
            return (this.maximumHeaderLength + this.maximumContentLength + this.maximumFooterLength);
        }
        ---
    */
    public @property @safe @nogc pure
    size_t maximumLength() const
    out (value)
    {
        assert(value >= this.minimumHeaderLength);
        assert(value >= this.minimumContentLength);
        assert(value >= this.minimumFooterLength);
        // NOTE:
        // The reason this assertion is commented out is that, if it is
        // executed, it calls `this.minimumLength`, the `out` contract of which calls
        // `this.maximumLength` in an infinite loop, resulting in a stack
        // overflow.
        // 
        // assert(value >= this.minimumLength);
    }
}