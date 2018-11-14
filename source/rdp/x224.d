/**
    From X.224, 13.1: "When consecutive octets are used to represent a binary number, the lower octet number has the most significant value."
    So, in other words, integers are encoded big-endian.

    I interpret "The length indicated shall be the header length in octets including parameters, but excluding the
    length indicator field and user data, if any." to mean that LI does NOT include the length of the user data,
    but based on the fact that I see it counted from packet captures, it seems that maybe there was supposed to be
    an additional comma after "length indicator field," meaning that user data *would* be included.
*/
module x224;
import interfaces;
import utilities;
import std.algorithm.mutation : reverse;
import std.outbuffer : OutBuffer;
import std.traits : ForeachType, isIntegral, isStaticArray, Unqual;
import std.typecons : Nullable;

///
public alias X224TPDUCode = X224TransportProtocolDataUnitCode;
///
public
enum X224TransportProtocolDataUnitCode : ubyte
{
    connectionRequest   = 0b1110_0000u,
    connectionConfirm   = 0b1101_0000u,
    data                = 0b1111_0000u,
    reject              = 0b0101_0000u,
    dataAcknowledgement = 0b0110_0000u
}

///
public
enum X224ProtocolClass : ubyte
{
    class0 = 0x00u,
    class1 = 0x01u,
    class2 = 0x02u,
    class3 = 0x03u,
    class4 = 0x04u
}

///
public
struct X224TargetsAndMaximums(T)
if (isIntegral!(Unqual!T) || (isStaticArray!T && isIntegral!(Unqual!(ForeachType!T))))
{
    public T targetValueCallingCalledUserDirection;
    public T minimumAcceptableValueCallingCalledUserDirection;
    public T targetValueCalledCallingUserDirection;
    public T minimumAcceptableValueCalledCallingUserDirection;

    public @property
    ubyte[] toBytes()
    {
        static if (isStaticArray!T)
        {
            version (BigEndian)
            {
                return
                    this.targetValueCallingCalledUserDirection ~
                    this.minimumAcceptableValueCallingCalledUserDirection ~
                    this.targetValueCalledCallingUserDirection ~
                    this.minimumAcceptableValueCalledCallingUserDirection;
            }
            else
            {
                return
                    reverse(cast(ForeachType!T[]) this.targetValueCallingCalledUserDirection) ~
                    reverse(cast(ForeachType!T[]) this.minimumAcceptableValueCallingCalledUserDirection) ~
                    reverse(cast(ForeachType!T[]) this.targetValueCalledCallingUserDirection) ~
                    reverse(cast(ForeachType!T[]) this.minimumAcceptableValueCalledCallingUserDirection);
            }
        }
        else
        {
            return
                convertToBigEndianBytes(this.targetValueCallingCalledUserDirection) ~
                convertToBigEndianBytes(this.minimumAcceptableValueCallingCalledUserDirection) ~
                convertToBigEndianBytes(this.targetValueCalledCallingUserDirection) ~
                convertToBigEndianBytes(this.minimumAcceptableValueCalledCallingUserDirection);
        }
    }
}

///
public alias X224TPDU = X224TransportProtocolDataUnit;
///
public abstract
class X224TransportProtocolDataUnit
{
    public immutable size_t fixedPartLength;

    public @property @safe @nogc final nothrow pure
    size_t maximumPermissibleVariableParameterValueLength()
    {
        // ubyte.max - 1 (for LI) - 2 (for variable parameter header) - fixedPart
        return (252u - this.fixedPartLength);
    }

    public ubyte lengthIndicator;
    public immutable X224TPDUCode code; // Made immutable because this will vary per class
    public ubyte[] userData;
}

///
public alias X224CRTPDU = X224ConnectionRequestTransportProtocolDataUnit;
///
public alias X224CRTransportProtocolDataUnit = X224ConnectionRequestTransportProtocolDataUnit;
///
public alias X224ConnectionRequestTPDU = X224ConnectionRequestTransportProtocolDataUnit;
/**
    See page 66 of the PDF of ITU X.224.
*/
public
class X224ConnectionRequestTransportProtocolDataUnit : X224TPDU
{
    public immutable size_t fixedPartLength = 6u;

    private
    enum X224ParameterCode : ubyte
    {
        callingTransportSelector = 0b1100_0000u,
        calledTransportSelector = 0b1100_0010u,
        transportProtocolDataUnitSize = 0b1100_0000u,
        preferredMaximumTransportProtocolDataUnitSize = 0b1111_0000u,
        versionNumber = 0b1100_0100u,
        protectionParameters = 0b1100_0101u,
        checksum = 0b1100_0011u,
        additionalOptionSelection = 0b1100_0110u,
        alternativeProtocolClasses = 0b1100_0111u,
        acknowledgementTime = 0b1000_0101u,
        throughput = 0b1000_1001u,
        residualErrorRate = 0b1000_0110u,
        priority = 0b1000_0111u,
        transitDelay = 0b1000_1000u,
        reassignmentTime = 0b1000_1011u,
        inactivityTimer = 0b1111_0010u
    }

    ///
    public alias X224CRTPDUSizeCode = X224ConnectionRequestTransportProtocolDataUnitSizeCode;
    ///
    public alias X224ConnectionRequestTPDUSizeCode = X224ConnectionRequestTransportProtocolDataUnitSizeCode;
    ///
    public alias X224CRTransportProtocolDataUnitSizeCode = X224ConnectionRequestTransportProtocolDataUnitSizeCode;
    ///
    public
    enum X224ConnectionRequestTransportProtocolDataUnitSizeCode : ubyte
    {
        octets128 = 0b0000_0111u,
        octets256 = 0b0000_1000u,
        octets512 = 0b0000_1001u,
        octets1024 = 0b0000_1010u,
        octets2048 = 0b0000_1011u,
        octets4096 = 0b0000_1100u, // Not allowed in class 0
        octets8192 = 0b0000_1101u // Not allowed in class 0
    }

    // Fixed Part

    public immutable X224TPDUCode code = X224TPDUCode.connectionRequest;
    public ubyte initialCreditAllocation = 0x00u;
    public immutable ushort destinationReference = 0x0000u;
    public ushort sourceReference = 0x0000u;
    public X224ProtocolClass protocolClass;
    public bool useExtendedFormatsInClasses_2_3_and_4 = false;
    public bool useExplicitFlowControlInClass2 = true;

    // Variable Part

    public Nullable!(ubyte[]) callingTransportSelector;
    public Nullable!(ubyte[]) calledTransportSelector;
    public Nullable!(X224CRTPDUSizeCode) transportProtocolDataUnitSize;
    public Nullable!(uint) preferredMaximumTransportProtocolDataUnitSize;
    public Nullable!(ubyte) versionNumber; // Not used if class 0 is preferred
    public Nullable!(ubyte[]) protectionParameters;
    public Nullable!(ushort) checksum;
    public Nullable!(ubyte) additionalOptionSelection; // TODO: Break this out into separate booleans
    public Nullable!(ubyte[]) alternativeProtocolClasses;
    public Nullable!(ushort) acknowledgementTimeInMilliseconds;
    public Nullable!(X224TargetsAndMaximums!(ubyte[3])) maximumThroughput;
    public Nullable!(X224TargetsAndMaximums!(ubyte[3])) averageThroughput;
    public Nullable!(ubyte) residualErrorRateTargetValuePowerOf10;
    public Nullable!(ubyte) residualErrorRateMinimumAcceptablePowerOf10;
    public Nullable!(ubyte) residualErrorRateTSDUSizeOfInterestPowerOf2; // What is TSDU?
    public Nullable!(ushort) priority;
    public Nullable!(X224TargetsAndMaximums!(ushort)) transitDelay;
    public Nullable!(ushort) timeToTryReassignmentInSeconds;
    public Nullable!(uint) inactivityTimeInMilliseconds;

    ///
    public @property @system
    ubyte[] bytes()
    out (value)
    {
        assert(value.length >= 7u);
    }
    do
    {
        if (this.userData.length > 32u)
            throw new Exception("User data cannot exceed 32 bytes in an X.224 Connection Request TPDU.");

        OutBuffer buffer = new OutBuffer();

        // Fixed Part
        ubyte[] fixedPart = [ 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u ];
        fixedPart[1] = cast(ubyte) X224TransportProtocolDataUnitCode.connectionRequest;
        fixedPart[1] |= (0x0Fu & this.initialCreditAllocation); // FIXME
        // DST-REF is always 0x0000
        fixedPart[4] = cast(ubyte) ((this.sourceReference & 0xFF00u) >> 8);
        fixedPart[5] = cast(ubyte) (this.sourceReference & 0x00FFu);
        fixedPart[6] = cast(ubyte) this.protocolClass;
        fixedPart[6] |= (this.useExtendedFormatsInClasses_2_3_and_4 ? 0b0000_0010u : 0b0000_0000u);
        fixedPart[6] |= (this.useExplicitFlowControlInClass2 ? 0b0000_0000u : 0b0000_0001u);
        buffer.put(fixedPart);

        // Variable Part
        if (!this.callingTransportSelector.isNull)
        {
            if (this.callingTransportSelector.get().length > this.maximumPermissibleVariableParameterValueLength)
                throw new Exception("Variable Parameter was too long!");

            buffer.put(cast(ubyte) X224ParameterCode.callingTransportSelector);
            buffer.put(bigEndianFewestBytesEncode(this.callingTransportSelector.get().length));
            buffer.put(this.callingTransportSelector.get());
        }

        if (!this.calledTransportSelector.isNull)
        {
            if (this.calledTransportSelector.get().length > this.maximumPermissibleVariableParameterValueLength)
                throw new Exception("Variable Parameter was too long!");

            buffer.put(cast(ubyte) X224ParameterCode.calledTransportSelector);
            buffer.put(bigEndianFewestBytesEncode(this.calledTransportSelector.get().length));
            buffer.put(this.calledTransportSelector.get());
        }

        if (!this.transportProtocolDataUnitSize.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.transportProtocolDataUnitSize);
            buffer.put(cast(ubyte) 0x01u);
            buffer.put(cast(ubyte) this.transportProtocolDataUnitSize.get());

            if (buffer.toBytes.length > ubyte.max)
                throw new Exception("Packet too big to encode its own length!");
        }

        if (!this.versionNumber.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.versionNumber);
            buffer.put(cast(ubyte) 0x01u);
            buffer.put(this.versionNumber.get());

            if (buffer.toBytes.length > ubyte.max)
                throw new Exception("Packet too big to encode its own length!");
        }

        if (!this.protectionParameters.isNull)
        {
            if (this.protectionParameters.get().length > this.maximumPermissibleVariableParameterValueLength)
                throw new Exception("Variable Parameter was too long!");

            buffer.put(cast(ubyte) X224ParameterCode.protectionParameters);
            buffer.put(cast(ubyte) this.protectionParameters.get().length);
            buffer.put(this.protectionParameters.get());
        }

        if (!this.checksum.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.checksum);
            buffer.put(cast(ubyte) 0x02u);
            buffer.put(convertToBigEndianBytes(this.checksum.get()));
        }

        if (!this.additionalOptionSelection.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.additionalOptionSelection);
            buffer.put(cast(ubyte) 0x01u);
            buffer.put(this.additionalOptionSelection.get());
        }

        if (!this.alternativeProtocolClasses.isNull)
        {
            if (this.alternativeProtocolClasses.get().length > this.maximumPermissibleVariableParameterValueLength)
                throw new Exception("Variable Parameter was too long!");

            buffer.put(cast(ubyte) X224ParameterCode.alternativeProtocolClasses);
            buffer.put(cast(ubyte) this.alternativeProtocolClasses.get().length);
            buffer.put(this.alternativeProtocolClasses.get());
        }

        if (!this.acknowledgementTimeInMilliseconds.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.acknowledgementTime);
            buffer.put(cast(ubyte) 0x02u);
            buffer.put(convertToBigEndianBytes(this.acknowledgementTimeInMilliseconds.get()));
        }

        if (!this.maximumThroughput.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.throughput);
            buffer.put(cast(ubyte) (this.averageThroughput.isNull ? 12u : 24u));
            buffer.put(this.maximumThroughput.get().toBytes);
            if (!this.averageThroughput.isNull) buffer.put(this.averageThroughput.get().toBytes);
        }

        if
        (
            !this.residualErrorRateTargetValuePowerOf10.isNull &&
            !this.residualErrorRateMinimumAcceptablePowerOf10 &&
            !this.residualErrorRateTSDUSizeOfInterestPowerOf2
        )
        {
            buffer.put(cast(ubyte) X224ParameterCode.residualErrorRate);
            buffer.put(cast(ubyte) 0x03u);
            buffer.put(this.residualErrorRateTargetValuePowerOf10.get());
            buffer.put(this.residualErrorRateMinimumAcceptablePowerOf10.get());
            buffer.put(this.residualErrorRateTSDUSizeOfInterestPowerOf2.get());
        }

        if (!this.priority.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.priority);
            buffer.put(cast(ubyte) 0x02u);
            buffer.put(bigEndianFewestBytesEncode(this.priority.get()));
        }

        if (!this.transitDelay.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.transitDelay);
            buffer.put(cast(ubyte) 0x08u);
            buffer.put(this.transitDelay.get().toBytes);
        }

        if (!this.timeToTryReassignmentInSeconds.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.reassignmentTime);
            buffer.put(cast(ubyte) 0x02u);
            buffer.put(bigEndianFewestBytesEncode(this.timeToTryReassignmentInSeconds.get()));
        }

        if (!this.inactivityTimeInMilliseconds.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.inactivityTimer);
            buffer.put(cast(ubyte) 0x04u);
            buffer.put(bigEndianFewestBytesEncode(this.inactivityTimeInMilliseconds.get()));
        }

        // User Data
        buffer.put(this.userData);
        
        ubyte[] ret = buffer.toBytes;
        if (ret.length > ubyte.max)
            throw new Exception("X.224 Connection Request TPDU is too big for its own length encoding! Cannot exceed 255 bytes!");
        ret[0] = cast(ubyte) (ret.length - 1);
        return ret;
    }
}

///
public alias X224CCTPDU = X224ConnectionConfirmTransportProtocolDataUnit;
///
public alias X224CCTransportProtocolDataUnit = X224ConnectionConfirmTransportProtocolDataUnit;
///
public alias X224ConnectionConfirmTPDU = X224ConnectionConfirmTransportProtocolDataUnit;
/**
    See page 70 of the PDF of ITU X.224.
*/
public
class X224ConnectionConfirmTransportProtocolDataUnit : X224TPDU
{
    public immutable size_t fixedPartLength = 6u;

    private
    enum X224ParameterCode : ubyte
    {
        callingTransportSelector = 0b1100_0000u,
        calledTransportSelector = 0b1100_0010u,
        transportProtocolDataUnitSize = 0b1100_0000u,
        preferredMaximumTransportProtocolDataUnitSize = 0b1111_0000u,
        versionNumber = 0b1100_0100u,
        protectionParameters = 0b1100_0101u,
        checksum = 0b1100_0011u,
        additionalOptionSelection = 0b1100_0110u,
        alternativeProtocolClasses = 0b1100_0111u,
        acknowledgementTime = 0b1000_0101u,
        throughput = 0b1000_1001u,
        residualErrorRate = 0b1000_0110u,
        priority = 0b1000_0111u,
        transitDelay = 0b1000_1000u,
        reassignmentTime = 0b1000_1011u,
        inactivityTimer = 0b1111_0010u
    }

    ///
    public alias X224CCTPDUSizeCode = X224ConnectionConfirmTransportProtocolDataUnitSizeCode;
    ///
    public alias X224ConnectionConfirmTPDUSizeCode = X224ConnectionConfirmTransportProtocolDataUnitSizeCode;
    ///
    public alias X224CCTransportProtocolDataUnitSizeCode = X224ConnectionConfirmTransportProtocolDataUnitSizeCode;
    ///
    public
    enum X224ConnectionConfirmTransportProtocolDataUnitSizeCode : ubyte
    {
        octets128 = 0b0000_0111u,
        octets256 = 0b0000_1000u,
        octets512 = 0b0000_1001u,
        octets1024 = 0b0000_1010u,
        octets2048 = 0b0000_1011u,
        octets4096 = 0b0000_1100u, // Not allowed in class 0
        octets8192 = 0b0000_1101u // Not allowed in class 0
    }

    // Fixed Part

    public immutable X224TPDUCode code = X224TPDUCode.connectionConfirm;
    public ubyte initialCreditAllocation = 0x00u;
    public immutable ushort destinationReference = 0x0000u;
    public ushort sourceReference = 0x0000u;
    public X224ProtocolClass protocolClass;
    public bool useExtendedFormatsInClasses_2_3_and_4 = false;
    public bool useExplicitFlowControlInClass2 = true;

    // Variable Part

    public Nullable!(ubyte[]) callingTransportSelector;
    public Nullable!(ubyte[]) calledTransportSelector;
    public Nullable!(X224CCTPDUSizeCode) transportProtocolDataUnitSize;
    public Nullable!(uint) preferredMaximumTransportProtocolDataUnitSize;
    public Nullable!(ubyte) versionNumber; // Not used if class 0 is preferred
    public Nullable!(ubyte[]) protectionParameters;
    public Nullable!(ushort) checksum;
    public Nullable!(ubyte) additionalOptionSelection; // TODO: Break this out into separate booleans
    public Nullable!(ubyte[]) alternativeProtocolClasses;
    public Nullable!(ushort) acknowledgementTimeInMilliseconds;
    public Nullable!(X224TargetsAndMaximums!(ubyte[3])) maximumThroughput;
    public Nullable!(X224TargetsAndMaximums!(ubyte[3])) averageThroughput;
    public Nullable!(ubyte) residualErrorRateTargetValuePowerOf10;
    public Nullable!(ubyte) residualErrorRateMinimumAcceptablePowerOf10;
    public Nullable!(ubyte) residualErrorRateTSDUSizeOfInterestPowerOf2; // What is TSDU?
    public Nullable!(ushort) priority;
    public Nullable!(X224TargetsAndMaximums!(ushort)) transitDelay;
    public Nullable!(ushort) timeToTryReassignmentInSeconds;
    public Nullable!(uint) inactivityTimeInMilliseconds;

    ///
    public @property @system
    ubyte[] bytes()
    out (value)
    {
        assert(value.length >= 7u);
    }
    do
    {
        if (this.userData.length > 32u)
            throw new Exception("User data cannot exceed 32 bytes in an X.224 Connection Confirm TPDU.");

        OutBuffer buffer = new OutBuffer();

        // Fixed Part
        ubyte[] fixedPart = [ 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u ];
        fixedPart[1] = cast(ubyte) X224TransportProtocolDataUnitCode.connectionRequest;
        fixedPart[1] |= (0x0Fu & this.initialCreditAllocation); // FIXME
        // DST-REF is always 0x0000
        fixedPart[4] = cast(ubyte) ((this.sourceReference & 0xFF00u) >> 8);
        fixedPart[5] = cast(ubyte) (this.sourceReference & 0x00FFu);
        fixedPart[6] = cast(ubyte) this.protocolClass;
        fixedPart[6] |= (this.useExtendedFormatsInClasses_2_3_and_4 ? 0b0000_0010u : 0b0000_0000u);
        fixedPart[6] |= (this.useExplicitFlowControlInClass2 ? 0b0000_0000u : 0b0000_0001u);
        buffer.put(fixedPart);

        // Variable Part
        if (!this.callingTransportSelector.isNull)
        {
            if (this.callingTransportSelector.get().length > this.maximumPermissibleVariableParameterValueLength)
                throw new Exception("Variable Parameter was too long!");

            buffer.put(cast(ubyte) X224ParameterCode.callingTransportSelector);
            buffer.put(bigEndianFewestBytesEncode(this.callingTransportSelector.get().length));
            buffer.put(this.callingTransportSelector.get());
        }

        if (!this.calledTransportSelector.isNull)
        {
            if (this.calledTransportSelector.get().length > this.maximumPermissibleVariableParameterValueLength)
                throw new Exception("Variable Parameter was too long!");

            buffer.put(cast(ubyte) X224ParameterCode.calledTransportSelector);
            buffer.put(bigEndianFewestBytesEncode(this.calledTransportSelector.get().length));
            buffer.put(this.calledTransportSelector.get());
        }

        if (!this.transportProtocolDataUnitSize.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.transportProtocolDataUnitSize);
            buffer.put(cast(ubyte) 0x01u);
            buffer.put(cast(ubyte) this.transportProtocolDataUnitSize.get());

            if (buffer.toBytes.length > ubyte.max)
                throw new Exception("Packet too big to encode its own length!");
        }

        if (!this.versionNumber.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.versionNumber);
            buffer.put(cast(ubyte) 0x01u);
            buffer.put(this.versionNumber.get());

            if (buffer.toBytes.length > ubyte.max)
                throw new Exception("Packet too big to encode its own length!");
        }

        if (!this.protectionParameters.isNull)
        {
            if (this.protectionParameters.get().length > this.maximumPermissibleVariableParameterValueLength)
                throw new Exception("Variable Parameter was too long!");

            buffer.put(cast(ubyte) X224ParameterCode.protectionParameters);
            buffer.put(cast(ubyte) this.protectionParameters.get().length);
            buffer.put(this.protectionParameters.get());
        }

        if (!this.checksum.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.checksum);
            buffer.put(cast(ubyte) 0x02u);
            buffer.put(convertToBigEndianBytes(this.checksum.get()));
        }

        if (!this.additionalOptionSelection.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.additionalOptionSelection);
            buffer.put(cast(ubyte) 0x01u);
            buffer.put(this.additionalOptionSelection.get());
        }

        if (!this.alternativeProtocolClasses.isNull)
        {
            if (this.alternativeProtocolClasses.get().length > this.maximumPermissibleVariableParameterValueLength)
                throw new Exception("Variable Parameter was too long!");

            buffer.put(cast(ubyte) X224ParameterCode.alternativeProtocolClasses);
            buffer.put(cast(ubyte) this.alternativeProtocolClasses.get().length);
            buffer.put(this.alternativeProtocolClasses.get());
        }

        if (!this.acknowledgementTimeInMilliseconds.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.acknowledgementTime);
            buffer.put(cast(ubyte) 0x02u);
            buffer.put(convertToBigEndianBytes(this.acknowledgementTimeInMilliseconds.get()));
        }

        if (!this.maximumThroughput.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.throughput);
            buffer.put(cast(ubyte) (this.averageThroughput.isNull ? 12u : 24u));
            buffer.put(this.maximumThroughput.get().toBytes);
            if (!this.averageThroughput.isNull) buffer.put(this.averageThroughput.get().toBytes);
        }

        if
        (
            !this.residualErrorRateTargetValuePowerOf10.isNull &&
            !this.residualErrorRateMinimumAcceptablePowerOf10 &&
            !this.residualErrorRateTSDUSizeOfInterestPowerOf2
        )
        {
            buffer.put(cast(ubyte) X224ParameterCode.residualErrorRate);
            buffer.put(cast(ubyte) 0x03u);
            buffer.put(this.residualErrorRateTargetValuePowerOf10.get());
            buffer.put(this.residualErrorRateMinimumAcceptablePowerOf10.get());
            buffer.put(this.residualErrorRateTSDUSizeOfInterestPowerOf2.get());
        }

        if (!this.priority.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.priority);
            buffer.put(cast(ubyte) 0x02u);
            buffer.put(bigEndianFewestBytesEncode(this.priority.get()));
        }

        if (!this.transitDelay.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.transitDelay);
            buffer.put(cast(ubyte) 0x08u);
            buffer.put(this.transitDelay.get().toBytes);
        }

        if (!this.timeToTryReassignmentInSeconds.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.reassignmentTime);
            buffer.put(cast(ubyte) 0x02u);
            buffer.put(bigEndianFewestBytesEncode(this.timeToTryReassignmentInSeconds.get()));
        }

        if (!this.inactivityTimeInMilliseconds.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.inactivityTimer);
            buffer.put(cast(ubyte) 0x04u);
            buffer.put(bigEndianFewestBytesEncode(this.inactivityTimeInMilliseconds.get()));
        }

        // User Data

        buffer.put(this.userData); // "shall not exceed 32 octets"
        
        ubyte[] ret = buffer.toBytes;
        if (ret.length > ubyte.max)
            throw new Exception("X.224 Connection Confirm TPDU is too big for its own length encoding! Cannot exceed 255 bytes!");
        ret[0] = cast(ubyte) (ret.length - 1);
        return ret;
    }
}

///
public alias X224DRTPDU = X224DisconnectRequestTransportProtocolDataUnit;
///
public alias X224DRTransportProtocolDataUnit = X224DisconnectRequestTransportProtocolDataUnit;
///
public alias X224DisconnectRequestTPDU = X224DisconnectRequestTransportProtocolDataUnit;
/**
    See page 70 of the PDF of ITU X.224.
*/
public
class X224DisconnectRequestTransportProtocolDataUnit : X224TPDU
{
    public immutable size_t fixedPartLength = 6u;

    private
    enum X224ParameterCode : ubyte
    {
        additionalInformation = 0b1110_0000u,
        checksum = 0b1100_0011u
    }

    public
    enum X224DisconnectRequestReason : ubyte
    {
        // These values can be used for all classes
        reasonNotSpecified = 0x00u,
        congestionAtTSAP = 0x01u,
        sessionEntityNotAttachedToTSAP = 0x02u,
        addressUnknown = 0x03u,

        // These values can only be used for classes 1 to 4
        normalDisconnect = 0x80u,
        remoteTransportEntityCongestionAtConnectRequestTime = 0x81u,
        connectionNegotiationFailed = 0x82u,
        duplicateSourceReferenceDetectedForTheSamePairOfNSAPs = 0x83u,
        mismatchedReferences = 0x84u,
        protocolError = 0x85u,
        // 0x86u is not used
        referenceOverflow = 0x87u,
        connectionRequestRefusedOnThisNetworkConnection = 0x88u,
        // 0x89 is not used
        headerOrParameterLengthInvalid = 0x8Au
    }

    // Fixed Part

    public immutable X224TPDUCode code = X224TPDUCode.disconnectRequest;
    public immutable ushort destinationReference = 0x0000u;
    public ushort sourceReference = 0x0000u;
    public X224DisconnectRequestReason reason;

    // Variable Part

    public Nullable!(ubyte[]) additionalInformation;
    public Nullable!(ushort) checksum;

    ///
    public @property @system
    ubyte[] bytes()
    out (value)
    {
        assert(value.length >= 7u);
    }
    do
    {
        if (this.userData.length > 64u)
            throw new Exception("User data cannot exceed 64 bytes in an X.224 Disconnect Request TPDU.");

        OutBuffer buffer = new OutBuffer();

        // Fixed Part
        ubyte[] fixedPart = [ 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u ];
        fixedPart[1] = cast(ubyte) X224TransportProtocolDataUnitCode.disconnectRequest;
        // DST-REF is always 0x0000
        fixedPart[4] = cast(ubyte) ((this.sourceReference & 0xFF00u) >> 8);
        fixedPart[5] = cast(ubyte) (this.sourceReference & 0x00FFu);
        fixedPart[6] = cast(ubyte) this.reason;
        buffer.put(fixedPart);

        // Variable Part
        if (!this.additionalInformation.isNull)
        {
            if (this.callingTransportSelector.get().length > this.maximumPermissibleVariableParameterValueLength)
                throw new Exception("Variable Parameter was too long!");

            buffer.put(cast(ubyte) X224ParameterCode.additionalInformation);
            buffer.put(bigEndianFewestBytesEncode(this.additionalInformation.get().length));
            buffer.put(this.additionalInformation.get());
        }

        if (!this.checksum.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.checksum);
            buffer.put(cast(ubyte) 0x02u);
            buffer.put(convertToBigEndianBytes(this.checksum.get()));
        }

        // User Data
        buffer.put(this.userData);
        
        ubyte[] ret = buffer.toBytes;
        if (ret.length > ubyte.max)
            throw new Exception("X.224 Disconnect Request TPDU is too big for its own length encoding! Cannot exceed 255 bytes!");
        ret[0] = cast(ubyte) (ret.length - 1);
        return ret;
    }
}

///
public alias X224DCTPDU = X224DisconnectConfirmTransportProtocolDataUnit;
///
public alias X224DCTransportProtocolDataUnit = X224DisconnectConfirmTransportProtocolDataUnit;
///
public alias X224DisconnectConfirmTPDU = X224DisconnectConfirmTransportProtocolDataUnit;
/**
    See page 70 of the PDF of ITU X.224.
*/
public
class X224DisconnectConfirmTransportProtocolDataUnit : X224TPDU
{
    public immutable size_t fixedPartLength = 5u;

    private
    enum X224ParameterCode : ubyte
    {
        checksum = 0b1100_0011u
    }

    // Fixed Part

    public immutable X224TPDUCode code = X224TPDUCode.disconnectRequest;
    public immutable ushort destinationReference = 0x0000u;
    public ushort sourceReference = 0x0000u;

    // Variable Part

    public Nullable!(ushort) checksum;

    ///
    public @property @system
    ubyte[] bytes()
    out (value)
    {
        assert(value.length >= 7u);
    }
    do
    {
        if (this.userData.length > 64u)
            throw new Exception("User data cannot exceed 64 bytes in an X.224 Disconnect Confirm TPDU.");

        OutBuffer buffer = new OutBuffer();

        // Fixed Part
        ubyte[] fixedPart = [ 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u ];
        fixedPart[1] = cast(ubyte) X224TransportProtocolDataUnitCode.disconnectConfirm;
        // DST-REF is always 0x0000
        fixedPart[4] = cast(ubyte) ((this.sourceReference & 0xFF00u) >> 8);
        fixedPart[5] = cast(ubyte) (this.sourceReference & 0x00FFu);
        buffer.put(fixedPart);

        // Variable Part
        if (!this.checksum.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.checksum);
            buffer.put(cast(ubyte) 0x02u);
            buffer.put(convertToBigEndianBytes(this.checksum.get()));
        }

        // User Data
        buffer.put(this.userData);
        
        ubyte[] ret = buffer.toBytes;
        if (ret.length > ubyte.max)
            throw new Exception("X.224 Disconnect Confirm TPDU is too big for its own length encoding! Cannot exceed 255 bytes!");
        ret[0] = cast(ubyte) (ret.length - 1);
        return ret;
    }
}

///
public alias X224DTTPDU = X224DataTransportProtocolDataUnit;
///
public alias X224DTTransportProtocolDataUnit = X224DataTransportProtocolDataUnit;
///
public alias X224DataTPDU = X224DataTransportProtocolDataUnit;
/**
    See page 70 of the PDF of ITU X.224.
*/
public
class X224DataTransportProtocolDataUnit(X224ProtocolClass protocolClass, bool extended) : X224TPDU
{
    public immutable size_t fixedPartLength = 5u;

    private
    enum X224ParameterCode : ubyte
    {
        checksum = 0b1100_0011u
    }

    // Fixed Part

    public immutable X224TPDUCode code = X224TPDUCode.data;
    public ubyte requestOfAcknowledgement = 0x00u;
    public immutable ushort destinationReference = 0x0000u;

    static if (extended)
        public int number = 0x00u;
    else
        public byte number = 0x00u;

    public bool endOfTransportServiceDataUnit = true;

    // Variable Part

    public Nullable!(ushort) checksum;

    ///
    public @property @system
    ubyte[] bytes()
    out (value)
    {
        assert(value.length >= 7u);
    }
    do
    {
        if (this.userData.length > 64u)
            throw new Exception("User data cannot exceed 64 bytes in an X.224 Disconnect Confirm TPDU.");

        OutBuffer buffer = new OutBuffer();

        // Fixed Part
        ubyte[] fixedPart = [ 0x00u, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u ];
        fixedPart[1] = cast(ubyte) X224TransportProtocolDataUnitCode.disconnectConfirm;
        // DST-REF is always 0x0000
        fixedPart[4] = cast(ubyte) ((this.sourceReference & 0xFF00u) >> 8);
        fixedPart[5] = cast(ubyte) (this.sourceReference & 0x00FFu);
        buffer.put(fixedPart);

        // Variable Part
        if (!this.checksum.isNull)
        {
            buffer.put(cast(ubyte) X224ParameterCode.checksum);
            buffer.put(cast(ubyte) 0x02u);
            buffer.put(convertToBigEndianBytes(this.checksum.get()));
        }

        // User Data
        buffer.put(this.userData);
        
        ubyte[] ret = buffer.toBytes;
        if (ret.length > ubyte.max)
            throw new Exception("X.224 Disconnect Confirm TPDU is too big for its own length encoding! Cannot exceed 255 bytes!");
        ret[0] = cast(ubyte) (ret.length - 1);
        return ret;
    }
}

void main()
{
    import std.stdio : writefln;
    X224CRTPDU conreq = new X224CRTPDU();
    // conreq.sourceReference = 10027u;
    writefln("%(%02X %)", conreq.bytes);
}

// DT: 02 f0 80