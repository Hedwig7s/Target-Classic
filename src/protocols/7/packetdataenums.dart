enum IdentificationPacketData { id, protocolVersion, name, keyOrMotd, userType }

enum PingPacketData { id }

enum LevelInitializePacketData { id }

enum LevelDataChunkPacketData { id, chunkLength, chunkData, percentComplete }

enum LevelFinalizePacketData { id, sizeX, sizeY, sizeZ }
