/**
    TPKT is a packet specified in
    $(LINK https://tools.ietf.org/html/rfc1006, RFC 1006) for transporting
    Connection-Oriented Transport Protocol (COTP) packets over a Transmission
    Control Protocol (TCP) data stream. It is a very simple packet, which
    consists solely of a version number and a length.
    
    Connection-Oriented Transport Protocol (COTP) is specified in the
    $(LINK https://www.iso.org/home.html, International Organization for Standardization (ISO))'s
    specification, $(LINK https://www.iso.org/standard/24077.html, ISO 8073), and
    in the $(LINK International Telecommunications Union, https://www.itu.int/en/Pages/default.aspx)'s
    specification, $(LINK http://www.itu.int/rec/T-REC-X.224-199511-I/en, X.224).
    It is used, most notably, in Microsoft's Remote Desktop Protocol (RDP),
    and by extension, TPKT is used as well for Remote Desktop Protocol (RDP).

    Authors:
    $(UL
        $(LI $(PERSON Jonathan M. Wilbur, jonathan@wilbur.space, http://jonathan.wilbur.space))
    )
    Copyright: Copyright (C) Jonathan M. Wilbur
    License: $(LINK https://mit-license.org/, MIT License)
    Standards:
    $(UL
        $(LI $(LINK https://tools.ietf.org/html/rfc1006, RFC 1006))
    )
*/
module tpkt;
import packet;

// TODO: Exceptions
// TODO: Embedded Documentation
// TODO: Command-Line Tools

version (unittest)
{
    import std.exception : assertThrown, assertNotThrown;
}

debug
{
    import std.stdio : writeln;
}

/// All valid versions of TPKT, which, currently, is only version 3.
public
enum TPKTVersion : ubyte
{
    version3 = 0x03u
}

/**
    TPKT is a packet specified in
    $(LINK https://tools.ietf.org/html/rfc1006, RFC 1006) for transporting
    Connection-Oriented Transport Protocol (COTP) packets over a Transmission
    Control Protocol (TCP) data stream. It is a very simple packet, which
    consists solely of a version number and a length. This class represents
    a single TPKT packet.

    Note: There are no aliases of this, because "TPKT" is not an acronym.
*/
public
class TPKT : BinaryPacket
{
    /// The version of TPKT with which this packet is formed.
    public TPKTVersion vers = TPKTVersion.version3;

    private ubyte[] _header = [ 0x03u, 0x00u, 0x00u, 0x07u ];
    private ubyte[] _content = [ 0x00u, 0x00u, 0x00u ];

    /**
        Sets the header of the packet.

        Throws:
        $(UL
            $(LI $(D PacketException) if the supplied header is not exactly four bytes in length.)
            $(LI $(D PacketInvalidException) if the supplied header is not version 3.)
            $(LI $(D PacketTruncationException) if the length indicated in the header would yield content fewer than three bytes in length.)
        )
    */
    public @property @safe pure
    void header(in ubyte[] value)
    {
        if (value.length != 4u)
            throw new PacketException("TPKT", "This exception was thrown because you attempted to supply a TPKT header that was not exactly four bytes.");

        if (value[0] != cast(ubyte) TPKTVersion.version3)
        {
            import std.conv : text;
            throw new PacketInvalidException("TPKT", "TPKT Version 3 (0x03)", text(value[0]));
        }

        if (value[2] == 0x00u && value[3] < (this.minimumLength))
            throw new PacketTruncationException("TPKT", cast(size_t) value[3], this.minimumLength);

        return;
    }

    @safe
    unittest
    {
        TPKT tpkt = new TPKT();
        assertNotThrown!Exception(tpkt.header = [ 0x03u, 0x00u, 0x00u, 0x07u ]);
        assertNotThrown!Exception(tpkt.header = [ 0x03u, 0x00u, 0x00u, 0x07u ]); // Assert a second time to confirm that writes do not append.
        assertThrown!Exception(tpkt.header = [ 0x04u, 0x00u, 0x00u, 0x07u ]); // This should throw because the version field is invalid.
        assertThrown!Exception(tpkt.header = [ 0x03u, 0x00u ]); // This should throw because the header is too short.
        assertThrown!Exception(tpkt.header = [ 0x03u, 0x00u, 0x00u ]); // This should throw because the header is too short.
        assertThrown!Exception(tpkt.header = [ 0x03u, 0x00u, 0x00u, 0x07u, 0x00u ]); // This should throw because the header is too long.
    }

    /// Returns the header of the packet.
    public @property @safe pure
    ubyte[] header() const
    {
        immutable ushort shortLength = cast(immutable ushort) this.length;
        version (LittleEndian)
        {
            return [
                cast(ubyte) this.vers,
                cast(ubyte) 0x00u, 
                cast(ubyte) (shortLength & 0x00FFu),
                cast(ubyte) ((shortLength & 0xFF00u) >> 8u)
            ];
        }
        else
        {
            return [
                cast(ubyte) this.vers,
                cast(ubyte) 0x00u, 
                cast(ubyte) ((shortLength & 0xFF00u) >> 8u),
                cast(ubyte) (shortLength & 0x00FFu)
            ];
        }
    }

    @safe
    unittest
    {
        TPKT tpkt = new TPKT();
        assertNotThrown!Exception(tpkt.header);
    }

    /// Returns the length of the header.
    public @property @safe @nogc nothrow pure
    size_t headerLength() const
    {
        return this._header.length; // This should always be 4u
    }

    public @property @safe @nogc nothrow pure
    size_t minimumHeaderLength() const
    {
        return size_t.min;
    }

    public @property @safe @nogc nothrow pure
    size_t maximumHeaderLength() const
    {
        return size_t.max;
    }

    public @property @safe pure
    void content(in ubyte[] value)
    {
        if (value.length < this.minimumContentLength)
            throw new Exception("Content length too short!");

        if (value.length > this.maximumContentLength)
            throw new Exception("Content length too long!");

        this._content = value.dup;
    }

    public @property @safe nothrow pure
    ubyte[] content() const
    {
        return this._content.dup;
    }

    public @property @safe @nogc nothrow pure
    size_t contentLength() const
    {
        return this._content.length;
    }

    public @property @safe @nogc nothrow pure
    size_t minimumContentLength() const
    {
        return 3u;
    }

    public @property @safe @nogc nothrow pure
    size_t maximumContentLength() const
    {
        return 65531u;
    }

    public @property @safe @nogc nothrow pure
    void footer(in ubyte[] value)
    {
        return;
    }

    public @property @safe @nogc nothrow pure
    ubyte[] footer() const
    {
        return [];
    }

    public @property @safe @nogc nothrow pure
    size_t footerLength() const
    {
        return 0u;
    }

    public @property @safe @nogc nothrow pure
    size_t minimumFooterLength() const
    {
        return size_t.min;
    }

    public @property @safe @nogc nothrow pure
    size_t maximumFooterLength() const
    {
        return size_t.min;
    }

    public @property @safe @nogc pure
    size_t length() const
    out (value)
    {
        assert(value >= this.headerLength);
        assert(value >= this.contentLength);
        assert(value >= this.footerLength);
    }
    do
    {
        return (this.headerLength + this.contentLength + this.footerLength);
    }

    public @property @safe @nogc nothrow pure
    size_t minimumLength() const
    {
        return (this.minimumHeaderLength + this.minimumContentLength + this.minimumFooterLength); // Should be 7.
    }

    public @property @safe @nogc nothrow pure
    size_t maximumLength() const
    {
        return (this.maximumHeaderLength + this.maximumContentLength + this.maximumFooterLength); // Should be ushort.max
    }

    /**
        The mutator that accepts the raw bytes that represent the thing in
        question and updates the members of it accordingly.

        Returns: the number of bytes read.
    */
    public @property @safe pure
    size_t fromBytes(in ubyte[] value)
    {
        if (value.length < 4u)
            throw new Exception("A valid TPKT cannot be created from fewer than four bytes.");

        this.header = value[0 .. 4];

        version (LittleEndian)
            immutable ushort reportedLength = (((cast(ushort) value[2]) << 8u) + value[3]);
        else
            immutable ushort reportedLength = (((cast(ushort) value[3]) << 8u) + value[2]);
        
        if (reportedLength < this.minimumLength)
            throw new Exception("A valid TPKT cannot be created from fewer than four bytes.");
        
        if (reportedLength > value.length)
            throw new Exception("The reported length of a TPKT was shorter than the actual number of bytes.");

        this.content = value[4 .. reportedLength];
        return reportedLength;
    }

    ///
    @safe
    unittest
    {
        TPKT tpkt = new TPKT();
        assertNotThrown!Exception(tpkt.fromBytes = [ 0x03u, 0x00u, 0x00u, 0x07u, 0x00u, 0x00u, 0x00u ]);
        assert(tpkt.length == 7u);
        assertNotThrown!Exception(tpkt.fromBytes = [ 0x03u, 0x00u, 0x00u, 0x07u, 0x00u, 0x00u, 0x00u ]); // Assert a second time to confirm that writes do not append.
        assert(tpkt.length == 7u);

        assertThrown!Exception(tpkt.fromBytes = [ 0x04u, 0x00u, 0x00u, 0x00u ]); // This should throw because the version field is invalid.
        assertThrown!Exception(tpkt.fromBytes = [ 0x03u, 0x00u ]); // This should throw because the header is too short.
        assertThrown!Exception(tpkt.fromBytes = [ 0x03u, 0x00u, 0x00u ]); // This should throw because the header is too short.

        assertNotThrown!Exception(tpkt.fromBytes = [ 0x03u, 0x00u, 0x00u, 0x07u, 0x00u, 0x00u, 0x00u, 0x00u ]);
        assert(tpkt.headerLength == 4u);
        assert(tpkt.contentLength == 3u);
        assert(tpkt.footerLength == 0u);

        assertNotThrown!Exception(tpkt.fromBytes = [ 0x03u, 0x00u, 0x00u, 0x08u, 0x00u, 0x00u, 0x00u, 0x00u ]);
        assert(tpkt.headerLength == 4u);
        assert(tpkt.contentLength == 4u);
        assert(tpkt.footerLength == 0u);
    }

    /**
        The accessor that returns the raw byte representation of the thing in
        question.
    */
    public @property @safe pure
    ubyte[] toBytes() const
    {
        return (this.header ~ this.content ~ this.footer);
    }

    @safe
    invariant
    {
        assert(this._header.length == 4u);
        assert(this._content.length >= 3u);
        assert(this._content.length <= 65531u);
    }
}