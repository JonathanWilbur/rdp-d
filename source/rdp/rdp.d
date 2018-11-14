module rdp;
// import core.time : Duration;
import std.array : appender, Appender;
import std.datetime.stopwatch : AutoStart, StopWatch;
import std.socket : InternetAddress, TcpSocket;
import tpkt;

immutable ubyte[7] x224ConnectRequestTemplate = [ 0x06u, 0x0Eu, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u ]; // Only first byte (LI) needs to change before being sent.
immutable ubyte[7] x224ConnectConfirmTemplate = [ 0x06u, 0x0Du, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u ]; // Only first byte (LI) matters.
immutable ubyte[3] x224DataTemplate = [ 0x02u, 0xF0u, 0x80u ]; // It does not look like this ever varies.

///
public alias RDPConnection = RemoteDesktopProtocolConnection;
/**

*/
public
class RemoteDesktopProtocolConnection
{
    private TcpSocket _socket;
    public ushort x224ConnectionTimeoutInMilliseconds = 5000u;

    public
    void createX224Connection()
    {
        TPKT connectionRequestTPKT = new TPKT();
        connectionRequestTPKT.content = cast(ubyte[]) x224ConnectRequestTemplate;
        this._socket.send(connectionRequestTPKT.toBytes);

        StopWatch stopWatch = StopWatch(AutoStart.yes);
        while (stopWatch.peek.total!"msecs" < this.x224ConnectionTimeoutInMilliseconds)
        {
            scope(exit) stopWatch.stop();
            // Appender!(ubyte[]) packetBuffer = appender!(ubyte[])();
            ubyte[1024] receiveBuffer;
            if (this._socket.receive(receiveBuffer) >= 7)
            {
                if (receiveBuffer[0 .. 7] == x224ConnectConfirmTemplate)
                {
                    break;
                }
                else
                {
                    // Lol idk
                }
            }
        }
    }

    public
    bool authenticate (in string username, in string password)
    {

    }
    
    /**
        Creates the IP and TCP connections, but nothing else.
    */
    public
    this(string hostname, ushort port = 3389u)
    {
        this._socket = new TcpSocket(InternetAddress(hostname, port));
    }

    public
    ~this()
    {
        this._socket.close();
    }
}