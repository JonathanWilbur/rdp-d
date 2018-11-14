module ip;

///
public alias IPv4Address = InternetProtocolVersion4Address;
/**

*/
public
struct InternetProtocolVersion4Address
{
    public ubyte[4] bytes;
}

///
public alias IPv4Connection = InternetProtocolVersion4Connection;
/**

*/
public
interface InternetProtocolVersion4Connection
{
    /**

    */
    public @property
    IPv4Address localInternetProtocolAddress;

    /**

    */
    public @property
    IPv4Address remoteInternetProtocolAddress;
}