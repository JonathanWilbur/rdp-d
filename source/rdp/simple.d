immutable ubyte[7] x224ConnectRequestTemplate = [ 0x00u, 0x0Eu, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u ]; // Only first byte (LI) needs to change before being sent.
immutable ubyte[7] x224ConnectConfirmTemplate = [ 0x00u, 0x0Du, 0x00u, 0x00u, 0x00u, 0x00u, 0x00u ]; // Only first byte (LI) matters.
immutable ubyte[3] x224DataTemplate = [ 0x02u, 0xF0u, 0x80u ]; // It does not look like this ever varies.